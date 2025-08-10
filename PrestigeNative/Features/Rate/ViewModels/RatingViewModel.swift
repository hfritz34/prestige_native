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
import UIKit

@MainActor
class RatingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var categories: [RatingCategoryModel] = []
    @Published var userRatings: [String: [Rating]] = [:]
    @Published var unratedItems: [RatingItemData] = []
    @Published var recentlyPlayedItems: [RatingItemData] = []
    @Published var searchResults: [RatingItemData] = []
    @Published var isSearching = false
    
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
    private var authManager: AuthManager?
    private var cancellables = Set<AnyCancellable>()
    private var itemCache: [String: RatingItemData] = [:]
    
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
        // Initial data load will be triggered from views after AuthManager is injected
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
    
    // MARK: - Search Functionality
    
    func searchLibrary(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }
        
        await MainActor.run { isSearching = true }
        
        do {
            // Prefer backend search for accuracy and scale
            let backendResults = try await searchUserLibrary(query: query)
            // Fallback: also merge frontend results to include local-only items
            let frontendResults = await searchExistingData(query: query)

            // Merge, preferring backend items
            let merged = (backendResults + frontendResults).removingDuplicates()
            await MainActor.run {
                self.searchResults = merged
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.error = "Search failed: \(error.localizedDescription)"
                self.isSearching = false
            }
        }
    }
    
    private func searchExistingData(query: String) async -> [RatingItemData] {
        let lowercaseQuery = query.lowercased()
        var results: [RatingItemData] = []
        
        // Search through unrated items
        let unratedMatches = unratedItems.filter { item in
            item.name.lowercased().contains(lowercaseQuery) ||
            (item.artists?.joined(separator: " ").lowercased().contains(lowercaseQuery) ?? false) ||
            (item.albumName?.lowercased().contains(lowercaseQuery) ?? false)
        }
        results.append(contentsOf: unratedMatches)
        
        // Search through rated items (convert from ratings)
        for (_, ratings) in userRatings {
            let ratedItemsData = ratings.compactMap { rating -> RatingItemData? in
                // Create item data from rating - ideally this would come from a proper data store
                return RatingItemData(
                    id: rating.itemId,
                    name: "Rated Item \(rating.itemId)", // Placeholder
                    imageUrl: nil,
                    artists: nil,
                    albumName: nil,
                    itemType: rating.itemType
                )
            }
            
            let ratedMatches = ratedItemsData.filter { item in
                item.name.lowercased().contains(lowercaseQuery)
            }
            results.append(contentsOf: ratedMatches)
        }
        
        // Remove duplicates and return
        return results.removingDuplicates()
    }
    
    // Backend search implementation
    private func searchUserLibrary(query: String) async throws -> [RatingItemData] {
        let type = selectedItemType.rawValue
        let endpoint = APIEndpoints.searchUserLibrary(query: query, type: type)
        let result: UserLibrarySearchResult = try await APIClient.shared.get(endpoint, responseType: UserLibrarySearchResult.self)
        let mapped = result.items.compactMap { item in
            RatingItemData(
                id: item.id,
                name: item.name,
                imageUrl: item.imageUrl,
                artists: item.artists,
                albumName: item.albumName,
                itemType: RatingItemType(rawValue: item.itemType) ?? selectedItemType
            )
        }
        cacheItems(mapped)
        return mapped
    }
    
    // MARK: - Rating Flow
    
    func startRating(for item: RatingItemData) async {
        currentRatingItem = item
        ratingState = .selectingCategory
        showRatingModal = true
        
        // Check for existing rating
        do {
            let server = try await ratingService.initializeRating(
                itemType: item.itemType,
                itemId: item.id
            )
            
            if server.isNewRating == false,
               let catId = server.categoryId,
               let score = server.personalScore,
               let pos = server.position {
                let existing = Rating(
                    itemId: server.itemId,
                    itemType: RatingItemType(rawValue: server.itemType) ?? item.itemType,
                    albumId: server.albumId,
                    categoryId: catId,
                    category: nil,
                    position: pos,
                    personalScore: score,
                    isNewRating: false
                )
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
        
        // Get existing ratings in the selected category
        let categoryRatings = getRatingsInCategory(category)
        
        // If there are no items to compare, save immediately
        guard !categoryRatings.isEmpty else {
            saveRating(position: 0)
            return
        }
        
        // Sort by position ascending
        let sortedRatings = categoryRatings.sorted { $0.position < $1.position }
        
        // Select strategic comparison points ~25%, 50%, 75%
        let indices = strategicIndices(count: sortedRatings.count)
        let selectedRatings = indices.map { sortedRatings[$0] }
        
        // Use cached item data when available; fall back to minimal placeholder
        comparisonItems = selectedRatings.map { rating in
            if let cached = itemCache[rating.itemId] { return cached }
            return RatingItemData(
                id: rating.itemId,
                name: "Unknown",
                imageUrl: nil,
                artists: nil,
                albumName: nil,
                itemType: rating.itemType
            )
        }
        
        currentComparisonIndex = 0
        ratingState = .comparing
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
                // Haptic feedback for comparison
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
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
        // Ensure we have an authenticated user
        guard let userId = authManager?.user?.id, !userId.isEmpty else {
            throw APIError.authenticationError
        }
        
        // Fetch user's prestige data and convert to RatingItemData
        switch type {
        case .track:
            return try await fetchUserTracks(userId: userId)
        case .album:
            return try await fetchUserAlbums(userId: userId)
        case .artist:
            return try await fetchUserArtists(userId: userId)
        }
    }
    
    private func fetchUserTracks(userId: String) async throws -> [RatingItemData] {
        // Fetch user's tracks from API
        let userTracks = try await APIClient.shared.getUserTracks(userId: userId)
        
        let items = userTracks.map { userTrack in
            let track = userTrack.track
            return RatingItemData(
                id: track.id,
                name: track.name,
                imageUrl: track.album.images.first?.url,
                artists: track.artists.map { $0.name },
                albumName: track.album.name,
                itemType: .track
            )
        }
        cacheItems(items)
        return items
    }
    
    private func fetchUserAlbums(userId: String) async throws -> [RatingItemData] {
        let userAlbums = try await APIClient.shared.getUserAlbums(userId: userId)
        
        let items = userAlbums.map { userAlbum in
            let album = userAlbum.album
            return RatingItemData(
                id: album.id,
                name: album.name,
                imageUrl: album.images.first?.url,
                artists: album.artists.map { $0.name },
                albumName: nil,
                itemType: .album
            )
        }
        cacheItems(items)
        return items
    }
    
    private func fetchUserArtists(userId: String) async throws -> [RatingItemData] {
        let userArtists = try await APIClient.shared.getUserArtists(userId: userId)
        
        let items = userArtists.map { userArtist in
            let artist = userArtist.artist
            return RatingItemData(
                id: artist.id,
                name: artist.name,
                imageUrl: artist.images.first?.url,
                artists: nil,
                albumName: nil,
                itemType: .artist
            )
        }
        cacheItems(items)
        return items
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

    
    func clearSearch() {
        searchResults = []
        isSearching = false
    }

    // MARK: - Item Cache Helpers
    private func cacheItems(_ items: [RatingItemData]) {
        for item in items { itemCache[item.id] = item }
    }

    func upsertItemData(_ item: RatingItemData) {
        itemCache[item.id] = item
    }

    func getItemData(for rating: Rating) -> RatingItemData? {
        return itemCache[rating.itemId]
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

    // MARK: - Dependency Injection
    @MainActor
    func setAuthManager(_ manager: AuthManager) {
        self.authManager = manager
    }

    // MARK: - Comparison Utilities
    private func strategicIndices(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        let positions: [Double] = [0.25, 0.5, 0.75]
        var indices = Set<Int>()
        for p in positions {
            let idx = min(max(Int((Double(count) - 1) * p), 0), count - 1)
            indices.insert(idx)
        }
        return Array(indices).sorted()
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

