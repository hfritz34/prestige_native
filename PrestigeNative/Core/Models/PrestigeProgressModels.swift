//
//  PrestigeProgressModels.swift
//  Models for prestige progress calculation
//
//  Defines the data structures for tracking user progress toward next prestige tiers.
//

import Foundation

// MARK: - Progress Response Models

struct PrestigeProgressResponse: Codable {
    let itemId: String
    let itemType: String
    let itemName: String
    let currentLevel: PrestigeProgressLevel
    let nextLevel: PrestigeProgressLevel?
    let progress: ProgressDetails
    let estimatedTimeToNext: TimeEstimation?
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case itemType = "item_type" 
        case itemName = "item_name"
        case currentLevel = "current_level"
        case nextLevel = "next_level"
        case progress
        case estimatedTimeToNext = "estimated_time_to_next"
    }
}

struct PrestigeProgressLevel: Codable {
    let tier: String
    let displayName: String
    let color: String
    let imageName: String
    let threshold: Double
    
    enum CodingKeys: String, CodingKey {
        case tier
        case displayName = "display_name"
        case color
        case imageName = "image_name"
        case threshold
    }
}

struct ProgressDetails: Codable {
    let currentValue: Double
    let nextThreshold: Double?
    let percentage: Double
    let isMaxLevel: Bool
    
    enum CodingKeys: String, CodingKey {
        case currentValue = "current_value"
        case nextThreshold = "next_threshold"
        case percentage
        case isMaxLevel = "is_max_level"
    }
}

struct TimeEstimation: Codable {
    let minutesRemaining: Double
    let formattedTime: String
    let estimationType: String // "based_on_recent_activity", "average_rate", "minimum_rate"
    
    enum CodingKeys: String, CodingKey {
        case minutesRemaining = "minutes_remaining"
        case formattedTime = "formatted_time"
        case estimationType = "estimation_type"
    }
}

// MARK: - Convenience Extensions

extension PrestigeProgressResponse {
    var progressValue: Double {
        progress.percentage / 100.0
    }
    
    var hasNextLevel: Bool {
        nextLevel != nil && !progress.isMaxLevel
    }
    
    var progressText: String? {
        guard let timeEst = estimatedTimeToNext else { return nil }
        return "\(timeEst.formattedTime) more to reach \(nextLevel?.displayName ?? "max level")"
    }
}

extension PrestigeProgressLevel {
    func toPrestigeLevel() -> PrestigeLevel {
        return PrestigeLevel.fromString(tier) ?? .none
    }
}