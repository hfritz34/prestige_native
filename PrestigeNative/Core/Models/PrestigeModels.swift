//
//  PrestigeModels.swift
//  Prestige System Models and Calculations
//
//  This file contains the core prestige system logic, including
//  prestige levels, calculations, and user listening data models
//

import Foundation

// MARK: - Prestige System

/// Prestige levels based on listening dedication
enum PrestigeLevel: String, CaseIterable, Codable {
    case none = "None"
    case bronze = "Bronze"
    case silver = "Silver"
    case peridot = "Peridot"
    case gold = "Gold"
    case emerald = "Emerald"
    case sapphire = "Sapphire"
    case garnet = "Garnet"
    case jet = "Jet"
    case diamond = "Diamond"
    case opal = "Opal"
    case darkMatter = "DarkMatter"
    
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
    
    /// Numeric order for comparison
    var order: Int {
        switch self {
        case .none: return 0
        case .bronze: return 1
        case .silver: return 2
        case .peridot: return 3
        case .gold: return 4
        case .emerald: return 5
        case .sapphire: return 6
        case .garnet: return 7
        case .jet: return 8
        case .diamond: return 9
        case .opal: return 10
        case .darkMatter: return 11
        }
    }
}

/// Prestige calculation logic (mirrors the frontend usePrestige hook)
struct PrestigeCalculator {
    
    /// Calculate prestige tier for tracks based on listening time
    /// - Parameter totalTimeMinutes: Total listening time in minutes
    /// - Returns: Appropriate prestige level
    static func getTrackPrestigeTier(totalTimeMinutes: Int) -> PrestigeLevel {
        if DevPrestigeTiers.isEnabled {
            return tier(from: totalTimeMinutes, thresholds: DevPrestigeTiers.trackThresholds)
        }
        switch totalTimeMinutes {
        case 15000...: return .darkMatter  // 15,000+ minutes
        case 6000..<15000: return .opal    // 6,000+ minutes
        case 3000..<6000: return .diamond  // 3,000+ minutes
        case 2200..<3000: return .jet      // 2,200+ minutes
        case 1600..<2200: return .garnet   // 1,600+ minutes
        case 1200..<1600: return .sapphire // 1,200+ minutes
        case 800..<1200: return .emerald   // 800+ minutes
        case 500..<800: return .gold       // 500+ minutes
        case 300..<500: return .peridot    // 300+ minutes
        case 150..<300: return .silver     // 150+ minutes
        case 60..<150: return .bronze      // 60+ minutes
        default: return .none              // Less than 60 minutes
        }
    }
    
    /// Calculate prestige tier for albums based on listening time
    /// - Parameter totalTimeMinutes: Total listening time in minutes
    /// - Returns: Appropriate prestige level
    static func getAlbumPrestigeTier(totalTimeMinutes: Int) -> PrestigeLevel {
        if DevPrestigeTiers.isEnabled {
            return tier(from: totalTimeMinutes, thresholds: DevPrestigeTiers.albumThresholds)
        }
        switch totalTimeMinutes {
        case 50000...: return .darkMatter  // 50,000+ minutes
        case 30000..<50000: return .opal   // 30,000+ minutes
        case 15000..<30000: return .diamond // 15,000+ minutes
        case 10000..<15000: return .jet    // 10,000+ minutes
        case 6000..<10000: return .garnet  // 6,000+ minutes
        case 4000..<6000: return .sapphire // 4,000+ minutes
        case 2000..<4000: return .emerald  // 2,000+ minutes
        case 1000..<2000: return .gold     // 1,000+ minutes
        case 500..<1000: return .peridot   // 500+ minutes
        case 350..<500: return .silver     // 350+ minutes
        case 200..<350: return .bronze     // 200+ minutes
        default: return .none              // Less than 200 minutes
        }
    }
    
    /// Calculate prestige tier for artists based on listening time
    /// - Parameter totalTimeMinutes: Total listening time in minutes
    /// - Returns: Appropriate prestige level
    static func getArtistPrestigeTier(totalTimeMinutes: Int) -> PrestigeLevel {
        if DevPrestigeTiers.isEnabled {
            return tier(from: totalTimeMinutes, thresholds: DevPrestigeTiers.artistThresholds)
        }
        switch totalTimeMinutes {
        case 100000...: return .darkMatter // 100,000+ minutes
        case 50000..<100000: return .opal  // 50,000+ minutes
        case 25000..<50000: return .diamond // 25,000+ minutes
        case 15000..<25000: return .jet    // 15,000+ minutes
        case 10000..<15000: return .garnet // 10,000+ minutes
        case 6000..<10000: return .sapphire // 6,000+ minutes
        case 3000..<6000: return .emerald  // 3,000+ minutes
        case 2000..<3000: return .gold     // 2,000+ minutes
        case 1200..<2000: return .peridot  // 1,200+ minutes
        case 750..<1200: return .silver    // 750+ minutes
        case 400..<750: return .bronze     // 400+ minutes
        default: return .none              // Less than 400 minutes
        }
    }
    
    /// Get next prestige tier and time needed
    /// - Parameters:
    ///   - currentLevel: Current prestige level
    ///   - totalTimeMinutes: Current listening time in minutes
    ///   - itemType: Type of item (track, album, artist)
    /// - Returns: Tuple of next level and minutes needed, or nil if at max level
    static func getNextTierInfo(currentLevel: PrestigeLevel, totalTimeMinutes: Int, itemType: ItemType) -> (nextLevel: PrestigeLevel, minutesNeeded: Int)? {
        let thresholds: [Int]
        
        if DevPrestigeTiers.isEnabled {
            thresholds = DevPrestigeTiers.thresholds(for: itemType)
        } else {
            switch itemType {
            case .track:
                thresholds = [60, 150, 300, 500, 800, 1200, 1600, 2200, 3000, 6000, 15000]
            case .album:
                thresholds = [200, 350, 500, 1000, 2000, 4000, 6000, 10000, 15000, 30000, 50000]
            case .artist:
                thresholds = [400, 750, 1200, 2000, 3000, 6000, 10000, 15000, 25000, 50000, 100000]
            }
        }
        
        let levels: [PrestigeLevel] = [.bronze, .silver, .peridot, .gold, .emerald, .sapphire, .garnet, .jet, .diamond, .opal, .darkMatter]
        
        for (index, threshold) in thresholds.enumerated() {
            if totalTimeMinutes < threshold {
                return (nextLevel: levels[index], minutesNeeded: threshold - totalTimeMinutes)
            }
        }
        
        return nil // Already at max level
    }
    
    private static func tier(from minutes: Int, thresholds: [Int]) -> PrestigeLevel {
        let levels: [PrestigeLevel] = [.bronze, .silver, .peridot, .gold, .emerald, .sapphire, .garnet, .jet, .diamond, .opal, .darkMatter]
        for (index, threshold) in thresholds.enumerated() {
            if minutes < threshold {
                return levels[index]
            }
        }
        return .darkMatter
    }
    
    enum ItemType {
        case track, album, artist
    }
}

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
    
    init(totalTime: Int, track: TrackResponse, userId: String, 
         albumPosition: Int? = nil, totalTracksInAlbum: Int? = nil, 
         isPinned: Bool = false, rating: Double? = nil, rankWithinAlbum: Int? = nil) {
        self.totalTime = totalTime
        self.track = track
        self.userId = userId
        self.albumPosition = albumPosition
        self.totalTracksInAlbum = totalTracksInAlbum
        self.isPinned = isPinned
        self.rating = rating
        self.rankWithinAlbum = rankWithinAlbum
    }
    
    var id: String { track.id }
    
    // Computed property for prestige level (calculated on frontend)
    // Note: API sends totalTime in seconds, so convert directly to minutes
    var prestigeLevel: PrestigeLevel {
        PrestigeCalculator.getTrackPrestigeTier(totalTimeMinutes: totalTime / 60)
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
        case isPinned, rating, rankWithinAlbum
    }
}

/// User's album data with listening statistics
struct UserAlbumResponse: Codable, Identifiable {
    let totalTime: Int          // Total listening time in seconds (from API)
    let album: AlbumResponse    // Album information
    let userId: String          // User ID
    let isPinned: Bool          // Whether album is pinned (required field)
    let rating: Double?         // User's rating score (1-10)
    
    init(totalTime: Int, album: AlbumResponse, userId: String, 
         isPinned: Bool = false, rating: Double? = nil) {
        self.totalTime = totalTime
        self.album = album
        self.userId = userId
        self.isPinned = isPinned
        self.rating = rating
    }
    
    var id: String { album.id }
    
    // Computed property for prestige level (calculated on frontend)
    // Note: API sends totalTime in seconds, so convert directly to minutes
    var prestigeLevel: PrestigeLevel {
        PrestigeCalculator.getAlbumPrestigeTier(totalTimeMinutes: totalTime / 60)
    }
    
    // Convenience properties
    var totalTimeMinutes: Int { totalTime / 60 }
    var totalTimeHours: Double { Double(totalTime) / 3600.0 }
    
    enum CodingKeys: String, CodingKey {
        case totalTime, album, userId
        case isPinned, rating
    }
}

/// User's artist data with listening statistics
struct UserArtistResponse: Codable, Identifiable {
    let totalTime: Int          // Total listening time in seconds (from API)
    let artist: ArtistResponse  // Artist information
    let userId: String          // User ID
    let isPinned: Bool          // Whether artist is pinned (required field)
    let rating: Double?         // User's rating score (1-10)
    
    init(totalTime: Int, artist: ArtistResponse, userId: String, 
         isPinned: Bool = false, rating: Double? = nil) {
        self.totalTime = totalTime
        self.artist = artist
        self.userId = userId
        self.isPinned = isPinned
        self.rating = rating
    }
    
    var id: String { artist.id }
    
    // Computed property for prestige level (calculated on frontend)
    // Note: API sends totalTime in seconds, so convert directly to minutes
    var prestigeLevel: PrestigeLevel {
        PrestigeCalculator.getArtistPrestigeTier(totalTimeMinutes: totalTime / 60)
    }
    
    // Convenience properties
    var totalTimeMinutes: Int { totalTime / 60 }
    var totalTimeHours: Double { Double(totalTime) / 3600.0 }
    
    enum CodingKeys: String, CodingKey {
        case totalTime, artist, userId
        case isPinned, rating
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