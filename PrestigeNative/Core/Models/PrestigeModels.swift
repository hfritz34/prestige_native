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
    case emerald = "Emerald"
    case amber = "Amber"
    case amethyst = "Amethyst"
    case quartz = "Quartz"
    case diamond = "Diamond"
    case jade = "Jade"
    case ruby = "Ruby"
    case pearl = "Pearl"
    case loveydovey = "Loveydovey"
    case tourmaline = "Tourmaline"
    case topaz = "Topaz"
    case tanazanite = "Tanazanite"
    case prestige = "Prestige"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .none: return "No Badge"
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .emerald: return "Emerald"
        case .amber: return "Amber"
        case .amethyst: return "Amethyst"
        case .quartz: return "Quartz"
        case .diamond: return "Diamond"
        case .jade: return "Jade"
        case .ruby: return "Ruby"
        case .pearl: return "Pearl"
        case .loveydovey: return "Lovey Dovey"
        case .tourmaline: return "Tourmaline"
        case .topaz: return "Topaz"
        case .tanazanite: return "Tanazanite"
        case .prestige: return "Prestige"
        }
    }
    
    /// Image name for prestige badge
    var imageName: String {
        switch self {
        case .none: return ""
        case .bronze: return "bronze"
        case .silver: return "silver"
        case .gold: return "gold"
        case .emerald: return "emerald"
        case .amber: return "amber"
        case .amethyst: return "amethyst"
        case .quartz: return "quartz"
        case .diamond: return "diamond"
        case .jade: return "jade"
        case .ruby: return "ruby"
        case .pearl: return "pearl"
        case .loveydovey: return "loveydovey"
        case .tourmaline: return "tourmaline"
        case .topaz: return "topaz"
        case .tanazanite: return "tanazanite"
        case .prestige: return "prestige"
        }
    }
    
    /// Color associated with prestige level
    var color: String {
        switch self {
        case .none: return "#6B7280"      // Gray
        case .bronze: return "#CD7F32"    // Bronze
        case .silver: return "#C0C0C0"    // Silver
        case .gold: return "#FFD700"      // Gold
        case .emerald: return "#50C878"   // Emerald green
        case .amber: return "#FFBF00"     // Amber gold
        case .amethyst: return "#9966CC"  // Amethyst purple
        case .quartz: return "#F0E8E8"    // Quartz white-pink
        case .diamond: return "#B9F2FF"   // Diamond blue
        case .jade: return "#00A86B"      // Jade green
        case .ruby: return "#E0115F"      // Ruby red
        case .pearl: return "#FAF0E6"     // Pearl white
        case .loveydovey: return "#FF69B4"// Hot pink
        case .tourmaline: return "#86608E" // Tourmaline purple
        case .topaz: return "#FFC87C"     // Topaz yellow
        case .tanazanite: return "#4B61D1" // Tanzanite blue-violet
        case .prestige: return "#FFD700"  // Prestige gold
        }
    }
    
    /// Get next prestige level (returns nil if at max level)
    var nextLevel: PrestigeLevel? {
        let allCases = PrestigeLevel.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex < allCases.count - 1 else {
            return nil
        }
        return allCases[currentIndex + 1]
    }
    
    /// Create PrestigeLevel from string
    static func fromString(_ string: String) -> PrestigeLevel? {
        return PrestigeLevel(rawValue: string) ?? 
               PrestigeLevel.allCases.first { $0.rawValue.lowercased() == string.lowercased() }
    }
    
    /// Numeric order for comparison (matches backend tier progression)
    var order: Int {
        switch self {
        case .none: return 0
        case .bronze: return 1
        case .silver: return 2
        case .gold: return 3
        case .emerald: return 4
        case .amber: return 5
        case .amethyst: return 6
        case .quartz: return 7
        case .diamond: return 8
        case .jade: return 9
        case .ruby: return 10
        case .pearl: return 11
        case .loveydovey: return 12
        case .tourmaline: return 13
        case .topaz: return 14
        case .tanazanite: return 15
        case .prestige: return 16     // Final ultimate tier
        }
    }
    
    /// Convert backend tier format to iOS enum
    static func fromBackendTier(_ backendTier: String) -> PrestigeLevel {
        // Backend sends "Loveydovey" with capital L, we use "Loveydovey" in our enum
        // All other tiers should match directly
        return PrestigeLevel(rawValue: backendTier) ?? .none
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
    let personalRatingScore: Double? // Personal rating score from backend
    let ratingPosition: Int?    // Position in user's rated tracks
    
    init(totalTime: Int, track: TrackResponse, userId: String, 
         albumPosition: Int? = nil, totalTracksInAlbum: Int? = nil, 
         isPinned: Bool = false, rating: Double? = nil, rankWithinAlbum: Int? = nil,
         prestigeTier: String? = nil, personalRatingScore: Double? = nil, 
         ratingPosition: Int? = nil) {
        self.totalTime = totalTime
        self.track = track
        self.userId = userId
        self.albumPosition = albumPosition
        self.totalTracksInAlbum = totalTracksInAlbum
        self.isPinned = isPinned
        self.rating = rating
        self.rankWithinAlbum = rankWithinAlbum
        self.prestigeTier = prestigeTier
        self.personalRatingScore = personalRatingScore
        self.ratingPosition = ratingPosition
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
        case personalRatingScore, ratingPosition
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
    let personalRatingScore: Double? // Personal rating score from backend
    let ratingPosition: Int?    // Position in user's rated albums
    
    init(totalTime: Int, album: AlbumResponse, userId: String, 
         isPinned: Bool = false, rating: Double? = nil, prestigeTier: String? = nil,
         personalRatingScore: Double? = nil, ratingPosition: Int? = nil) {
        self.totalTime = totalTime
        self.album = album
        self.userId = userId
        self.isPinned = isPinned
        self.rating = rating
        self.prestigeTier = prestigeTier
        self.personalRatingScore = personalRatingScore
        self.ratingPosition = ratingPosition
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
        case personalRatingScore, ratingPosition
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
    let personalRatingScore: Double? // Personal rating score from backend
    let ratingPosition: Int?    // Position in user's rated artists
    
    init(totalTime: Int, artist: ArtistResponse, userId: String, 
         isPinned: Bool = false, rating: Double? = nil, prestigeTier: String? = nil,
         personalRatingScore: Double? = nil, ratingPosition: Int? = nil) {
        self.totalTime = totalTime
        self.artist = artist
        self.userId = userId
        self.isPinned = isPinned
        self.rating = rating
        self.prestigeTier = prestigeTier
        self.personalRatingScore = personalRatingScore
        self.ratingPosition = ratingPosition
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
        case personalRatingScore, ratingPosition
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