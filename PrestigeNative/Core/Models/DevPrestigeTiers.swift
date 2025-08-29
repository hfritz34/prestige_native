//
//  DevPrestigeTiers.swift
//  Ultra-low prestige thresholds for demos
//

import Foundation

enum DevPrestigeTiers {
    // Toggle to enable dev tiers
    static let isEnabled: Bool = true

    // Max tiers within about an hour for quick demo spread
    // Values are minutes thresholds for the next tier
    static let trackThresholds: [Int]   = [2, 5, 8, 12, 18, 25, 35, 50, 75, 90, 120]
    static let albumThresholds: [Int]   = [5, 10, 15, 20, 30, 40, 55, 70, 85, 100, 120]
    static let artistThresholds: [Int]  = [10, 15, 20, 30, 40, 50, 65, 80, 95, 110, 120]

    static func thresholds(for itemType: PrestigeCalculator.ItemType) -> [Int] {
        switch itemType {
        case .track: return trackThresholds
        case .album: return albumThresholds
        case .artist: return artistThresholds
        }
    }
}


