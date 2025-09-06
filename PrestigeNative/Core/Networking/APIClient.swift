//
//  APIClient.swift
//  Core Network Layer for Prestige iOS
//
//  This file contains the main HTTP client service that handles all
//  API communication with retry logic, authentication, and error handling.
//  This is equivalent to the useHttp.ts hook from the web application.
//

import Foundation
import Combine

class APIClient: ObservableObject {
    static let shared = APIClient()
    
    // Date formatters for high precision .NET API dates
    private static let highPrecisionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    private static let standardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    private let baseURL: String
    private let maxRetries = 2
    private let session: URLSession
    private var authManager: AuthManager?
    
    @Published var isLoading = false
    @Published var lastError: APIError?
    
    private init() {
        self.baseURL = ProcessInfo.processInfo.environment["API_ADDRESS"] ?? ""
        
        // Configure URLSession with timeout settings
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Private Helper Methods
    
    /// Retry logic for failed requests with exponential backoff
    private func retryRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type,
        retries: Int = 0
    ) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Log response for debugging (truncate large bodies)
            print("🔵 APIClient: Response status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                let maxLogChars = 2000
                if responseString.count > maxLogChars {
                    let prefix = responseString.prefix(maxLogChars)
                    print("🔵 APIClient: Response body (truncated to \(maxLogChars) chars, total=\(responseString.count)): \(prefix) ...")
                } else {
                    print("🔵 APIClient: Response body: \(responseString)")
                }
            }
            
            // Handle successful responses
            if 200...299 ~= httpResponse.statusCode {
                // Debug: Log response data for prestige-related endpoints
                if let dataString = String(data: data, encoding: .utf8),
                   let url = request.url?.absoluteString,
                   (url.contains("tracks") || url.contains("albums") || url.contains("artists")) {
                    print("🔍 API Response for \(url):")
                    print("🔍 Response data: \(dataString.prefix(500))")
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Try high precision format first (from .NET API)
                    if let date = APIClient.highPrecisionDateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    // Fall back to standard ISO8601
                    if let date = ISO8601DateFormatter().date(from: dateString) {
                        return date
                    }
                    
                    // Final fallback to standard format
                    if let date = APIClient.standardDateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                }
                return try decoder.decode(T.self, from: data)
            }
            
            // Handle rate limiting (429) with exponential backoff
            if httpResponse.statusCode == 429 && retries < maxRetries {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                let delay = Double(retryAfter ?? "1") ?? Double(1000 * pow(2, Double(retries))) / 1000.0
                print("⏳ Rate limited. Retrying after \(delay) seconds (attempt \(retries + 1)/\(maxRetries))")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await retryRequest(request, responseType: responseType, retries: retries + 1)
            }
            
            // Handle server errors with retry logic
            if httpResponse.statusCode >= 500 && retries < maxRetries {
                let delay = Double(500 * pow(2, Double(retries))) / 1000.0
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await retryRequest(request, responseType: responseType, retries: retries + 1)
            }
            
            // Handle other HTTP errors
            let errorMessage = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage?.message)
            
        } catch {
            // Retry network errors
            if retries < maxRetries && error is URLError {
                let delay = Double(500 * pow(2, Double(retries))) / 1000.0
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await retryRequest(request, responseType: responseType, retries: retries + 1)
            }
            
            if error is DecodingError {
                throw APIError.decodingError(error)
            } else if error is URLError {
                throw APIError.networkError(error)
            } else {
                throw error
            }
        }
    }
    
    /// Create authenticated request with bearer token
    private func createAuthenticatedRequest(
        url: URL,
        method: HTTPMethod,
        body: Data? = nil
    ) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get authentication token from AuthManager
        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔵 APIClient: Added Auth0 Bearer token to request")
        } else {
            print("⚠️ APIClient: No authentication token available")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    /// Set the AuthManager for dependency injection
    func setAuthManager(_ manager: AuthManager) {
        self.authManager = manager
    }
    
    /// Get authentication token from AuthManager
    private func getAuthToken() async -> String? {
        guard let authManager = authManager else {
            await MainActor.run { lastError = .authenticationError }
            print("⚠️ APIClient: AuthManager not injected")
            return nil
        }
        
        do {
            return try await authManager.getAccessToken()
        } catch {
            await MainActor.run { lastError = .authenticationError }
            return nil
        }
    }
    
    // MARK: - Public API Methods
    
    /// Perform GET request
    /// GET request with caching support
    func get<T: Codable>(
        _ endpoint: String,
        responseType: T.Type,
        cacheCategory: CacheCategory? = nil,
        forceRefresh: Bool = false
    ) async throws -> T {
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            print("❌ APIClient: Invalid URL for endpoint: \(endpoint)")
            throw APIError.invalidURL
        }
        
        // Check cache first if category provided and not forcing refresh
        if let cacheCategory = cacheCategory, !forceRefresh {
            if let cached = ResponseCacheService.shared.getCachedResponse(
                for: endpoint,
                responseType: responseType,
                category: cacheCategory
            ) {
                return cached
            }
        }
        
        print("🔵 APIClient: Making GET request to: \(url.absoluteString)")
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let request = try await createAuthenticatedRequest(url: url, method: .GET)
        
        do {
            let result = try await retryRequest(request, responseType: responseType)
            await MainActor.run { lastError = nil }
            
            // Cache the result if category provided
            if let cacheCategory = cacheCategory {
                ResponseCacheService.shared.cacheResponse(
                    result,
                    for: endpoint,
                    category: cacheCategory
                )
            }
            
            return result
        } catch let error as APIError {
            await MainActor.run { lastError = error }
            throw error
        }
    }
    
    /// Perform POST request
    func post<T: Decodable, U: Encodable>(
        _ endpoint: String,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            throw APIError.invalidURL
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(body)
        
        let request = try await createAuthenticatedRequest(url: url, method: .POST, body: bodyData)
        
        do {
            let result = try await retryRequest(request, responseType: responseType)
            await MainActor.run { lastError = nil }
            return result
        } catch let error as APIError {
            await MainActor.run { lastError = error }
            throw error
        }
    }
    
    /// Perform POST request without expecting a response
    func postWithoutResponse<U: Encodable>(
        _ endpoint: String,
        body: U
    ) async throws {
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            throw APIError.invalidURL
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(body)
        
        let request = try await createAuthenticatedRequest(url: url, method: .POST, body: bodyData)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Log response for debugging
            print("🔵 APIClient: Response status: \(httpResponse.statusCode)")
            
            // Handle successful responses (200-299)
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage?.message)
            }
            
            await MainActor.run { lastError = nil }
        } catch let error as APIError {
            await MainActor.run { lastError = error }
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            await MainActor.run { lastError = apiError }
            throw apiError
        }
    }
    
    /// Perform PUT request
    func put<T: Decodable, U: Encodable>(
        _ endpoint: String,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            throw APIError.invalidURL
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(body)
        
        let request = try await createAuthenticatedRequest(url: url, method: .PUT, body: bodyData)
        
        do {
            let result = try await retryRequest(request, responseType: responseType)
            await MainActor.run { lastError = nil }
            return result
        } catch let error as APIError {
            await MainActor.run { lastError = error }
            throw error
        }
    }
    
    /// Perform PATCH request
    func patch<T: Decodable, U: Encodable>(
        _ endpoint: String,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            throw APIError.invalidURL
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(body)
        
        let request = try await createAuthenticatedRequest(url: url, method: .PATCH, body: bodyData)
        
        do {
            let result = try await retryRequest(request, responseType: responseType)
            await MainActor.run { lastError = nil }
            return result
        } catch let error as APIError {
            await MainActor.run { lastError = error }
            throw error
        }
    }
    
    /// Perform DELETE request
    func delete<T: Decodable>(
        _ endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            throw APIError.invalidURL
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let request = try await createAuthenticatedRequest(url: url, method: .DELETE)
        
        do {
            let result = try await retryRequest(request, responseType: responseType)
            await MainActor.run { lastError = nil }
            return result
        } catch let error as APIError {
            await MainActor.run { lastError = error }
            throw error
        }
    }
    
    /// Perform DELETE request without response body
    func delete(_ endpoint: String) async throws {
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            throw APIError.invalidURL
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let request = try await createAuthenticatedRequest(url: url, method: .DELETE)
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if !(200...299 ~= httpResponse.statusCode) {
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
            }
            
            await MainActor.run { lastError = nil }
        } catch let error as APIError {
            await MainActor.run { lastError = error }
            throw error
        }
    }
}

// MARK: - HTTP Method Enum

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Convenience Extensions

extension APIClient {
    /// Get user tracks with prestige data
    func getUserTracks(userId: String) async throws -> [UserTrackResponse] {
        return try await get(APIEndpoints.userTracks(userId: userId), responseType: [UserTrackResponse].self)
    }
    
    /// Get user albums with prestige data
    func getUserAlbums(userId: String) async throws -> [UserAlbumResponse] {
        return try await get(APIEndpoints.userAlbums(userId: userId), responseType: [UserAlbumResponse].self)
    }
    
    /// Get user artists with prestige data
    func getUserArtists(userId: String) async throws -> [UserArtistResponse] {
        return try await get(APIEndpoints.userArtists(userId: userId), responseType: [UserArtistResponse].self)
    }
    
    /// Get user profile with shorter timeout for initial check
    func getUserProfile(userId: String, quickCheck: Bool = false) async throws -> UserResponse {
        if quickCheck {
            // For initial setup check, use shorter timeout
            var request = URLRequest(url: APIEndpoints.fullURL(for: APIEndpoints.userProfile(userId: userId))!)
            request.timeoutInterval = 10.0 // 10 second timeout for quick check
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = await getAuthToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if 200...299 ~= httpResponse.statusCode {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Try high precision format first (from .NET API)
                    if let date = APIClient.highPrecisionDateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    // Fall back to standard ISO8601
                    if let date = ISO8601DateFormatter().date(from: dateString) {
                        return date
                    }
                    
                    // Final fallback to standard format
                    if let date = APIClient.standardDateFormatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                }
                return try decoder.decode(UserResponse.self, from: data)
            } else {
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
            }
        } else {
            return try await get(APIEndpoints.userProfile(userId: userId), responseType: UserResponse.self)
        }
    }
    
    // MARK: - Enhanced Friends API with Caching
    
    /// Get user friends with Redis caching
    func getFriends(userId: String, forceRefresh: Bool = false) async throws -> [FriendResponse] {
        return try await getCached(
            APIEndpoints.friends(userId: userId),
            responseType: [FriendResponse].self,
            category: .friends,
            forceRefresh: forceRefresh
        )
    }
    
    /// Get detailed friend profile
    func getFriendProfile(userId: String, friendId: String, forceRefresh: Bool = false) async throws -> FriendResponse {
        return try await getCached(
            APIEndpoints.friendProfile(userId: userId, friendId: friendId),
            responseType: FriendResponse.self,
            category: .friendProfiles,
            forceRefresh: forceRefresh
        )
    }
    
    /// Get friend's recently played tracks
    func getFriendRecentlyPlayed(userId: String, friendId: String) async throws -> [RecentlyPlayedResponse] {
        return try await get(
            APIEndpoints.friendRecentlyPlayed(userId: userId, friendId: friendId),
            responseType: [RecentlyPlayedResponse].self
        )
    }
    
    /// Search users
    func searchUsers(query: String) async throws -> [UserResponse] {
        // Search results are dynamic, use short TTL cache
        return try await getCached(
            APIEndpoints.searchUsers(query: query),
            responseType: [UserResponse].self,
            category: .searchResults
        )
    }
    
    /// Update user nickname
    func updateNickname(_ nickname: String) async throws -> UserResponse {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        let request = NicknameRequest(nickname: nickname)
        return try await patch(APIEndpoints.updateNickname(userId: userId), body: request, responseType: UserResponse.self)
    }
    
    /// Update user profile (display name and bio)
    func updateUserProfile(userId: String, displayName: String, bio: String?) async throws -> UserResponse {
        let request = UpdateProfileRequest(nickname: displayName.isEmpty ? nil : displayName, bio: bio)
        return try await patch(APIEndpoints.updateUserProfile(userId: userId), body: request, responseType: UserResponse.self)
    }
    
    /// Add friend with cache invalidation
    func addFriend(friendId: String) async throws -> FriendResponse {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        
        // Use new web app endpoint
        let friendResponse = try await post(
            APIEndpoints.addFriendship(userId: userId, friendId: friendId),
            body: EmptyBody(),
            responseType: FriendResponse.self
        )
        
        // Invalidate friends cache
        await ResponseCacheService.shared.invalidateWithRedis(
            category: .friends,
            keyPattern: userId
        )
        
        return friendResponse
    }
    
    /// Remove friend with cache invalidation
    func removeFriend(friendId: String) async throws {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        
        try await delete(APIEndpoints.removeFriendship(userId: userId, friendId: friendId))
        
        // Invalidate friends cache
        await ResponseCacheService.shared.invalidateWithRedis(
            category: .friends,
            keyPattern: userId
        )
        await ResponseCacheService.shared.invalidateWithRedis(
            category: .friendProfiles,
            keyPattern: friendId
        )
    }
    
    // MARK: - Social Discovery
    
    /// Get friends who listened to a specific track
    func getFriendsWithTrack(userId: String, trackId: String) async throws -> [FriendResponse] {
        return try await get(
            APIEndpoints.friendsWithTrack(userId: userId, trackId: trackId),
            responseType: [FriendResponse].self
        )
    }
    
    /// Get friends who listened to a specific album
    func getFriendsWithAlbum(userId: String, albumId: String) async throws -> [FriendResponse] {
        return try await get(
            APIEndpoints.friendsWithAlbum(userId: userId, albumId: albumId),
            responseType: [FriendResponse].self
        )
    }
    
    /// Get friends who listened to a specific artist
    func getFriendsWithArtist(userId: String, artistId: String) async throws -> [FriendResponse] {
        return try await get(
            APIEndpoints.friendsWithArtist(userId: userId, artistId: artistId),
            responseType: [FriendResponse].self
        )
    }
    
    /// Get friend's listening time for a track
    func getFriendTrackTime(friendId: String, trackId: String) async throws -> FriendListeningData {
        return try await get(
            APIEndpoints.friendTrackTime(friendId: friendId, trackId: trackId),
            responseType: FriendListeningData.self
        )
    }
    
    /// Get friend's listening time for an album
    func getFriendAlbumTime(friendId: String, albumId: String) async throws -> FriendListeningData {
        return try await get(
            APIEndpoints.friendAlbumTime(friendId: friendId, albumId: albumId),
            responseType: FriendListeningData.self
        )
    }
    
    /// Get friend's listening time for an artist
    func getFriendArtistTime(friendId: String, artistId: String) async throws -> FriendListeningData {
        return try await get(
            APIEndpoints.friendArtistTime(friendId: friendId, artistId: artistId),
            responseType: FriendListeningData.self
        )
    }
    
    // MARK: - Friend Request Management
    
    /// Send friend request
    func sendFriendRequest(friendId: String) async throws -> FriendResponse {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        
        let endpoint = "api/friendships/\(userId)/friend-requests/\(friendId)"
        print("🔵 APIClient: Sending friend request - endpoint: \(endpoint)")
        print("🔵 APIClient: Full URL will be: \(APIEndpoints.baseURL)/\(endpoint)")
        
        // Try to get the response as FriendResponse, but handle cases where backend might return different format
        do {
            return try await post(endpoint, body: EmptyBody(), responseType: FriendResponse.self)
        } catch {
            print("⚠️ APIClient: Friend request response parsing failed, trying alternative approach: \(error)")
            
            // If parsing fails, try making a basic POST and then fetch the friend details
            try await postWithoutResponse(endpoint, body: EmptyBody())
            
            // Create a basic FriendResponse for the friend request that was sent
            // We'll need to fetch the actual friend data separately
            return FriendResponse(
                id: friendId,
                name: "Friend", // Placeholder - will be updated when friends list is refreshed
                nickname: nil,
                profilePicUrl: nil,
                friendshipDate: Date(),
                mutualFriends: nil,
                status: 0, // 0 = pending
                favoriteTracks: nil,
                favoriteAlbums: nil,
                favoriteArtists: nil,
                topTracks: nil,
                topAlbums: nil,
                topArtists: nil,
                ratedTracks: nil,
                ratedAlbums: nil,
                ratedArtists: nil,
                recentlyPlayed: nil
            )
        }
    }
    
    /// Accept friend request
    func acceptFriendRequest(friendId: String) async throws -> FriendResponse {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        
        let endpoint = "api/friendships/\(userId)/friend-requests/\(friendId)/accept"
        return try await post(endpoint, body: EmptyBody(), responseType: FriendResponse.self)
    }
    
    /// Decline friend request
    func declineFriendRequest(friendId: String) async throws {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        
        let endpoint = "api/friendships/\(userId)/friend-requests/\(friendId)/decline"
        try await postWithoutResponse(endpoint, body: EmptyBody())
    }
    
    /// Get incoming friend requests
    func getIncomingFriendRequests() async throws -> [FriendRequestResponse] {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        
        let endpoint = "api/friendships/\(userId)/friend-requests"
        return try await get(endpoint, responseType: [FriendRequestResponse].self)
    }
    
    /// Get outgoing friend requests
    func getOutgoingFriendRequests() async throws -> [FriendRequestResponse] {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        
        let endpoint = "api/friendships/\(userId)/outgoing-friend-requests"
        return try await get(endpoint, responseType: [FriendRequestResponse].self)
    }
    
    // MARK: - Helper Models
    
    private struct EmptyBody: Codable {}
    
    /// Search Spotify
    func searchSpotify(query: String, type: String) async throws -> SpotifySearchResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let pluralType = type == "track" ? "tracks" : type == "album" ? "albums" : "artists"
        let endpoint = "spotify/\(pluralType)/search?Query=\(encodedQuery)"
        
        // Based on web app, endpoint returns array directly for each type
        switch type {
        case "track":
            let tracks = try await get(endpoint, responseType: [SpotifyTrackSearch].self)
            return SpotifySearchResponse(tracks: SpotifyTracksSearch(items: tracks), albums: nil, artists: nil)
        case "album":
            let albums = try await get(endpoint, responseType: [SpotifyAlbumSearch].self)
            return SpotifySearchResponse(tracks: nil, albums: SpotifyAlbumsSearch(items: albums), artists: nil)
        case "artist":
            let artists = try await get(endpoint, responseType: [SpotifyArtistSearch].self)
            return SpotifySearchResponse(tracks: nil, albums: nil, artists: SpotifyArtistsSearch(items: artists))
        default:
            return SpotifySearchResponse(tracks: nil, albums: nil, artists: nil)
        }
    }
    
    /// Toggle favorite item (add/remove)
    func toggleFavorite(userId: String, type: String, itemId: String) async throws -> [UserTrackResponse] {
        let pluralType = type + "s" // tracks, albums, artists
        let endpoint = "profiles/\(userId)/favorites/\(pluralType)/\(itemId)"
        struct EmptyBody: Codable {}
        
        print("🔵 APIClient: Toggling favorite - type: \(type), itemId: \(itemId)")
        
        // Make the API call without expecting specific response format
        // The API returns different formats for different types
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            throw APIError.invalidURL
        }
        
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(EmptyBody())
        let request = try await createAuthenticatedRequest(url: url, method: .PATCH, body: bodyData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("🔵 Raw response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 Raw response body: \(responseString)")
        }
        
        if 200...299 ~= httpResponse.statusCode {
            print("✅ Successfully toggled favorite (raw success)")
            // Return empty array since we can't decode the mixed response types
            // The calling code should refresh the favorites list separately
            return []
        } else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: "Failed to toggle favorite")
        }
    }
    
    /// Get favorites for a type
    func getFavorites(userId: String, type: String) async throws -> [UserTrackResponse] {
        let pluralType = type + "s" // tracks, albums, artists
        let endpoint = "profiles/\(userId)/favorites/\(pluralType)"
        
        // For tracks, use UserTrackResponse
        if type == "track" {
            return try await get(endpoint, responseType: [UserTrackResponse].self)
        } else {
            // For albums and artists, return empty array for now
            // The backend needs to be updated to support proper album/artist favorites
            return []
        }
    }
    
    /// Get album favorites
    func getAlbumFavorites(userId: String) async throws -> [UserAlbumResponse] {
        let endpoint = "profiles/\(userId)/favorites/albums"
        return try await get(endpoint, responseType: [UserAlbumResponse].self)
    }
    
    /// Get artist favorites  
    func getArtistFavorites(userId: String) async throws -> [UserArtistResponse] {
        let endpoint = "profiles/\(userId)/favorites/artists"
        return try await get(endpoint, responseType: [UserArtistResponse].self)
    }
    
    /// Update user setup status
    func updateUserSetupStatus(_ isSetup: Bool) async throws -> UserResponse {
        guard let userId = authManager?.user?.id else {
            throw APIError.authenticationError
        }
        let endpoint = "users/\(userId)/is-setup?isSetup=\(isSetup)"
        return try await patch(endpoint, body: ["isSetup": isSetup], responseType: UserResponse.self)
    }
    
    /// Get user ratings for a specific item type
    func getUserRatings(itemType: String) async throws -> [RatedItem] {
        let endpoint = APIEndpoints.userRatings(itemType: itemType)
        let serverRatings = try await get(endpoint, responseType: [ServerRatingResponse].self)
        
        // Convert server ratings to RatedItem objects
        var ratedItems: [RatedItem] = []
        
        for serverRating in serverRatings {
            // Create rating object
            let rating = Rating(
                itemId: serverRating.itemId,
                itemType: RatingItemType(rawValue: serverRating.itemType) ?? .track,
                albumId: serverRating.albumId,
                categoryId: serverRating.categoryId ?? 0,
                category: nil, // We'll populate this separately if needed
                position: serverRating.position ?? 0,
                personalScore: serverRating.personalScore ?? 0.0,
                rankWithinAlbum: serverRating.rankWithinAlbum,
                isNewRating: serverRating.isNewRating
            )
            
            // Get item details
            do {
                let itemData = try await getItemDetails(itemType: serverRating.itemType, itemId: serverRating.itemId)
                let ratedItem = RatedItem(
                    id: serverRating.itemId,
                    rating: rating,
                    itemData: itemData
                )
                ratedItems.append(ratedItem)
            } catch {
                print("Failed to get item details for rating: \(error)")
                // Continue with next item instead of failing completely
            }
        }
        
        return ratedItems.sorted { $0.rating.personalScore > $1.rating.personalScore }
    }
    
    /// Get item details for ratings
    private func getItemDetails(itemType: String, itemId: String) async throws -> RatingItemData {
        let endpoint = APIEndpoints.itemDetails(itemType: itemType, itemId: itemId)
        return try await get(endpoint, responseType: RatingItemData.self)
    }
    
    // MARK: - Pin Toggle Methods
    
    /// Toggle pin status for track
    func togglePinTrack(userId: String, trackId: String) async throws {
        let endpoint = "prestige/\(userId)/tracks/\(trackId)/pin"
        try await postWithoutResponse(endpoint, body: EmptyBody())
    }
    
    /// Toggle pin status for album
    func togglePinAlbum(userId: String, albumId: String) async throws {
        let endpoint = "prestige/\(userId)/albums/\(albumId)/pin"
        try await postWithoutResponse(endpoint, body: EmptyBody())
    }
    
    /// Toggle pin status for artist
    func togglePinArtist(userId: String, artistId: String) async throws {
        let endpoint = "prestige/\(userId)/artists/\(artistId)/pin"
        try await postWithoutResponse(endpoint, body: EmptyBody())
    }
    
    /// Get album tracks with rankings
    func getAlbumTracksWithRankings(userId: String, albumId: String) async throws -> AlbumTracksWithRankingsResponse {
        let endpoint = "prestige/\(userId)/albums/\(albumId)/tracks"
        return try await get(endpoint, responseType: AlbumTracksWithRankingsResponse.self)
    }
    
    /// Get artist albums with user activity and ratings
    func getArtistAlbumsWithUserActivity(userId: String, artistId: String) async throws -> ArtistAlbumsWithRankingsResponse {
        let endpoint = "prestige/\(userId)/artists/\(artistId)/albums"
        print("🔵 APIClient: Making request to endpoint: \(endpoint)")
        print("🔵 APIClient: Full URL: \(baseURL)/\(endpoint)")
        
        do {
            let result = try await get(endpoint, responseType: ArtistAlbumsWithRankingsResponse.self)
            print("✅ APIClient: Successfully parsed ArtistAlbumsWithRankingsResponse")
            print("🔵 APIClient: - artistId: \(result.artistId)")
            print("🔵 APIClient: - totalAlbums: \(result.totalAlbums)")
            print("🔵 APIClient: - albums count: \(result.albums.count)")
            print("🔵 APIClient: - ratedAlbums: \(result.ratedAlbums)")
            
            if !result.albums.isEmpty {
                print("🔵 APIClient: First album example:")
                let firstAlbum = result.albums[0]
                print("🔵 APIClient:   - albumId: \(firstAlbum.albumId)")
                print("🔵 APIClient:   - albumName: \(firstAlbum.albumName)")
                print("🔵 APIClient:   - artistName: \(firstAlbum.artistName)")
                print("🔵 APIClient:   - albumRatingScore: \(firstAlbum.albumRatingScore ?? 0.0)")
                print("🔵 APIClient:   - albumRatingPosition: \(firstAlbum.albumRatingPosition ?? 0)")
            }
            
            return result
        } catch {
            print("❌ APIClient: Error in getArtistAlbumsWithUserActivity: \(error)")
            if let data = error as? DecodingError {
                print("❌ APIClient: Decoding error details: \(data)")
            }
            throw error
        }
    }
    
    /// Get all pinned items for a user
    func getPinnedItems(userId: String) async throws -> PinnedItemsResponse {
        let endpoint = "prestige/\(userId)/pinned"
        return try await get(endpoint, responseType: PinnedItemsResponse.self)
    }
    
    // MARK: - Friend Context Methods
    
    func getFriendTrackDetails(userId: String, friendId: String, trackId: String) async throws -> FriendItemDetailsResponse {
        let endpoint = APIEndpoints.friendTrackDetails(userId: userId, friendId: friendId, trackId: trackId)
        return try await get(endpoint, responseType: FriendItemDetailsResponse.self)
    }
    
    func getFriendAlbumDetails(userId: String, friendId: String, albumId: String) async throws -> FriendItemDetailsResponse {
        let endpoint = APIEndpoints.friendAlbumDetails(userId: userId, friendId: friendId, albumId: albumId)
        return try await get(endpoint, responseType: FriendItemDetailsResponse.self)
    }
    
    func getFriendArtistDetails(userId: String, friendId: String, artistId: String) async throws -> FriendItemDetailsResponse {
        let endpoint = APIEndpoints.friendArtistDetails(userId: userId, friendId: friendId, artistId: artistId)
        return try await get(endpoint, responseType: FriendItemDetailsResponse.self)
    }
    
    func getFriendAlbumTrackRankings(userId: String, friendId: String, albumId: String) async throws -> [FriendTrackRankingResponse] {
        let endpoint = APIEndpoints.friendAlbumTrackRankings(userId: userId, friendId: friendId, albumId: albumId)
        return try await get(endpoint, responseType: [FriendTrackRankingResponse].self)
    }
    
    func getFriendArtistAlbumRankings(userId: String, friendId: String, artistId: String) async throws -> [FriendAlbumRatingResponse] {
        let endpoint = APIEndpoints.friendArtistAlbumRankings(userId: userId, friendId: friendId, artistId: artistId)
        return try await get(endpoint, responseType: [FriendAlbumRatingResponse].self)
    }
    
    func getEnhancedTrackComparison(userId: String, trackId: String, friendId: String) async throws -> EnhancedItemComparisonResponse {
        let endpoint = APIEndpoints.enhancedCompareTrack(userId: userId, trackId: trackId, friendId: friendId)
        return try await get(endpoint, responseType: EnhancedItemComparisonResponse.self)
    }
    
    func getEnhancedAlbumComparison(userId: String, albumId: String, friendId: String) async throws -> EnhancedItemComparisonResponse {
        let endpoint = APIEndpoints.enhancedCompareAlbum(userId: userId, albumId: albumId, friendId: friendId)
        return try await get(endpoint, responseType: EnhancedItemComparisonResponse.self)
    }
    
    func getEnhancedArtistComparison(userId: String, artistId: String, friendId: String) async throws -> EnhancedItemComparisonResponse {
        let endpoint = APIEndpoints.enhancedCompareArtist(userId: userId, artistId: artistId, friendId: friendId)
        return try await get(endpoint, responseType: EnhancedItemComparisonResponse.self)
    }
}