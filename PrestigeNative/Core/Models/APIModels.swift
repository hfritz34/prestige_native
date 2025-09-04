//
//  APIModels.swift
//  Core API Models for PreNostige iOS
//
//  This file contains basic API response models that correspond to
//  the Prestige.Api backend responses
//

import Foundation

// MARK: - Core Data Models

/// Represents an image with dimensions
struct ImageResponse: Codable {
    let url: String
    let height: Int
    let width: Int
}

/// External URLs (typically Spotify links)
struct ExternalUrls: Codable {
    let spotify: String
}

/// Basic track information from Spotify
struct TrackResponse: Codable, Identifiable {
    let id: String
    let name: String
    let duration_ms: Int
    let album: AlbumInfo
    let artists: [ArtistInfo]

    struct AlbumInfo: Codable {
        let id: String
        let name: String
        let images: [ImageResponse]
    }

    struct ArtistInfo: Codable {
        let id: String
        let name: String
    }
}

/// Basic album information from Spotify
struct AlbumResponse: Codable, Identifiable {
    let id: String
    let name: String
    let images: [ImageResponse]
    let artists: [TrackResponse.ArtistInfo]

    enum CodingKeys: String, CodingKey {
        case id, name, images, artists
    }
}

/// Basic artist information from Spotify
struct ArtistResponse: Codable, Identifiable {
    let id: String
    let name: String
    let images: [ImageResponse]

    /// Computed property to get artist image URL
    var artistImageUrl: String {
        return images.first?.url ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, name, images
    }
}

// MARK: - Recently Played

/// Recently played track information
struct RecentlyPlayedResponse: Codable {
    let trackName: String
    let artistName: String
    let imageUrl: String
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case trackName, artistName, imageUrl, id
    }
}

// MARK: - Recently Updated

/// Response for recently updated items from hourly batch processing
struct RecentlyUpdatedResponse: Codable {
    let tracks: [UserTrackResponse]
    let albums: [UserAlbumResponse]
    let artists: [UserArtistResponse]

    /// Initialize with empty arrays by default
    init(tracks: [UserTrackResponse] = [], 
         albums: [UserAlbumResponse] = [], 
         artists: [UserArtistResponse] = []) {
        self.tracks = tracks
        self.albums = albums
        self.artists = artists
    }
}

// MARK: - Search Results

/// Search results from Spotify API
struct SearchResults: Codable {
    let artists: [ArtistResponse]?
    let albums: [AlbumResponse]?
    let tracks: [TrackResponse]?
    
    enum CodingKeys: String, CodingKey {
        case artists, albums, tracks
    }
}

// MARK: - Spotify Search Models

struct SpotifySearchResponse: Codable {
    let tracks: SpotifyTracksSearch?
    let albums: SpotifyAlbumsSearch?
    let artists: SpotifyArtistsSearch?
}

struct SpotifyTracksSearch: Codable {
    let items: [SpotifyTrackSearch]
}

struct SpotifyAlbumsSearch: Codable {
    let items: [SpotifyAlbumSearch]
}

struct SpotifyArtistsSearch: Codable {
    let items: [SpotifyArtistSearch]
}

struct SpotifyTrackSearch: Codable {
    let id: String
    let name: String
    let album: SpotifyAlbumSearch?
    let artists: [SpotifyArtistSimplified]?
}

struct SpotifyAlbumSearch: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
    let artists: [SpotifyArtistSimplified]?
}

struct SpotifyArtistSearch: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
    let followers: SpotifyFollowers?
}

struct SpotifyArtistSimplified: Codable {
    let id: String
    let name: String
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct SpotifyFollowers: Codable {
    let total: Int
}

// Typealias for handling the different search result types
typealias SpotifySearchItem = Codable

// MARK: - Error Handling

/// API error response structure
struct APIErrorResponse: Codable {
    let message: String
    let statusCode: Int
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case message, statusCode, timestamp
    }
}

/// Custom API errors
enum APIError: Error, LocalizedError, Equatable {
    case invalidResponse
    case decodingError(Error)
    case httpError(statusCode: Int, message: String?)
    case networkError(Error)
    case authenticationError
    case noData
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationError:
            return "Authentication failed"
        case .noData:
            return "No data received"
        case .invalidURL:
            return "Invalid URL"
        }
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse),
             (.authenticationError, .authenticationError),
             (.noData, .noData),
             (.invalidURL, .invalidURL):
            return true
        case let (.httpError(lhsCode, lhsMessage), .httpError(rhsCode, rhsMessage)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage
        case let (.decodingError(lhsError), .decodingError(rhsError)),
             let (.networkError(lhsError), .networkError(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Extensions

extension Date {
    /// Format date for display in the app
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Time ago string (e.g., "2 hours ago")
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Int {
    /// Format listening time as human-readable string
    var listeningTimeString: String {
        let minutes = self / 60
        let hours = minutes / 60
        let days = hours / 24
        
        if days > 0 {
            let remainingHours = hours % 24
            if remainingHours > 0 {
                return "\(days)d \(remainingHours)h"
            } else {
                return "\(days)d"
            }
        } else if hours > 0 {
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Friend Context Models

/// Friend's detailed item information with ratings and context
struct FriendItemDetailsResponse: Codable, Identifiable {
    let itemId: String
    var id: String { itemId }
    let itemType: String
    let itemName: String
    let itemImageUrl: String
    let friendId: String
    let friendNickname: String
    let friendListeningTime: Int?
    let friendRatingScore: Double?
    let friendPosition: Int?
    let friendPrestigeTier: String
    let friendRankWithinAlbum: Int?
    let isPinned: Bool
    let isFavorite: Bool
    let additionalData: AnyCodable?
    
    enum CodingKeys: String, CodingKey {
        case itemId, itemType, itemName, itemImageUrl
        case friendId, friendNickname, friendListeningTime
        case friendRatingScore, friendPosition, friendPrestigeTier
        case friendRankWithinAlbum, isPinned, isFavorite, additionalData
    }
}

/// Friend's track rankings within an album
struct FriendTrackRankingResponse: Codable, Identifiable {
    let trackId: String
    var id: String { trackId }
    let trackName: String
    let trackImageUrl: String
    let trackNumber: Int
    let duration: Int
    let friendId: String
    let friendListeningTime: Int?
    let friendRatingScore: Double?
    let friendPosition: Int?
    let friendRankWithinAlbum: Int?
    let friendPrestigeTier: String
    
    enum CodingKeys: String, CodingKey {
        case trackId, trackName, trackImageUrl, trackNumber, duration
        case friendId, friendListeningTime, friendRatingScore
        case friendPosition, friendRankWithinAlbum, friendPrestigeTier
    }
}

/// Friend's album ratings within an artist
struct FriendAlbumRatingResponse: Codable, Identifiable {
    let albumId: String
    var id: String { albumId }
    let albumName: String
    let albumImageUrl: String
    let releaseDate: Date
    let trackCount: Int
    let friendId: String
    let friendListeningTime: Int?
    let friendRatingScore: Double?
    let friendPosition: Int?
    let friendPrestigeTier: String
    let isPinned: Bool
    let isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case albumId, albumName, albumImageUrl, releaseDate, trackCount
        case friendId, friendListeningTime, friendRatingScore
        case friendPosition, friendPrestigeTier, isPinned, isFavorite
    }
}

/// Enhanced comparison response with detailed rating data
struct EnhancedItemComparisonResponse: Codable {
    let itemId: String
    let itemType: String
    let itemName: String
    let itemImageUrl: String
    let friendId: String
    let friendNickname: String
    let userStats: UserComparisonStats
    let friendStats: UserComparisonStats
}

struct UserComparisonStats: Codable {
    let listeningTime: Int?
    let ratingScore: Double?
    let position: Int?
    let prestigeTier: String?
}

/// Helper for flexible JSON decoding
struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) where T: Codable {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else {
            value = ()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        }
    }
}