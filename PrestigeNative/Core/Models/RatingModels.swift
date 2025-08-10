//
//  RatingModels.swift
//  Rating System Models
//
//  This file contains all rating-related models that correspond to
//  the Prestige.Api backend rating system
//

import Foundation

// MARK: - Rating Category

struct RatingCategoryModel: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let minScore: Double
    let maxScore: Double
    let colorHex: String
    let displayOrder: Int
    
    var displayName: String {
        switch name.lowercased() {
        case "loved": return "I loved it"
        case "liked": return "It was okay"
        case "disliked": return "I didn't like it"
        default: return name
        }
    }
    
    var emoji: String {
        switch name.lowercased() {
        case "loved": return "😍"
        case "liked": return "👍"
        case "disliked": return "👎"
        default: return "⭐"
        }
    }
}

// MARK: - Rating

struct Rating: Codable, Identifiable {
    let id: String
    let userId: String
    let itemId: String
    let itemType: RatingItemType
    let albumId: String?
    let categoryId: String
    let category: RatingCategoryModel?
    let position: Int
    let personalScore: Double
    let createdAt: Date?
    let updatedAt: Date?
    
    var displayScore: String {
        String(format: "%.1f", personalScore)
    }
}

// MARK: - Rating Item Type

enum RatingItemType: String, Codable, CaseIterable {
    case track = "Track"
    case album = "Album"
    case artist = "Artist"
    
    var displayName: String {
        switch self {
        case .track: return "Tracks"
        case .album: return "Albums"
        case .artist: return "Artists"
        }
    }
    
    var singularName: String {
        switch self {
        case .track: return "Track"
        case .album: return "Album"
        case .artist: return "Artist"
        }
    }
}

// MARK: - Rating Comparison

struct RatingComparison: Codable {
    let id: String
    let userId: String
    let itemId1: String
    let itemId2: String
    let itemType: RatingItemType
    let winnerId: String
    let comparisonDate: Date
}

// MARK: - Request Models

struct SaveRatingRequest: Codable {
    let itemId: String
    let itemType: String
    let personalScore: Double
    let categoryId: String
}

struct ComparisonRequest: Codable {
    let itemId1: String
    let itemId2: String
    let itemType: String
    let winnerId: String
}

// MARK: - Response Models

struct RatingResponse: Codable {
    let rating: Rating?
    let message: String?
    let isSuccess: Bool
}

struct RatingCategoryResponse: Codable {
    let categories: [RatingCategoryModel]
}

struct ComparisonResultResponse: Codable {
    let success: Bool
    let message: String?
    let comparisonId: String?
}

struct RatingInitResponse: Codable {
    let existingRating: Rating?
    let itemData: RatingItemData
}

// MARK: - Rating Item Data

struct RatingItemData: Codable {
    let id: String
    let name: String
    let imageUrl: String?
    let artists: [String]?
    let albumName: String?
    let itemType: RatingItemType
}

// MARK: - Extended Rating Models for UI

struct RatedItem: Identifiable {
    let id: String
    let rating: Rating
    let itemData: RatingItemData
    
    var displayTitle: String {
        itemData.name
    }
    
    var displaySubtitle: String {
        switch itemData.itemType {
        case .track:
            return itemData.artists?.joined(separator: ", ") ?? ""
        case .album:
            return itemData.artists?.joined(separator: ", ") ?? ""
        case .artist:
            return ""
        }
    }
    
    var imageUrl: String {
        itemData.imageUrl ?? ""
    }
}

// MARK: - UI State Models

struct RatingState {
    var selectedCategory: RatingCategoryModel?
    var currentPosition: Int = 0
    var comparisons: [ComparisonPair] = []
    var currentComparisonIndex: Int = 0
    var isLoading: Bool = false
    var error: String?
}

struct ComparisonPair {
    let item1: RatingItemData
    let item2: RatingItemData
    var winnerId: String?
}

// MARK: - Rating Statistics

struct RatingStatistics {
    let totalRatings: Int
    let lovedCount: Int
    let likedCount: Int
    let dislikedCount: Int
    let averageScore: Double
    
    var lovedPercentage: Double {
        guard totalRatings > 0 else { return 0 }
        return Double(lovedCount) / Double(totalRatings) * 100
    }
    
    var likedPercentage: Double {
        guard totalRatings > 0 else { return 0 }
        return Double(likedCount) / Double(totalRatings) * 100
    }
    
    var dislikedPercentage: Double {
        guard totalRatings > 0 else { return 0 }
        return Double(dislikedCount) / Double(totalRatings) * 100
    }
}