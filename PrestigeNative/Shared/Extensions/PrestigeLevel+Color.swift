//
//  PrestigeLevel+Color.swift
//  SwiftUI Color extension for PrestigeLevel
//

import SwiftUI

extension PrestigeLevel {
    /// SwiftUI Color for prestige level
    var swiftUIColor: Color {
        switch self {
        case .none: return Color.gray
        case .bronze: return Color(red: 0.804, green: 0.498, blue: 0.196)    // Bronze
        case .silver: return Color(red: 0.753, green: 0.753, blue: 0.753)    // Silver
        case .gold: return Color(red: 1.0, green: 0.843, blue: 0.0)          // Gold
        case .emerald: return Color(red: 0.314, green: 0.784, blue: 0.471)   // Emerald green
        case .amber: return Color(red: 1.0, green: 0.749, blue: 0.0)         // Amber gold
        case .amethyst: return Color(red: 0.608, green: 0.349, blue: 0.714)  // Amethyst purple
        case .quartz: return Color(red: 0.941, green: 0.910, blue: 0.910)    // Quartz white-pink
        case .diamond: return Color(red: 0.725, green: 0.949, blue: 1.0)     // Diamond blue
        case .jade: return Color(red: 0.0, green: 0.659, blue: 0.420)        // Jade green
        case .ruby: return Color(red: 0.878, green: 0.067, blue: 0.373)      // Ruby red
        case .pearl: return Color(red: 0.980, green: 0.941, blue: 0.902)     // Pearl white
        case .loveydovey: return Color(red: 1.0, green: 0.412, blue: 0.706)  // Hot pink
        case .tourmaline: return Color(red: 0.525, green: 0.376, blue: 0.557) // Tourmaline purple
        case .topaz: return Color(red: 1.0, green: 0.784, blue: 0.486)       // Topaz yellow
        case .tanazanite: return Color(red: 0.294, green: 0.380, blue: 0.820) // Tanzanite blue-violet
        case .prestige: return Color(red: 1.0, green: 0.843, blue: 0.0)      // Prestige gold
        }
    }
}