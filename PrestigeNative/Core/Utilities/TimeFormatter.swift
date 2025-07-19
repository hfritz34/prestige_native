//
//  TimeFormatter.swift
//  Time Formatting Utilities
//
//  Provides consistent time formatting across the app for listening time display.
//

import Foundation

struct TimeFormatter {
    
    /// Formats listening time from milliseconds to a human-readable string
    /// - Parameter milliseconds: Total listening time in milliseconds
    /// - Returns: Formatted string (e.g., "45m", "1h 25m", "24h 30m")
    static func formatListeningTime(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let totalMinutes = seconds / 60
        let hours = totalMinutes / 60
        let remainingMinutes = totalMinutes % 60
        
        if hours > 0 {
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(totalMinutes)m"
        }
    }
    
    /// Formats listening time with more detailed breakdown for very large values
    /// - Parameter milliseconds: Total listening time in milliseconds
    /// - Returns: Formatted string with days if applicable (e.g., "2d 5h", "1d 12h 30m")
    static func formatDetailedListeningTime(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let totalMinutes = seconds / 60
        let totalHours = totalMinutes / 60
        let days = totalHours / 24
        let remainingHours = totalHours % 24
        let remainingMinutes = totalMinutes % 60
        
        if days > 0 {
            if remainingHours > 0 {
                return "\(days)d \(remainingHours)h"
            } else {
                return "\(days)d"
            }
        } else if totalHours > 0 {
            if remainingMinutes > 0 {
                return "\(totalHours)h \(remainingMinutes)m"
            } else {
                return "\(totalHours)h"
            }
        } else {
            return "\(totalMinutes)m"
        }
    }
    
    /// Formats listening time in minutes only (for display compatibility)
    /// - Parameter milliseconds: Total listening time in milliseconds
    /// - Returns: Total minutes as string (e.g., "180 minutes")
    static func formatMinutesOnly(_ milliseconds: Int) -> String {
        let totalMinutes = milliseconds / (1000 * 60)
        return "\(totalMinutes) minutes"
    }
}