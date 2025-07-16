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
struct UserResponse: Codable {
    let id: String
    let nickname: String
    let email: String
    let profilePictureUrl: String?
    let isSetup: Bool
    let createdAt: Date
    let spotifyConnected: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, nickname, email, profilePictureUrl, isSetup, createdAt, spotifyConnected
    }
}

/// Request to update user nickname
struct NicknameRequest: Codable {
    let nickname: String
    
    enum CodingKeys: String, CodingKey {
        case nickname
    }
}

// MARK: - Friends System

/// Friend relationship response
struct FriendResponse: Codable {
    let friendId: String
    let friendNickname: String
    let friendProfilePictureUrl: String?
    let friendshipDate: Date
    let mutualFriends: Int?
    
    enum CodingKeys: String, CodingKey {
        case friendId, friendNickname, friendProfilePictureUrl, friendshipDate, mutualFriends
    }
}

/// Request to add a friend
struct AddFriendRequest: Codable {
    let friendId: String
    
    enum CodingKeys: String, CodingKey {
        case friendId
    }
}

// MARK: - Favorites System

/// Favorites response (Union type in TypeScript, protocol in Swift)
protocol FavoritesResponse: Codable {}

struct TrackFavoritesResponse: FavoritesResponse {
    let tracks: [UserTrackResponse]
    let albums: [UserAlbumResponse]? = nil
    let artists: [UserArtistResponse]? = nil
    
    enum CodingKeys: String, CodingKey {
        case tracks
    }
}

struct AlbumFavoritesResponse: FavoritesResponse {
    let tracks: [UserTrackResponse]? = nil
    let albums: [UserAlbumResponse]
    let artists: [UserArtistResponse]? = nil
    
    enum CodingKeys: String, CodingKey {
        case albums
    }
}

struct ArtistFavoritesResponse: FavoritesResponse {
    let tracks: [UserTrackResponse]? = nil
    let albums: [UserAlbumResponse]? = nil
    let artists: [UserArtistResponse]
    
    enum CodingKeys: String, CodingKey {
        case artists
    }
}