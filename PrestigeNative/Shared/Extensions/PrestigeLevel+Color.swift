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
        case .peridot: return Color(red: 0.604, green: 0.804, blue: 0.196)   // Yellow-green
        case .gold: return Color(red: 1.0, green: 0.843, blue: 0.0)          // Gold
        case .emerald: return Color(red: 0.314, green: 0.784, blue: 0.471)   // Emerald green
        case .sapphire: return Color(red: 0.059, green: 0.322, blue: 0.729)  // Sapphire blue
        case .amber: return Color(red: 1.0, green: 0.749, blue: 0.0)       // Amber gold
        case .jet: return Color(red: 0.204, green: 0.204, blue: 0.204)       // Jet black
        case .diamond: return Color(red: 0.725, green: 0.949, blue: 1.0)     // Diamond blue
        case .opal: return Color(red: 1.0, green: 0.937, blue: 0.859)        // Opal white
        case .darkMatter: return Color(red: 0.188, green: 0.098, blue: 0.204) // Dark purple
        case .ruby: return Color(red: 0.878, green: 0.067, blue: 0.373)      // Ruby red
        case .jade: return Color(red: 0.0, green: 0.659, blue: 0.420)        // Jade green
        case .amethyst: return Color(red: 0.608, green: 0.349, blue: 0.714)  // Amethyst purple
        case .cosmic: return Color(red: 0.294, green: 0.0, blue: 0.510)      // Cosmic indigo
        }
    }
}