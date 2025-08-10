//
//  RatingService.swift
//  Rating Service for API Operations
//
//  This service handles all rating-related API calls including
//  fetching categories, saving ratings, and managing comparisons
//

import Foundation
import Combine

class RatingService: ObservableObject {
    static let shared = RatingService()
    private let apiClient = APIClient.shared
    
    @Published var categories: [RatingCategory] = []
    @Published var userRatings: [String: [Rating]] = [:]
    @Published var isLoading = false
    @Published var error: APIError?
    
    private init() {}
    
    // MARK: - Fetch Rating Categories
    
    func fetchCategories() async throws -> [RatingCategory] {
        do {
            let response = try await apiClient.get(
                APIEndpoints.ratingCategories,
                responseType: RatingCategoryResponse.self
            )
            
            await MainActor.run {
                self.categories = response.categories.sorted { $0.displayOrder < $1.displayOrder }
            }
            
            return response.categories
        } catch {
            await MainActor.run { self.error = error as? APIError }
            throw error
        }
    }
    
    // MARK: - Initialize Rating Process
    
    func initializeRating(itemType: RatingItemType, itemId: String) async throws -> RatingInitResponse {
        do {
            let endpoint = APIEndpoints.rateItem(itemType: itemType.rawValue, itemId: itemId)
            return try await apiClient.post(
                endpoint,
                body: EmptyBody(),
                responseType: RatingInitResponse.self
            )
        } catch {
            await MainActor.run { self.error = error as? APIError }
            throw error
        }
    }
    
    // MARK: - Save Rating
    
    func saveRating(
        itemId: String,
        itemType: RatingItemType,
        score: Double,
        categoryId: String
    ) async throws -> Rating {
        let request = SaveRatingRequest(
            itemId: itemId,
            itemType: itemType.rawValue,
            personalScore: score,
            categoryId: categoryId
        )
        
        do {
            let response = try await apiClient.post(
                APIEndpoints.saveRating,
                body: request,
                responseType: RatingResponse.self
            )
            
            guard response.isSuccess, let rating = response.rating else {
                throw APIError.invalidResponse
            }
            
            return rating
        } catch {
            await MainActor.run { self.error = error as? APIError }
            throw error
        }
    }
    
    // MARK: - Submit Comparison
    
    func submitComparison(
        itemId1: String,
        itemId2: String,
        itemType: RatingItemType,
        winnerId: String
    ) async throws -> ComparisonResultResponse {
        let request = ComparisonRequest(
            itemId1: itemId1,
            itemId2: itemId2,
            itemType: itemType.rawValue,
            winnerId: winnerId
        )
        
        do {
            return try await apiClient.post(
                APIEndpoints.submitComparison,
                body: request,
                responseType: ComparisonResultResponse.self
            )
        } catch {
            await MainActor.run { self.error = error as? APIError }
            throw error
        }
    }
    
    // MARK: - Fetch User Ratings
    
    func fetchUserRatings(itemType: RatingItemType) async throws -> [Rating] {
        do {
            await MainActor.run { self.isLoading = true }
            
            let endpoint = APIEndpoints.userRatings(itemType: itemType.rawValue)
            let ratings = try await apiClient.get(
                endpoint,
                responseType: [Rating].self
            )
            
            await MainActor.run {
                self.userRatings[itemType.rawValue] = ratings
                self.isLoading = false
            }
            
            return ratings
        } catch {
            await MainActor.run {
                self.error = error as? APIError
                self.isLoading = false
            }
            throw error
        }
    }
    
    // MARK: - Delete Rating
    
    func deleteRating(itemType: RatingItemType, itemId: String) async throws {
        do {
            let endpoint = APIEndpoints.deleteRating(itemType: itemType.rawValue, itemId: itemId)
            try await apiClient.delete(endpoint)
            
            // Remove from local cache
            await MainActor.run {
                if var ratings = self.userRatings[itemType.rawValue] {
                    ratings.removeAll { $0.itemId == itemId }
                    self.userRatings[itemType.rawValue] = ratings
                }
            }
        } catch {
            await MainActor.run { self.error = error as? APIError }
            throw error
        }
    }
    
    // MARK: - Get Ratings for Album Tracks
    
    func fetchAlbumTrackRatings(albumId: String) async throws -> [Rating] {
        let allTrackRatings = try await fetchUserRatings(itemType: .track)
        return allTrackRatings.filter { $0.albumId == albumId }
    }
    
    // MARK: - Calculate Rating Statistics
    
    func calculateStatistics(for ratings: [Rating]) -> RatingStatistics {
        let total = ratings.count
        let loved = ratings.filter { $0.personalScore >= 6.8 }.count
        let liked = ratings.filter { $0.personalScore >= 3.4 && $0.personalScore < 6.8 }.count
        let disliked = ratings.filter { $0.personalScore < 3.4 }.count
        
        let averageScore = ratings.isEmpty ? 0 : 
            ratings.reduce(0) { $0 + $1.personalScore } / Double(total)
        
        return RatingStatistics(
            totalRatings: total,
            lovedCount: loved,
            likedCount: liked,
            dislikedCount: disliked,
            averageScore: averageScore
        )
    }
    
    // MARK: - Helper Methods
    
    func getCategoryForScore(_ score: Double) -> RatingCategory? {
        return categories.first { category in
            score >= category.minScore && score <= category.maxScore
        }
    }
    
    func getRatingsInCategory(_ categoryId: String, itemType: RatingItemType) -> [Rating] {
        guard let ratings = userRatings[itemType.rawValue] else { return [] }
        return ratings
            .filter { $0.categoryId == categoryId }
            .sorted { $0.position < $1.position }
    }
}

// MARK: - Empty Body for POST requests without payload

private struct EmptyBody: Codable {}