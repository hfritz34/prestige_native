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
    let name: String
    let nickname: String?
    let profilePicUrl: String?
    let friendshipDate: Date?
    let mutualFriends: Int?
    let status: Int?
    
    // Rich profile data from web app
    let favoriteTracks: [UserTrackResponse]?
    let favoriteAlbums: [UserAlbumResponse]?
    let favoriteArtists: [UserArtistResponse]?
    let topTracks: [UserTrackResponse]?
    let topAlbums: [UserAlbumResponse]?
    let topArtists: [UserArtistResponse]?
    
    // Computed property to maintain compatibility with existing code
    var friendId: String {
        return id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, nickname, profilePicUrl, friendshipDate, mutualFriends, status
        case favoriteTracks, favoriteAlbums, favoriteArtists
        case topTracks, topAlbums, topArtists
    }
}

/// Simplified friend response for lists (without detailed profile data)
struct FriendSummaryResponse: Codable, Identifiable {
    let id: String
    let name: String
    let nickname: String?
    let profilePicUrl: String?
    let friendshipDate: Date?
    let mutualFriends: Int?
    let status: Int?
    
    // Computed property to maintain compatibility with existing code
    var friendId: String {
        return id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, nickname, profilePicUrl, friendshipDate, mutualFriends, status
    }
}

/// Request to add a friend
struct AddFriendRequest: Codable {
    let friendId: String
    
    enum CodingKeys: String, CodingKey {
        case friendId
    }
}

/// Friend request response for incoming/outgoing requests
struct FriendRequestResponse: Codable, Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let fromUserName: String
    let fromUserNickname: String?
    let fromUserProfilePicUrl: String?
    let toUserName: String
    let toUserNickname: String?
    let toUserProfilePicUrl: String?
    let status: FriendRequestStatus
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, fromUserId, toUserId, fromUserName, fromUserNickname, fromUserProfilePicUrl
        case toUserName, toUserNickname, toUserProfilePicUrl, status, createdAt, updatedAt
    }
}

/// Friend request status enum
enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted" 
    case declined = "declined"
    case blocked = "blocked"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .blocked:
            return "Blocked"
        }
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

// MARK: - Friend Comparison Models

/// Simplified item model for friend comparisons
struct PrestigeItem: Identifiable {
    let id: String
    let name: String
    let imageUrl: String
    let itemType: PrestigeItemType
    
    enum PrestigeItemType: String, CaseIterable {
        case track = "track"
        case album = "album"
        case artist = "artist"
        
        var displayName: String {
            switch self {
            case .track: return "Track"
            case .album: return "Album"
            case .artist: return "Artist"
            }
        }
    }
}