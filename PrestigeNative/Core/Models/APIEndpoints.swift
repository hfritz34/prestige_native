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
    static let baseURL = ProcessInfo.processInfo.environment["API_ADDRESS"] ?? "https://prestigeapi-gbdzagg5e4a3aahc.eastus-01.azurewebsites.net"
    
    // MARK: - Authentication
    static let login = "auth/login"
    static let logout = "auth/logout"
    static let refreshToken = "auth/token"
    
    // MARK: - User Profile
    static func userProfile(userId: String) -> String { "users/\(userId)" }
    static func updateProfile(userId: String) -> String { "users/\(userId)" }
    static func updateNickname(userId: String) -> String { "users/\(userId)/nickname" }
    static let setFavorites = "users/favorites"
    
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
    
    // MARK: - Friends (Enhanced endpoints matching web app)
    static func friends(userId: String) -> String {
        return "friendships/\(userId)/friends"
    }
    
    static func addFriendship(userId: String, friendId: String) -> String {
        return "friendships/\(userId)/friends/\(friendId)"
    }
    
    static func removeFriendship(userId: String, friendId: String) -> String {
        return "friendships/\(userId)/friends/\(friendId)"
    }
    
    static func friendProfile(userId: String, friendId: String) -> String {
        return "friendships/\(userId)/friends/\(friendId)"
    }
    
    // Social discovery endpoints
    static func friendsWithTrack(userId: String, trackId: String) -> String {
        return "friendships/\(userId)/friends/listened-to-track/\(trackId)"
    }
    
    static func friendsWithAlbum(userId: String, albumId: String) -> String {
        return "friendships/\(userId)/friends/listened-to-album/\(albumId)"
    }
    
    static func friendsWithArtist(userId: String, artistId: String) -> String {
        return "friendships/\(userId)/friends/listened-to-artist/\(artistId)"
    }
    
    // Friend listening data
    static func friendTrackTime(friendId: String, trackId: String) -> String {
        return "friendships/friend/\(friendId)/track/\(trackId)"
    }
    
    static func friendAlbumTime(friendId: String, albumId: String) -> String {
        return "friendships/friend/\(friendId)/album/\(albumId)"
    }
    
    static func friendArtistTime(friendId: String, artistId: String) -> String {
        return "friendships/friend/\(friendId)/artist/\(artistId)"
    }
    
    // Legacy endpoints (keeping for backward compatibility)
    static let addFriend = "friend/add"
    static func removeFriend(friendId: String) -> String { "friend/\(friendId)" }
    static func searchUsers(query: String) -> String { "users/search?query=\(query)" }
    
    // MARK: - Spotify Integration
    static let spotifySearch = "spotify/search"
    static let spotifyRecentlyPlayed = "spotify/recently-played"
    
    // MARK: - Rating System
    static let ratingCategories = "api/rating/categories"
    static func rateItem(itemType: String, itemId: String) -> String { "api/rating/rate/\(itemType)/\(itemId)" }
    static let saveRating = "api/rating/save"
    static let submitComparison = "api/rating/compare"
    static func userRatings(itemType: String) -> String { "api/rating/user/\(itemType)" }
    static func deleteRating(itemType: String, itemId: String) -> String { "api/rating/user/\(itemType)/\(itemId)" }
    static let ratingSuggestions = "api/rating/suggestions"

    // MARK: - Library
    static let batchItemDetails = "api/library/items/batch"
    static func itemDetails(itemType: String, itemId: String) -> String { "api/library/item/\(itemType)/\(itemId)" }

    // MARK: - Search
    static func searchUserLibrary(query: String, type: String, page: Int = 1, pageSize: Int = 20) -> String {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return "api/search/user-library?query=\(encodedQuery)&type=\(type)&page=\(page)&pageSize=\(pageSize)"
    }
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