//
//  RatingViewModel.swift
//  Rating View Model
//
//  Manages rating state, comparison logic, and coordinates
//  between the rating UI and the backend service
//

import Foundation
import Combine
import SwiftUI

@MainActor
class RatingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var categories: [RatingCategoryModel] = []
    @Published var userRatings: [String: [Rating]] = [:]
    @Published var unratedItems: [RatingItemData] = []
    @Published var recentlyPlayedItems: [RatingItemData] = []
    
    @Published var selectedItemType: RatingItemType = .track
    @Published var selectedCategory: RatingCategoryModel?
    @Published var currentRatingItem: RatingItemData?
    @Published var existingRating: Rating?
    
    @Published var comparisonItems: [RatingItemData] = []
    @Published var currentComparisonIndex = 0
    @Published var comparisons: [ComparisonPair] = []
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var showRatingModal = false
    @Published var ratingState: RatingFlowState = .idle
    
    // MARK: - Services
    
    private let ratingService = RatingService.shared
    private let spotifyService = SpotifyService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Rating Flow State
    
    enum RatingFlowState {
        case idle
        case selectingCategory
        case comparing
        case saving
        case completed
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        Task {
            await loadInitialData()
        }
    }
    
    private func setupBindings() {
        // Observe rating service updates
        ratingService.$categories
            .receive(on: DispatchQueue.main)
            .assign(to: &$categories)
        
        ratingService.$userRatings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratings in
                self?.userRatings = ratings
            }
            .store(in: &cancellables)
        
        ratingService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        do {
            isLoading = true
            
            // Load categories if not already loaded
            if categories.isEmpty {
                _ = try await ratingService.fetchCategories()
            }
            
            // Load user ratings for selected item type
            await loadUserRatings()
            
            // Load unrated items
            await loadUnratedItems()
            
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func loadUserRatings() async {
        do {
            _ = try await ratingService.fetchUserRatings(itemType: selectedItemType)
        } catch {
            print("Failed to load user ratings: \(error)")
        }
    }
    
    func loadUnratedItems() async {
        do {
            // This would typically fetch from Spotify service
            // For now, using placeholder logic
            let allItems = try await fetchAllUserItems(type: selectedItemType)
            let ratedIds = userRatings[selectedItemType.rawValue]?.map { $0.itemId } ?? []
            
            unratedItems = allItems.filter { !ratedIds.contains($0.id) }
        } catch {
            print("Failed to load unrated items: \(error)")
        }
    }
    
    func loadRecentlyPlayed() async {
        do {
            // Fetch recently played from Spotify
            let recentTracks = try await spotifyService.getRecentlyPlayed()
            let ratedIds = userRatings[RatingItemType.track.rawValue]?.map { $0.itemId } ?? []
            
            recentlyPlayedItems = recentTracks
                .filter { !ratedIds.contains($0.id) }
                .removingDuplicates()
        } catch {
            print("Failed to load recently played: \(error)")
        }
    }
    
    // MARK: - Rating Flow
    
    func startRating(for item: RatingItemData) async {
        currentRatingItem = item
        ratingState = .selectingCategory
        showRatingModal = true
        
        // Check for existing rating
        do {
            let response = try await ratingService.initializeRating(
                itemType: item.itemType,
                itemId: item.id
            )
            
            if let existing = response.existingRating {
                existingRating = existing
                selectedCategory = categories.first { $0.id == existing.categoryId }
            }
        } catch {
            self.error = "Failed to initialize rating: \(error.localizedDescription)"
        }
    }
    
    func selectCategory(_ category: RatingCategoryModel) {
        selectedCategory = category
        
        // If updating existing rating, skip to position selection
        if existingRating != nil {
            prepareComparisons()
        } else {
            // For new ratings, check if there are items to compare
            let categoryRatings = getRatingsInCategory(category)
            
            if categoryRatings.isEmpty {
                // No items to compare, assign top position
                saveRating(position: 0)
            } else {
                prepareComparisons()
            }
        }
    }
    
    private func prepareComparisons() {
        guard let category = selectedCategory,
              let item = currentRatingItem else { return }
        
        ratingState = .comparing
        
        // Get existing ratings in the selected category
        let categoryRatings = getRatingsInCategory(category)
        
        // For tracks, filter by album if applicable
        let relevantRatings: [Rating]
        if item.itemType == .track, let albumId = item.albumName {
            relevantRatings = categoryRatings.filter { rating in
                // This would need the album ID from the rating
                // For now, using all ratings in category
                return true
            }
        } else {
            relevantRatings = categoryRatings
        }
        
        // Sort by position
        let sortedRatings = relevantRatings.sorted { $0.position < $1.position }
        
        // Create comparison items
        // Using linear insertion for now (can be optimized to binary search)
        comparisonItems = []
        currentComparisonIndex = 0
        
        // Start from the lowest scored items
        if !sortedRatings.isEmpty {
            // Would need to fetch item data for each rating
            // For now, starting comparison flow
            ratingState = .comparing
        }
    }
    
    func handleComparison(winnerId: String) async {
        guard let item = currentRatingItem else { return }
        
        // Submit comparison to backend
        if currentComparisonIndex < comparisonItems.count {
            let comparisonItem = comparisonItems[currentComparisonIndex]
            
            do {
                _ = try await ratingService.submitComparison(
                    itemId1: item.id,
                    itemId2: comparisonItem.id,
                    itemType: item.itemType,
                    winnerId: winnerId
                )
            } catch {
                print("Failed to submit comparison: \(error)")
            }
        }
        
        // Move to next comparison or finish
        if currentComparisonIndex < comparisonItems.count - 1 {
            currentComparisonIndex += 1
        } else {
            // Determine final position based on comparisons
            let position = calculateFinalPosition()
            saveRating(position: position)
        }
    }
    
    func skipComparison() {
        // Skip current comparison
        if currentComparisonIndex < comparisonItems.count - 1 {
            currentComparisonIndex += 1
        } else {
            // Use middle position if all comparisons skipped
            let position = comparisonItems.count / 2
            saveRating(position: position)
        }
    }
    
    private func calculateFinalPosition() -> Int {
        // Based on comparison results, determine position
        // This is a simplified version - actual implementation would
        // use the comparison results to find the correct position
        return currentComparisonIndex
    }
    
    private func saveRating(position: Int) {
        guard let category = selectedCategory,
              let item = currentRatingItem else { return }
        
        ratingState = .saving
        
        Task {
            do {
                let rating = try await ratingService.saveRating(
                    itemId: item.id,
                    itemType: item.itemType,
                    score: Double(position), // Backend will calculate actual score
                    categoryId: category.id
                )
                
                ratingState = .completed
                
                // Update local state
                await loadUserRatings()
                
                // Close modal after short delay
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    showRatingModal = false
                    resetRatingFlow()
                }
            } catch {
                self.error = "Failed to save rating: \(error.localizedDescription)"
                ratingState = .idle
            }
        }
    }
    
    func deleteRating(_ rating: Rating) async {
        do {
            try await ratingService.deleteRating(
                itemType: rating.itemType,
                itemId: rating.itemId
            )
            
            // Reload data
            await loadUserRatings()
            await loadUnratedItems()
        } catch {
            self.error = "Failed to delete rating: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    
    private func getRatingsInCategory(_ category: RatingCategoryModel) -> [Rating] {
        return userRatings[selectedItemType.rawValue]?
            .filter { $0.categoryId == category.id }
            .sorted { $0.position < $1.position } ?? []
    }
    
    private func fetchAllUserItems(type: RatingItemType) async throws -> [RatingItemData] {
        // This would fetch from Spotify service based on type
        // For now, returning empty array
        return []
    }
    
    func resetRatingFlow() {
        currentRatingItem = nil
        selectedCategory = nil
        existingRating = nil
        comparisonItems = []
        currentComparisonIndex = 0
        comparisons = []
        ratingState = .idle
    }
    
    // MARK: - Computed Properties
    
    var currentComparisonProgress: (current: Int, total: Int) {
        (current: currentComparisonIndex + 1, total: max(comparisonItems.count, 1))
    }
    
    var ratingStatistics: RatingStatistics? {
        guard let ratings = userRatings[selectedItemType.rawValue] else { return nil }
        return ratingService.calculateStatistics(for: ratings)
    }
    
    var filteredRatings: [Rating] {
        userRatings[selectedItemType.rawValue] ?? []
    }
}

// MARK: - Array Extension for Removing Duplicates

extension Array where Element == RatingItemData {
    func removingDuplicates() -> [Element] {
        var seen = Set<String>()
        return filter { item in
            guard !seen.contains(item.id) else { return false }
            seen.insert(item.id)
            return true
        }
    }
}