//
//  Theme.swift
//  Centralized app colors
//

import SwiftUI

enum Theme {
    static let primary = Color(hex: "#5167FC") ?? .purple
    static let primarySoft = (Color(hex: "#5167FC") ?? .purple).opacity(0.12)
    static let accent = Color.purple
    static let textSecondary = Color.secondary
    static let surface = Color(UIColor.secondarySystemBackground)
    static let surfaceElevated = Color(UIColor.tertiarySystemBackground)
}


