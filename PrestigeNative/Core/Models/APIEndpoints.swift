//
//  APIEndpoints.swift
//  API Endpoint Definitions
//
//  This file contains all API endpoint paths and URL construction
//  for the Prestige API integration
//

import Foundation

/// API endpoint paths for reference
enum APIEndpoints {
    static let baseURL = ProcessInfo.processInfo.environment["API_ADDRESS"] ?? ""
    
    // MARK: - Authentication
    static let login = "auth/login"
    static let logout = "auth/logout"
    static let refreshToken = "auth/token"
    
    // MARK: - User Profile
    static func userProfile(userId: String) -> String { "user/\(userId)" }
    static func updateProfile(userId: String) -> String { "user/\(userId)" }
    static let updateNickname = "user/nickname"
    static let setFavorites = "user/favorites"
    
    // MARK: - Prestige Data
    static func userTracks(userId: String) -> String { "profiles/\(userId)/top/tracks" }
    static func userAlbums(userId: String) -> String { "profiles/\(userId)/top/albums" }
    static func userArtists(userId: String) -> String { "profiles/\(userId)/top/artists" }
    static func recentlyPlayed(userId: String) -> String { "profiles/\(userId)/recently-played" }
    
    // MARK: - Favorites
    static func favoriteTracks(userId: String) -> String { "profiles/\(userId)/favorites/tracks" }
    static func favoriteAlbums(userId: String) -> String { "profiles/\(userId)/favorites/albums" }
    static func favoriteArtists(userId: String) -> String { "profiles/\(userId)/favorites/artists" }
    static func addFavorite(userId: String, type: String, itemId: String) -> String { "profiles/\(userId)/favorites/\(type)/\(itemId)" }
    
    // MARK: - Friends
    static func friends(userId: String) -> String { "friend/\(userId)" }
    static let addFriend = "friend/add"
    static func removeFriend(friendId: String) -> String { "friend/\(friendId)" }
    static func searchUsers(query: String) -> String { "friend/search?query=\(query)" }
    
    // MARK: - Spotify Integration
    static let spotifySearch = "spotify/search"
    static let spotifyRecentlyPlayed = "spotify/recently-played"
}

// MARK: - URL Construction Helpers

extension APIEndpoints {
    /// Construct full URL for an endpoint
    /// - Parameter endpoint: The endpoint path
    /// - Returns: Complete URL or nil if invalid
    static func fullURL(for endpoint: String) -> URL? {
        return URL(string: "\(baseURL)/\(endpoint)")
    }
    
    /// Construct URL with query parameters
    /// - Parameters:
    ///   - endpoint: The endpoint path
    ///   - parameters: Query parameters as key-value pairs
    /// - Returns: Complete URL with query parameters or nil if invalid
    static func fullURL(for endpoint: String, parameters: [String: String]) -> URL? {
        guard var urlComponents = URLComponents(string: "\(baseURL)/\(endpoint)") else {
            return nil
        }
        
        urlComponents.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        
        return urlComponents.url
    }
}