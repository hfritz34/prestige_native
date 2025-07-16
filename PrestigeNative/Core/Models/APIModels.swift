//
//  APIModels.swift
//  Core API Models for Prestige iOS
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
struct TrackResponse: Codable {
    let id: String
    let name: String
    let imageUrl: String
    let spotifyUrl: String
    let albumName: String
    let artistName: String
    let durationMs: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageUrl, spotifyUrl, albumName, artistName, durationMs
    }
}

/// Basic album information from Spotify
struct AlbumResponse: Codable {
    let id: String
    let name: String
    let imageUrl: String
    let spotifyUrl: String
    let releaseDate: String
    let artistName: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageUrl, spotifyUrl, releaseDate, artistName
    }
}

/// Basic artist information from Spotify
struct ArtistResponse: Codable {
    let id: String
    let name: String
    let images: [ImageResponse]
    let spotifyUrl: String
    
    /// Computed property to get artist image URL
    var artistImageUrl: String {
        return images.first?.url ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, images, spotifyUrl
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