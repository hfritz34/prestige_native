//
//  UserStatisticsModels.swift
//  User Statistics Model
//

import Foundation

/// Response model for user statistics
struct UserStatisticsResponse: Codable {
    let friendsCount: Int
    let ratingsCount: Int
    let prestigesCount: Int
}