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
    
    private let baseURL: String
    private let maxRetries = 2
    private let session: URLSession
    
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
            
            // Log response for debugging
            print("🔵 APIClient: Response status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔵 APIClient: Response body: \(responseString)")
            }
            
            // Handle successful responses
            if 200...299 ~= httpResponse.statusCode {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
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
    
    /// Get authentication token from AuthManager
    private func getAuthToken() async -> String? {
        do {
            // This will be injected properly when we set up dependency injection
            let authManager = AuthManager()
            return try await authManager.getAccessToken()
        } catch {
            await MainActor.run { lastError = .authenticationError }
            return nil
        }
    }
    
    // MARK: - Public API Methods
    
    /// Perform GET request
    func get<T: Decodable>(
        _ endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        guard let url = APIEndpoints.fullURL(for: endpoint) else {
            print("❌ APIClient: Invalid URL for endpoint: \(endpoint)")
            throw APIError.invalidURL
        }
        
        print("🔵 APIClient: Making GET request to: \(url.absoluteString)")
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        let request = try await createAuthenticatedRequest(url: url, method: .GET)
        
        do {
            let result = try await retryRequest(request, responseType: responseType)
            await MainActor.run { lastError = nil }
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
    
    /// Get user profile
    func getUserProfile(userId: String) async throws -> UserResponse {
        return try await get(APIEndpoints.userProfile(userId: userId), responseType: UserResponse.self)
    }
    
    /// Get user friends
    func getFriends(userId: String) async throws -> [FriendResponse] {
        return try await get(APIEndpoints.friends(userId: userId), responseType: [FriendResponse].self)
    }
    
    /// Search users
    func searchUsers(query: String) async throws -> [UserResponse] {
        return try await get(APIEndpoints.searchUsers(query: query), responseType: [UserResponse].self)
    }
    
    /// Update user nickname
    func updateNickname(_ nickname: String) async throws -> UserResponse {
        let request = NicknameRequest(nickname: nickname)
        return try await post(APIEndpoints.updateNickname, body: request, responseType: UserResponse.self)
    }
    
    /// Add friend
    func addFriend(friendId: String) async throws -> FriendResponse {
        let request = AddFriendRequest(friendId: friendId)
        return try await post(APIEndpoints.addFriend, body: request, responseType: FriendResponse.self)
    }
    
    /// Remove friend
    func removeFriend(friendId: String) async throws {
        try await delete(APIEndpoints.removeFriend(friendId: friendId))
    }
}