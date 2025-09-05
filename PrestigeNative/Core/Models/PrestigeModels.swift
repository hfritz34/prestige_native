//
//  PrestigeModels.swift
//  Prestige System Models and Calculations
//
//  This file contains the core prestige system logic, including
//  prestige levels, calculations, and user listening data models
//

import Foundation

// MARK: - Prestige System

/// Prestige levels based on listening dedication (matches backend tier order)
enum PrestigeLevel: String, CaseIterable, Codable {
    case none = "None"
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case sapphire = "Sapphire"
    case emerald = "Emerald"
    case diamond = "Diamond"
    case garnet = "Garnet"
    case opal = "Opal"
    case peridot = "Peridot"
    case jet = "Jet"
    case darkMatter = "Dark Matter"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .none: return "No Badge"
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .peridot: return "Peridot"
        case .gold: return "Gold"
        case .emerald: return "Emerald"
        case .sapphire: return "Sapphire"
        case .garnet: return "Garnet"
        case .jet: return "Jet"
        case .diamond: return "Diamond"
        case .opal: return "Opal"
        case .darkMatter: return "Dark Matter"
        }
    }
    
    /// Image name for prestige badge
    var imageName: String {
        switch self {
        case .none: return ""
        case .bronze: return "bronze"
        case .silver: return "silver"
        case .peridot: return "peridot"
        case .gold: return "gold"
        case .emerald: return "emerald"
        case .sapphire: return "sapphire"
        case .garnet: return "garnet"
        case .jet: return "jet"
        case .diamond: return "diamond"
        case .opal: return "opal"
        case .darkMatter: return "darkmatter"
        }
    }
    
    /// Color associated with prestige level
    var color: String {
        switch self {
        case .none: return "#6B7280"      // Gray
        case .bronze: return "#CD7F32"    // Bronze
        case .silver: return "#C0C0C0"    // Silver
        case .peridot: return "#9ACD32"   // Yellow-green
        case .gold: return "#FFD700"      // Gold
        case .emerald: return "#50C878"   // Emerald green
        case .sapphire: return "#0F52BA"  // Sapphire blue
        case .garnet: return "#733635"    // Garnet red
        case .jet: return "#343434"       // Jet black
        case .diamond: return "#B9F2FF"   // Diamond blue
        case .opal: return "#FFEFDB"      // Opal white
        case .darkMatter: return "#301934" // Dark purple
        }
    }
    
    /// Numeric order for comparison (matches backend tier progression)
    var order: Int {
        switch self {
        case .none: return 0
        case .bronze: return 1
        case .silver: return 2
        case .peridot: return 3     // Fixed: moved from 9 to 3
        case .gold: return 4        // Fixed: moved from 3 to 4
        case .emerald: return 5     // Correct position
        case .sapphire: return 6    // Fixed: moved from 4 to 6
        case .garnet: return 7      // Correct position
        case .jet: return 8         // Fixed: moved from 10 to 8
        case .diamond: return 9     // Fixed: moved from 6 to 9
        case .opal: return 10       // Fixed: moved from 8 to 10
        case .darkMatter: return 11 // Correct position
        }
    }
    
    /// Convert backend tier format to iOS enum
    static func fromBackendTier(_ backendTier: String) -> PrestigeLevel {
        // Handle the main difference: "DarkMatter" -> "Dark Matter"
        let normalizedTier = backendTier == "DarkMatter" ? "Dark Matter" : backendTier
        return PrestigeLevel(rawValue: normalizedTier) ?? .none
    }
}

// MARK: - Prestige calculation now handled by backend
// All prestige tier calculations moved to backend API endpoints

// MARK: - User-Specific Models

/// User's track data with listening statistics
struct UserTrackResponse: Codable, Identifiable {
    let totalTime: Int          // Total listening time in seconds (from API)
    let track: TrackResponse    // Track information
    let userId: String          // User ID
    let albumPosition: Int?     // Ranking within album (1 = best track)
    let totalTracksInAlbum: Int? // Total tracks in the album
    let isPinned: Bool          // Whether track is pinned (required field)
    let rating: Double?         // User's rating score (1-10)
    let rankWithinAlbum: Int?   // Ranking position within the album
    let prestigeTier: String?   // Prestige tier from backend (e.g., "Gold", "Diamond")
    
    init(totalTime: Int, track: TrackResponse, userId: String, 
         albumPosition: Int? = nil, totalTracksInAlbum: Int? = nil, 
         isPinned: Bool = false, rating: Double? = nil, rankWithinAlbum: Int? = nil,
         prestigeTier: String? = nil) {
        self.totalTime = totalTime
        self.track = track
        self.userId = userId
        self.albumPosition = albumPosition
        self.totalTracksInAlbum = totalTracksInAlbum
        self.isPinned = isPinned
        self.rating = rating
        self.rankWithinAlbum = rankWithinAlbum
        self.prestigeTier = prestigeTier
    }
    
    var id: String { track.id }
    
    // Prestige level from backend data (no longer calculated locally)
    var prestigeLevel: PrestigeLevel {
        print("🔍 UserTrackResponse.prestigeLevel - prestigeTier: \(prestigeTier ?? "nil") for track: \(track.name)")
        guard let tier = prestigeTier else { 
            print("🔍 No prestige tier for track: \(track.name)")
            return .none 
        }
        let level = PrestigeLevel.fromBackendTier(tier)
        print("🔍 Mapped prestige level: \(level) for track: \(track.name)")
        return level
    }
    
    // Convenience properties
    var totalTimeMinutes: Int { totalTime / 60 }
    var totalTimeHours: Double { Double(totalTime) / 3600.0 }
    
    // Album rank display
    var albumRankDisplay: String? {
        guard let position = albumPosition, let total = totalTracksInAlbum else { return nil }
        return "#\(position) of \(total)"
    }
    
    enum CodingKeys: String, CodingKey {
        case totalTime, track, userId
        case albumPosition, totalTracksInAlbum
        case isPinned, rating, rankWithinAlbum, prestigeTier
    }
}

/// User's album data with listening statistics
struct UserAlbumResponse: Codable, Identifiable {
    let totalTime: Int          // Total listening time in seconds (from API)
    let album: AlbumResponse    // Album information
    let userId: String          // User ID
    let isPinned: Bool          // Whether album is pinned (required field)
    let rating: Double?         // User's rating score (1-10)
    let prestigeTier: String?   // Prestige tier from backend (e.g., "Gold", "Diamond")
    
    init(totalTime: Int, album: AlbumResponse, userId: String, 
         isPinned: Bool = false, rating: Double? = nil, prestigeTier: String? = nil) {
        self.totalTime = totalTime
        self.album = album
        self.userId = userId
        self.isPinned = isPinned
        self.rating = rating
        self.prestigeTier = prestigeTier
    }
    
    var id: String { album.id }
    
    // Prestige level from backend data (no longer calculated locally)
    var prestigeLevel: PrestigeLevel {
        guard let tier = prestigeTier else { return .none }
        return PrestigeLevel.fromBackendTier(tier)
    }
    
    // Convenience properties
    var totalTimeMinutes: Int { totalTime / 60 }
    var totalTimeHours: Double { Double(totalTime) / 3600.0 }
    
    enum CodingKeys: String, CodingKey {
        case totalTime, album, userId
        case isPinned, rating, prestigeTier
    }
}

/// User's artist data with listening statistics
struct UserArtistResponse: Codable, Identifiable {
    let totalTime: Int          // Total listening time in seconds (from API)
    let artist: ArtistResponse  // Artist information
    let userId: String          // User ID
    let isPinned: Bool          // Whether artist is pinned (required field)
    let rating: Double?         // User's rating score (1-10)
    let prestigeTier: String?   // Prestige tier from backend (e.g., "Gold", "Diamond")
    
    init(totalTime: Int, artist: ArtistResponse, userId: String, 
         isPinned: Bool = false, rating: Double? = nil, prestigeTier: String? = nil) {
        self.totalTime = totalTime
        self.artist = artist
        self.userId = userId
        self.isPinned = isPinned
        self.rating = rating
        self.prestigeTier = prestigeTier
    }
    
    var id: String { artist.id }
    
    // Prestige level from backend data (no longer calculated locally)
    var prestigeLevel: PrestigeLevel {
        guard let tier = prestigeTier else { return .none }
        return PrestigeLevel.fromBackendTier(tier)
    }
    
    // Convenience properties
    var totalTimeMinutes: Int { totalTime / 60 }
    var totalTimeHours: Double { Double(totalTime) / 3600.0 }
    
    enum CodingKeys: String, CodingKey {
        case totalTime, artist, userId
        case isPinned, rating, prestigeTier
    }
}

// MARK: - New API Response Models for Album/Artist Rankings

/// Response for album tracks with ranking information
struct AlbumTracksWithRankingsResponse: Codable {
    let albumId: String
    let totalTracks: Int
    let ratedTracks: Int
    let allTracksRated: Bool
    let tracks: [AlbumTrackWithRanking]
}

/// Individual track with ranking within an album
struct AlbumTrackWithRanking: Codable, Identifiable {
    let trackId: String
    let trackName: String
    let artists: [ArtistInfo]
    let albumRanking: Int?
    let trackNumber: Int
    let hasUserRating: Bool
    let isPinned: Bool
    let isFavorite: Bool
    
    var id: String { trackId }
    
    struct ArtistInfo: Codable {
        let id: String
        let name: String
    }
}

/// Response for artist albums with user activity and ratings
struct ArtistAlbumsWithRankingsResponse: Codable {
    let artistId: String
    let totalAlbums: Int
    let albums: [ArtistAlbumWithRating]
    
    private enum CodingKeys: String, CodingKey {
        case artistId = "artistId"         // API returns camelCase
        case totalAlbums = "totalAlbums"   // API returns camelCase
        case albums = "albums"             // API returns camelCase
    }
    
    // Computed property for backwards compatibility
    var ratedAlbums: Int {
        return albums.count
    }
}

/// Individual album with rating information for an artist
struct ArtistAlbumWithRating: Codable, Identifiable {
    let albumId: String
    let albumName: String
    let artistName: String
    let albumImage: String?
    let albumRatingScore: Double?
    let albumRatingPosition: Int?
    let albumRatingCategory: String?
    let totalTracks: Int?      // NEW: Total tracks in album
    let ratedTracks: Int?      // NEW: User's rated tracks in album
    
    private enum CodingKeys: String, CodingKey {
        case albumId = "albumId"                         // API returns camelCase
        case albumName = "albumName"                     // API returns camelCase
        case artistName = "artistName"                   // API returns camelCase
        case albumImage = "albumImage"                   // API returns camelCase
        case albumRatingScore = "albumRatingScore"       // API returns camelCase
        case albumRatingPosition = "albumRatingPosition" // API returns camelCase
        case albumRatingCategory = "albumRatingCategory" // API returns camelCase
        case totalTracks = "totalTracks"                 // NEW: Total tracks
        case ratedTracks = "ratedTracks"                 // NEW: Rated tracks
    }
    
    var id: String { albumId }
    
    // Computed properties for backwards compatibility
    var totalListeningTime: Int { 0 } // Not available from API
    var releaseDate: String? { nil } // Not available from API
    var trackCount: Int { totalTracks ?? 0 } // Use totalTracks from API
}