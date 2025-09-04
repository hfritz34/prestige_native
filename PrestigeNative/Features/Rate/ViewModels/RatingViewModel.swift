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
#if os(iOS)
import UIKit
#endif

@MainActor
class RatingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var categories: [RatingCategoryModel] = []
    @Published var userRatings: [String: [Rating]] = [:]
    @Published var unratedItems: [RatingItemData] = []
    @Published var recentlyPlayedItems: [RatingItemData] = []
    @Published var searchResults: [RatingItemData] = []
    @Published var isSearching = false
    
    @Published var selectedItemType: RatingItemType = .album
    @Published var selectedCategory: RatingCategoryModel?
    @Published var currentRatingItem: RatingItemData?
    @Published var existingRating: Rating?
    
    // Track current item's album ID for track comparison filtering
    private var currentItemAlbumId: String?
    
    @Published var comparisonItems: [RatingItemData] = []
    @Published var currentComparisonIndex = 0
    @Published var comparisons: [ComparisonPair] = []
    
    // Binary search state
    var binarySearchState: BinarySearchState?
    
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = ""
    @Published var error: String?
    @Published var showRatingModal = false
    @Published var ratingState: RatingFlowState = .idle
    
    // MARK: - Services
    
    private let ratingService = RatingService.shared
    private let spotifyService = SpotifyService()
    private let libraryService = LibraryService()
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
    
    // MARK: - Binary Search State
    
    struct BinarySearchState {
        var sortedRatings: [Rating]
        var leftIndex: Int
        var rightIndex: Int
        var currentMidIndex: Int
        var comparisonResults: [(itemId: String, winnerId: String)]
        var finalPosition: Int?
        
        mutating func recordComparison(itemId: String, winnerId: String) {
            comparisonResults.append((itemId: itemId, winnerId: winnerId))
        }
        
        var isComplete: Bool {
            finalPosition != nil
        }
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
            loadingProgress = 0.0
            loadingMessage = "Loading rating system..."
            
            // Load categories if not already loaded
            if categories.isEmpty {
                loadingProgress = 0.1
                loadingMessage = "Loading rating categories..."
                _ = try await ratingService.fetchCategories()
            }
            
            loadingProgress = 0.2
            loadingMessage = "Preloading metadata for all content types..."
            // Preload metadata for all content types to prevent "Unknown" fallbacks
            await preloadAllContentMetadata()
            
            loadingProgress = 0.6
            loadingMessage = "Loading your ratings..."
            // Load user ratings for selected item type
            await loadUserRatings()
            
            loadingProgress = 0.8
            loadingMessage = "Loading unrated items..."
            // Load unrated items
            await loadUnratedItems()
            
            loadingProgress = 0.9
            loadingMessage = "Preparing display..."
            // Ensure metadata is loaded for immediate display
            await ensureMetadataLoaded()
            
            // Add a brief delay to ensure everything is ready for display
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            loadingProgress = 1.0
            loadingMessage = "Ready!"
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            loadingProgress = 0.0
            loadingMessage = ""
        }
    }
    
    /// Handles switching to a new item type with proper loading states
    func switchItemType(to newType: RatingItemType) async {
        // Set loading state immediately
        isLoading = true
        loadingProgress = 0.0
        loadingMessage = "Loading \(newType.displayName.lowercased())..."
        
        // Update the selected type
        selectedItemType = newType
        
        do {
            loadingProgress = 0.3
            loadingMessage = "Loading your ratings..."
            
            // Load ratings for the new type
            await loadUserRatings()
            
            loadingProgress = 0.7
            loadingMessage = "Loading unrated items..."
            
            // Load unrated items for the new type
            await loadUnratedItems()
            
            loadingProgress = 0.9
            loadingMessage = "Preparing metadata..."
            
            // Ensure metadata is loaded
            await ensureMetadataLoaded()
            
            loadingProgress = 1.0
            loadingMessage = "Ready!"
            
        } catch {
            print("Failed to switch item type: \(error)")
            self.error = error.localizedDescription
        }
        
        // Complete loading
        isLoading = false
        loadingProgress = 0.0
        loadingMessage = ""
    }

    func loadUserRatings() async {
        do {
            let ratings = try await ratingService.fetchUserRatings(itemType: selectedItemType)
            // Metadata is preloaded during initial data load, but load any missing items
            await loadMetadataForRatings(ratings)
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
                    albumId: rating.albumId,
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
                albumId: nil,
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
        
        // Reset selection state for new rating flow
        selectedCategory = nil
        existingRating = nil
        
        // Ensure selectedItemType matches the item being rated
        selectedItemType = item.itemType
        // Prefer albumId from the item payload when rating tracks; fallback to server init later
        if item.itemType == .track {
            currentItemAlbumId = item.albumId
        }
        print("🔵 RatingViewModel: startRating - selectedItemType set to: \(selectedItemType.rawValue)")
        
        // Ensure categories are loaded before proceeding
        if categories.isEmpty {
            do {
                _ = try await ratingService.fetchCategories()
            } catch {
                self.error = "Failed to load rating categories: \(error.localizedDescription)"
                return
            }
        }
        
        // Always load fresh user ratings for the selected type before comparisons
        // Web does this on every rate flow start to ensure latest data
        do {
            _ = try await ratingService.fetchUserRatings(itemType: item.itemType)
        } catch {
            print("Failed to prefetch user ratings for \(item.itemType.rawValue): \(error)")
            // Continue; flow can still proceed (will treat as first rating if none loaded)
        }
        
        // Check for existing rating
        do {
            let server = try await ratingService.initializeRating(
                itemType: item.itemType,
                itemId: item.id
            )
            
            // Store album ID for track comparison filtering, but don't overwrite a known albumId with nil
            if let serverAlbumId = server.albumId, !serverAlbumId.isEmpty {
                currentItemAlbumId = serverAlbumId
            }
            print("🔵 RatingViewModel: startRating - itemType: \(item.itemType.rawValue), itemId: \(item.id)")
            print("🔵 RatingViewModel: Server response albumId: \(server.albumId ?? "nil")")
            
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
                    rankWithinAlbum: server.rankWithinAlbum,
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
            let itemTypeInfo = selectedItemType == .track ? "track (albumId: \(currentItemAlbumId ?? "nil"))" : selectedItemType.rawValue
            print("🔵 RatingViewModel: selectCategory - checking for items to compare for \(itemTypeInfo)")
            let categoryRatings = getRatingsInCategory(category, albumId: currentItemAlbumId)
            print("🔵 Ratings Debug: albumId=\(currentItemAlbumId ?? "nil"), allTypeRatings=\(userRatings[selectedItemType.rawValue]?.count ?? 0), partitionFiltered=\(categoryRatings.count)")
            
            if categoryRatings.isEmpty {
                if selectedItemType == .track {
                    print("✅ RatingViewModel: First track in this album's \(category.name) category - assigning position 0")
                } else {
                    print("✅ RatingViewModel: First \(selectedItemType.rawValue) in \(category.name) category - assigning position 0")
                }
                // No items to compare, assign top position
                saveRating(position: 0)
            } else {
                if selectedItemType == .track {
                    print("🔵 RatingViewModel: Found \(categoryRatings.count) other rated tracks in same album - starting album-scoped comparisons")
                } else {
                    print("🔵 RatingViewModel: Found \(categoryRatings.count) other rated \(selectedItemType.rawValue)s - starting comparisons")
                }
                prepareComparisons()
            }
        }
    }
    
    private func prepareComparisons() {
        guard let category = selectedCategory,
              let item = currentRatingItem else { return }
        
        // Get existing ratings in the selected category, filtered by album for tracks
        var categoryRatings = getRatingsInCategory(category, albumId: currentItemAlbumId)

        // If item is track and we have zero candidates but user has other track ratings,
        // attempt to enrich missing albumIds from metadata and retry once
        if item.itemType == .track,
           categoryRatings.isEmpty,
           let allTrackRatings = userRatings[RatingItemType.track.rawValue],
           !allTrackRatings.isEmpty {
            // Find ratings in this category with missing albumId
            let missingAlbumRatings = allTrackRatings.filter { $0.categoryId == category.id && $0.albumId == nil }
            if !missingAlbumRatings.isEmpty {
                Task {
                    let itemsToFetch = missingAlbumRatings.map { (id: $0.itemId, type: RatingItemType.track) }
                    let details = await libraryService.getItemDetailsBatch(items: itemsToFetch)
                    // Update cache for these items (albumName/Id available in ItemDetailsResponse)
                    await MainActor.run {
                        for d in details {
                            let updated = RatingItemData(
                                id: d.id,
                                name: d.name,
                                imageUrl: d.imageUrl,
                                artists: d.artists,
                                albumName: d.albumName,
                                albumId: d.albumId,
                                itemType: .track
                            )
                            itemCache[d.id] = updated
                        }
                    }
                    // Retry computing candidates
                    let retried = getRatingsInCategory(category, albumId: currentItemAlbumId)
                    await MainActor.run {
                        categoryRatings = retried
                        if categoryRatings.isEmpty {
                            // Still empty, save as first in category
                            saveRating(position: 0)
                        } else {
                            // Proceed with comparisons
                            let sortedRatings = categoryRatings.sorted { $0.personalScore > $1.personalScore }
                            binarySearchState = BinarySearchState(
                                sortedRatings: sortedRatings,
                                leftIndex: 0,
                                rightIndex: sortedRatings.count - 1,
                                currentMidIndex: sortedRatings.count / 2,
                                comparisonResults: [],
                                finalPosition: nil
                            )
                            startNextComparison()
                        }
                    }
                }
                return
            }
        }
        
        // If there are no items to compare, save immediately at top position
        guard !categoryRatings.isEmpty else {
            // First item in category gets position 0
            saveRating(position: 0)
            return
        }
        
        // Sort by score descending (highest score first)
        let sortedRatings = categoryRatings.sorted { $0.personalScore > $1.personalScore }
        
        // Initialize binary search state
        binarySearchState = BinarySearchState(
            sortedRatings: sortedRatings,
            leftIndex: 0,
            rightIndex: sortedRatings.count - 1,
            currentMidIndex: sortedRatings.count / 2,
            comparisonResults: [],
            finalPosition: nil
        )
        
        // Start with middle item for comparison
        startNextComparison()
    }
    
    private func startNextComparison() {
        guard var searchState = binarySearchState,
              let _ = currentRatingItem else { return }
        
        // Check if search is complete
        if searchState.leftIndex > searchState.rightIndex {
            // Binary search complete, determine final position
            let finalPosition = searchState.leftIndex
            binarySearchState?.finalPosition = finalPosition
            
            // Save rating with position - let backend calculate score
            saveRating(position: finalPosition)
            return
        }
        
        // Calculate middle index (favor higher value for even count)
        let midIndex = (searchState.leftIndex + searchState.rightIndex) / 2
        binarySearchState?.currentMidIndex = midIndex
        
        // Get the item at middle position for comparison
        let comparisonRating = searchState.sortedRatings[midIndex]
        
        // Get item data for comparison with metadata
        let comparisonItem: RatingItemData
        if let cached = itemCache[comparisonRating.itemId] {
            comparisonItem = cached
        } else {
            // Create placeholder item first for immediate display
            comparisonItem = RatingItemData(
                id: comparisonRating.itemId,
                name: "Loading...",
                imageUrl: nil,
                artists: nil,
                albumName: nil,
                albumId: nil,
                itemType: comparisonRating.itemType
            )
            
            // Fetch item details from LibraryService asynchronously
            Task {
                do {
                    let itemDetails = try await libraryService.getItemDetails(
                        itemId: comparisonRating.itemId, 
                        itemType: comparisonRating.itemType
                    )
                    
                    let updatedItem = RatingItemData(
                        id: itemDetails.id,
                        name: itemDetails.name,
                        imageUrl: itemDetails.imageUrl,
                        artists: itemDetails.artists,
                        albumName: itemDetails.albumName,
                        albumId: itemDetails.albumId ?? (comparisonRating.itemType == .track ? self.currentItemAlbumId : nil),
                        itemType: comparisonRating.itemType
                    )
                    
                    // Cache for future use
                    await MainActor.run {
                        itemCache[comparisonRating.itemId] = updatedItem
                        // Update comparison items if this is still the current comparison
                        if comparisonItems.first?.id == comparisonRating.itemId {
                            comparisonItems = [updatedItem]
                        }
                    }
                    
                    print("✅ Fetched metadata for comparison item: \(itemDetails.name)")
                } catch {
                    print("❌ Failed to fetch metadata for \(comparisonRating.itemId): \(error)")
                }
            }
        }
        
        // Set up for comparison
        comparisonItems = [comparisonItem]
        currentComparisonIndex = 0
        ratingState = .comparing
    }
    
    func handleComparison(winnerId: String) async {
        guard let item = currentRatingItem,
              var searchState = binarySearchState else { return }
        
        // Get the comparison item
        guard currentComparisonIndex < comparisonItems.count else { return }
        let comparisonItem = comparisonItems[currentComparisonIndex]
        
        // Submit comparison to backend
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
        
        // Record comparison result
        searchState.recordComparison(itemId: comparisonItem.id, winnerId: winnerId)
        binarySearchState = searchState
        
        // Update binary search bounds based on comparison result
        if winnerId == item.id {
            // New item won - it's better, so it goes LEFT (higher position/score)
            binarySearchState?.rightIndex = searchState.currentMidIndex - 1
        } else {
            // Existing item won - new item is worse, so it goes RIGHT (lower position/score)
            binarySearchState?.leftIndex = searchState.currentMidIndex + 1
        }
        
        // Continue with next comparison
        startNextComparison()
    }
    
    func skipComparison() {
        guard var searchState = binarySearchState else { return }
        
        // For skipped comparisons, treat as a tie and place after the current item (lower score)
        binarySearchState?.leftIndex = searchState.currentMidIndex + 1
        
        // Continue with next comparison
        startNextComparison()
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
                    position: position,
                    categoryId: category.id
                )
                
                ratingState = .completed
                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                
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
    
    private func getRatingsInCategory(_ category: RatingCategoryModel, albumId: String? = nil) -> [Rating] {
        // Partition gating via score range (matches web behavior)
        let allTypeRatings = userRatings[selectedItemType.rawValue] ?? []
        let categoryRatings = allTypeRatings.filter { rating in
            rating.personalScore >= category.minScore && rating.personalScore <= category.maxScore
        }
        
        print("🔵 RatingViewModel: getRatingsInCategory - itemType: \(selectedItemType.rawValue), category: \(category.name)")
        print("🔵 RatingViewModel: Total category ratings: \(categoryRatings.count)")
        
        // For tracks, filter by album to only compare tracks within the same album
        if selectedItemType == .track {
            print("🔵 RatingViewModel: Filtering tracks by album - provided albumId: \(albumId ?? "nil")")
            
            guard let albumId = albumId else {
                print("❌ RatingViewModel: No albumId provided for track comparison - cannot filter by album")
                // If we don't have albumId for a track, this should not happen normally,
                // but return empty to be safe and trigger position 0
                return []
            }
            
            // Primary filter using rating.albumId; fallback to itemCache metadata when albumId is missing on rating
            let albumFilteredRatings = categoryRatings.filter { rating in
                if rating.albumId == albumId { return true }
                if rating.albumId == nil, let cached = itemCache[rating.itemId], cached.albumId == albumId {
                    return true
                }
                return false
            }
            print("🔵 RatingViewModel: Tracks in same album (\(albumId)): \(albumFilteredRatings.count)")
            
            if albumFilteredRatings.isEmpty {
                print("✅ RatingViewModel: No other tracks rated in this album - first track will get position 0")
            } else {
                print("🔵 RatingViewModel: Found \(albumFilteredRatings.count) rated tracks in same album for comparison:")
                // Log details of found tracks
                for (index, rating) in albumFilteredRatings.enumerated() {
                    print("  Track \(index + 1): \(rating.itemId), albumId: \(rating.albumId ?? "nil"), score: \(rating.personalScore)")
                }
            }
            
            return albumFilteredRatings.sorted { $0.personalScore > $1.personalScore }
        }
        
        print("🔵 RatingViewModel: Non-track comparison - returning \(categoryRatings.count) items")
        return categoryRatings.sorted { $0.personalScore > $1.personalScore }
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
                albumId: track.album.id,
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
                albumId: nil,
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
                albumId: nil,
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
        binarySearchState = nil
        currentItemAlbumId = nil // Reset album ID tracking
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

    /// Load metadata for a batch of ratings to populate itemCache
    private func loadMetadataForRatings(_ ratings: [Rating]) async {
        let itemIds = Array(Set(ratings.map { $0.itemId })) // Remove duplicates
        
        // Only load metadata for items not already in cache
        let uncachedIds = itemIds.filter { itemCache[$0] == nil }
        
        guard !uncachedIds.isEmpty else { return }
        
        do {
            // Load metadata in batches to avoid overwhelming the API
            let batchSize = 20
            for batch in uncachedIds.chunked(into: batchSize) {
                await withTaskGroup(of: Void.self) { group in
                    for itemId in batch {
                        group.addTask { [weak self] in
                            guard let self = self else { return }
                            
                            // Find the rating to determine item type
                            if let rating = ratings.first(where: { $0.itemId == itemId }) {
                                do {
                                    let details = try await self.libraryService.getItemDetails(
                                        itemId: itemId,
                                        itemType: rating.itemType
                                    )
                                    
                                    let itemData = RatingItemData(
                                        id: itemId,
                                        name: details.name,
                                        imageUrl: details.imageUrl,
                                        artists: details.artists,
                                        albumName: details.albumName,
                                        albumId: details.albumId,
                                        itemType: rating.itemType
                                    )
                                    
                                    await MainActor.run {
                                        self.itemCache[itemId] = itemData
                                    }
                                } catch {
                                    print("Failed to load metadata for item \(itemId): \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Preload metadata for all content types to prevent "Unknown" fallbacks
    private func preloadAllContentMetadata() async {
        print("🔄 Starting comprehensive metadata preloading for all content types...")
        
        loadingMessage = "Fetching tracks ratings..."
        // Fetch ratings for all content types concurrently
        async let tracksTask = ratingService.fetchUserRatings(itemType: .track)
        
        loadingMessage = "Fetching albums ratings..."
        async let albumsTask = ratingService.fetchUserRatings(itemType: .album) 
        
        loadingMessage = "Fetching artists ratings..."
        async let artistsTask = ratingService.fetchUserRatings(itemType: .artist)
        
        do {
            let (tracks, albums, artists) = try await (tracksTask, albumsTask, artistsTask)
            
            // Combine all ratings for batch metadata loading
            let allRatings = tracks + albums + artists
            print("📊 Preloading metadata for \(allRatings.count) total ratings (\(tracks.count) tracks, \(albums.count) albums, \(artists.count) artists)")
            
            loadingMessage = "Loading metadata for \(allRatings.count) items..."
            // Load metadata for all ratings
            await loadMetadataForRatings(allRatings)
            
            print("✅ Comprehensive metadata preloading completed")
        } catch {
            print("⚠️ Failed to preload some metadata: \(error)")
        }
    }
    
    func getItemData(for rating: Rating) -> RatingItemData? {
        return itemCache[rating.itemId]
    }
    
    /// Ensure metadata is loaded for current ratings - call this before accessing rated items
    func ensureMetadataLoaded() async {
        let currentRatings = userRatings[selectedItemType.rawValue] ?? []
        await loadMetadataForRatings(currentRatings)
    }
    
    // MARK: - Computed Properties
    
    var currentComparisonProgress: (current: Int, total: Int) {
        if let searchState = binarySearchState {
            // Calculate progress based on binary search depth
            let totalRatings = searchState.sortedRatings.count
            let maxComparisons = totalRatings > 0 ? Int(log2(Double(totalRatings))) + 1 : 1
            let currentComparison = searchState.comparisonResults.count + 1
            return (current: min(currentComparison, maxComparisons), total: maxComparisons)
        } else {
            // Fallback for simple comparison mode
            return (current: currentComparisonIndex + 1, total: max(comparisonItems.count, 1))
        }
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

