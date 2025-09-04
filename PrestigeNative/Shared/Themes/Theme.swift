//
//  Theme.swift
//  Centralized app colors
//

import SwiftUI
import UIKit

enum Theme {
    // Primary brand color - use sparingly as accent
    static let primary = Color(hex: "#5167FC") ?? .purple
    static let primarySoft = (Color(hex: "#5167FC") ?? .purple).opacity(0.08)
    
    // Neutral colors for modern, clean UI
    static let accent = Color(hex: "#5167FC") ?? .purple
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.6)
    
    // Surface colors with subtle depth
    static let surface = Color(UIColor.secondarySystemBackground)
    static let surfaceElevated = Color(UIColor.tertiarySystemBackground)
    static let surfaceGlass = Color.white.opacity(0.05)
    
    // Button styles - minimal and clean
    static let buttonBackground = Color(UIColor.systemBackground).opacity(0.9)
    static let buttonBackgroundPressed = Color(UIColor.systemGray6)
    
    // Shadows for modern depth
    static let shadowLight = Color.black.opacity(0.05)
    static let shadowMedium = Color.black.opacity(0.1)
    
    // Special colors (use sparingly)
    static let spotifyGreen = Color(hex: "#1DB954") ?? .green
    static let deleteRed = Color.red.opacity(0.9)
}


