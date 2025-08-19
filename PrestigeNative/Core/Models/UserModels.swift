//
//  UserModels.swift
//  User Profile and Social Features Models
//
//  This file contains models related to user profiles, friends,
//  and social features for the Prestige iOS app
//

import Foundation

// MARK: - User Profile

/// User profile information
struct UserResponse: Codable, Identifiable {
    let id: String
    let name: String
    let nickname: String
    let email: String
    let profilePictureUrl: String?
    let isSetup: Bool
    let createdAt: Date?
    let spotifyConnected: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, isSetup, createdAt, spotifyConnected
        case nickname = "nickName"
        case profilePictureUrl = "profilePicURL"
    }
}

/// Request to update user nickname
struct NicknameRequest: Codable {
    let nickname: String
    
    enum CodingKeys: String, CodingKey {
        case nickname = "nickName"
    }
}

// MARK: - Friends System

/// Enhanced friend response matching web app functionality
struct FriendResponse: Codable, Identifiable {
    let id: String
    let friendId: String
    let name: String
    let nickname: String?
    let profilePicUrl: String?
    let friendshipDate: Date?
    let mutualFriends: Int?
    
    // Rich profile data from web app
    let favoriteTracks: [UserTrackResponse]?
    let favoriteAlbums: [UserAlbumResponse]?
    let favoriteArtists: [UserArtistResponse]?
    let topTracks: [UserTrackResponse]?
    let topAlbums: [UserAlbumResponse]?
    let topArtists: [UserArtistResponse]?
    
    enum CodingKeys: String, CodingKey {
        case id, friendId, name, nickname, profilePicUrl, friendshipDate, mutualFriends
        case favoriteTracks, favoriteAlbums, favoriteArtists
        case topTracks, topAlbums, topArtists
    }
}

/// Simplified friend response for lists (without detailed profile data)
struct FriendSummaryResponse: Codable, Identifiable {
    let id: String
    let friendId: String
    let name: String
    let nickname: String?
    let profilePicUrl: String?
    let friendshipDate: Date?
    let mutualFriends: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, friendId, name, nickname, profilePicUrl, friendshipDate, mutualFriends
    }
}

/// Request to add a friend
struct AddFriendRequest: Codable {
    let friendId: String
    
    enum CodingKeys: String, CodingKey {
        case friendId
    }
}

// MARK: - Social Discovery

/// Response for friends who have listened to specific items
struct FriendsWithItemResponse: Codable {
    let friends: [FriendResponse]
    let itemType: String
    let itemId: String
    let totalCount: Int
}

/// Friend listening data for specific items
struct FriendListeningData: Codable {
    let friendId: String
    let totalTime: Int // in seconds
    let playCount: Int?
    let lastPlayed: Date?
    let rating: Double?
    
    enum CodingKeys: String, CodingKey {
        case friendId, totalTime, playCount, lastPlayed, rating
    }
}

/// Currently playing data for friends
struct FriendCurrentlyPlaying: Codable, Identifiable {
    let id: String
    let friendId: String
    let friendName: String
    let friendProfilePic: String?
    let track: TrackResponse?
    let isPlaying: Bool
    let progressMs: Int?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, friendId, friendName, friendProfilePic, track, isPlaying, progressMs, timestamp
    }
}

// MARK: - Favorites System

/// Favorites response - simplified based on web app implementation
protocol FavoritesResponse: Codable {}

struct TrackFavoritesResponse: FavoritesResponse {
    let tracks: [UserTrackResponse]
}

struct AlbumFavoritesResponse: FavoritesResponse {
    let albums: [UserAlbumResponse]
}

struct ArtistFavoritesResponse: FavoritesResponse {
    let artists: [UserArtistResponse]
}