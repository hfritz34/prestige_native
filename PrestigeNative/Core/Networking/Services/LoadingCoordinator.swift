//
//  LoadingCoordinator.swift
//  Unified Loading System for Batch Data Fetching
//
//  Coordinates loading of multiple data types simultaneously
//  to provide a unified loading experience with all content
//  appearing at once rather than staggered.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Loading State

enum LoadingState: Equatable {
    case idle
    case loading(progress: Double)
    case loaded
    case error(APIError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var hasError: Bool {
        if case .error = self { return true }
        return false
    }
}

// MARK: - Content Bundle

struct PrestigeContentBundle {
    let tracks: [UserTrackResponse]
    let albums: [UserAlbumResponse]
    let artists: [UserArtistResponse]
    let pinnedItems: PinnedItemsResponse?
    let recentlyUpdated: RecentlyUpdatedResponse?
    
    var isEmpty: Bool {
        return tracks.isEmpty && albums.isEmpty && artists.isEmpty
    }
}

// MARK: - Pinned Items Response

struct PinnedItemsResponse: Codable {
    let tracks: [UserTrackResponse]
    let albums: [UserAlbumResponse]
    let artists: [UserArtistResponse]
}

// MARK: - Recently Updated Response (defined in APIModels.swift)
// RecentlyUpdatedResponse is now defined in APIModels.swift to avoid duplication

// MARK: - Loading Coordinator

class LoadingCoordinator: ObservableObject {
    @Published var loadingState: LoadingState = .idle
    @Published var contentBundle: PrestigeContentBundle?
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = ""
    
    private let apiClient: APIClient
    private let profileService: ProfileService
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for different time ranges
    private var cachedContent: [PrestigeTimeRange: PrestigeContentBundle] = [:]
    private var lastFetchTime: [PrestigeTimeRange: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes for most content
    private let recentlyUpdatedCacheDuration: TimeInterval = 3600 // 1 hour for recently updated
    private let pinnedItemsCacheDuration: TimeInterval = 1800 // 30 minutes for pinned items
    
    init(apiClient: APIClient = .shared, profileService: ProfileService = ProfileService()) {
        self.apiClient = apiClient
        self.profileService = profileService
    }
    
    // MARK: - Public Methods
    
    /// Load all content for a given time range
    @MainActor
    func loadAllContent(
        for userId: String,
        timeRange: PrestigeTimeRange,
        forceRefresh: Bool = false
    ) async {
        // Apply network simulation if enabled (for testing)
        do {
            try await NetworkSimulator.shared.simulateDelay()
        } catch {
            self.loadingState = .error(APIError.networkError(error))
            return
        }
        
        // Check cache if not forcing refresh
        if !forceRefresh, let cached = getCachedContent(for: timeRange) {
            self.contentBundle = cached
            self.loadingState = .loaded
            return
        }
        
        // Start loading
        self.loadingState = .loading(progress: 0.0)
        self.loadingMessage = "Loading your prestige data..."
        
        do {
            let bundle = try await fetchContentBundle(
                userId: userId,
                timeRange: timeRange
            )
            
            // Cache the result
            cacheContent(bundle, for: timeRange)
            
            // Update state
            self.contentBundle = bundle
            self.loadingState = .loaded
            self.loadingProgress = 1.0
            
        } catch let error as APIError {
            self.loadingState = .error(error)
        } catch {
            self.loadingState = .error(.networkError(error))
        }
    }
    
    /// Preload images for visible content
    func preloadImages(for contentType: ContentType, limit: Int = 50) async {
        guard let bundle = contentBundle else { return }
        
        let imageUrls: [String] = switch contentType {
        case .tracks:
            bundle.tracks.prefix(limit).compactMap { $0.track.album.images.first?.url }
        case .albums:
            bundle.albums.prefix(limit).compactMap { $0.album.images.first?.url }
        case .artists:
            bundle.artists.prefix(limit).compactMap { $0.artist.images.first?.url }
        }
        
        // Preload images using URLSession to populate cache
        await withTaskGroup(of: Void.self) { group in
            for url in imageUrls {
                group.addTask {
                    await self.preloadImage(url: url)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchContentBundle(
        userId: String,
        timeRange: PrestigeTimeRange
    ) async throws -> PrestigeContentBundle {
        
        updateProgress(0.1, message: "Connecting to server...")
        
        switch timeRange {
        case .allTime:
            return try await fetchAllTimeContent(userId: userId)
        case .recentlyUpdated:
            return try await fetchRecentlyUpdatedContent(userId: userId)
        case .pinned:
            return try await fetchPinnedContent(userId: userId)
        }
    }
    
    private func fetchAllTimeContent(userId: String) async throws -> PrestigeContentBundle {
        updateProgress(0.2, message: "Fetching your top tracks...")
        
        // Use async let for parallel fetching
        async let tracksTask = fetchTracks(userId: userId)
        async let albumsTask = fetchAlbums(userId: userId)
        async let artistsTask = fetchArtists(userId: userId)
        
        // Wait for all three to complete
        let (tracks, albums, artists) = try await (tracksTask, albumsTask, artistsTask)
        
        updateProgress(0.8, message: "Processing prestige levels...")
        
        // Sort by prestige level and total time
        let sortedTracks = tracks.sorted { 
            if $0.prestigeLevel.order != $1.prestigeLevel.order {
                return $0.prestigeLevel.order > $1.prestigeLevel.order
            }
            return $0.totalTime > $1.totalTime
        }
        
        let sortedAlbums = albums.sorted {
            if $0.prestigeLevel.order != $1.prestigeLevel.order {
                return $0.prestigeLevel.order > $1.prestigeLevel.order
            }
            return $0.totalTime > $1.totalTime
        }
        
        let sortedArtists = artists.sorted {
            if $0.prestigeLevel.order != $1.prestigeLevel.order {
                return $0.prestigeLevel.order > $1.prestigeLevel.order
            }
            return $0.totalTime > $1.totalTime
        }
        
        updateProgress(0.9, message: "Preparing display...")
        
        return PrestigeContentBundle(
            tracks: Array(sortedTracks.prefix(100)), // Increased from 60
            albums: Array(sortedAlbums.prefix(100)), // Increased from 60
            artists: Array(sortedArtists.prefix(100)), // Increased from 60
            pinnedItems: nil,
            recentlyUpdated: nil
        )
    }
    
    private func fetchRecentlyUpdatedContent(userId: String) async throws -> PrestigeContentBundle {
        updateProgress(0.2, message: "Fetching recently updated items...")
        
        let profileService = ProfileService()
        let recentData = await profileService.fetchRecentlyUpdated(userId: userId)
        
        updateProgress(0.8, message: "Sorting by total listening time...")
        
        // Sort all recently updated items by total listening time (greatest to least)
        let sortedTracks = recentData.tracks.sorted { $0.totalTime > $1.totalTime }
        let sortedAlbums = recentData.albums.sorted { $0.totalTime > $1.totalTime }
        let sortedArtists = recentData.artists.sorted { $0.totalTime > $1.totalTime }
        
        return PrestigeContentBundle(
            tracks: sortedTracks,
            albums: sortedAlbums,
            artists: sortedArtists,
            pinnedItems: nil,
            recentlyUpdated: RecentlyUpdatedResponse(
                tracks: sortedTracks,
                albums: sortedAlbums,
                artists: sortedArtists
            )
        )
    }
    
    private func fetchPinnedContent(userId: String) async throws -> PrestigeContentBundle {
        updateProgress(0.2, message: "Fetching pinned items...")
        
        // Get pinned items response from API
        let pinnedResponse = try await apiClient.get("prestige/\(userId)/pinned", responseType: PinnedItemsResponse.self)
        
        updateProgress(0.9, message: "Organizing pinned content...")
        
        return PrestigeContentBundle(
            tracks: pinnedResponse.tracks,
            albums: pinnedResponse.albums,
            artists: pinnedResponse.artists,
            pinnedItems: nil,
            recentlyUpdated: nil
        )
    }
    
    private func fetchTracks(userId: String) async throws -> [UserTrackResponse] {
        updateProgress(0.3, message: "Loading tracks...")
        let tracks = try await apiClient.getUserTracks(userId: userId)
        
        updateProgress(0.4, message: "Loading track rankings...")
        return try await enhanceTracksWithRankings(tracks: tracks)
    }
    
    private func enhanceTracksWithRankings(tracks: [UserTrackResponse]) async throws -> [UserTrackResponse] {
        // Fetch track ratings to get album rankings
        let trackRatings = try await RatingService.shared.fetchUserRatings(itemType: .track)
        
        // Create a lookup dictionary for quick access
        let ratingLookup = Dictionary(uniqueKeysWithValues: trackRatings.map { ($0.itemId, $0) })
        
        // Enhance tracks with album ranking information
        return tracks.map { track in
            let rating = ratingLookup[track.track.id]
            return UserTrackResponse(
                totalTime: track.totalTime,
                track: track.track,
                userId: track.userId,
                albumPosition: rating?.rankWithinAlbum,
                totalTracksInAlbum: nil, // Will need separate logic to get total tracks
                isPinned: track.isPinned,
                rating: rating?.personalScore,
                prestigeTier: track.prestigeTier // CRITICAL: Preserve the prestige tier from original track!
            )
        }
    }
    
    private func fetchAlbums(userId: String) async throws -> [UserAlbumResponse] {
        updateProgress(0.4, message: "Loading albums...")
        return try await apiClient.getUserAlbums(userId: userId)
    }
    
    private func fetchArtists(userId: String) async throws -> [UserArtistResponse] {
        updateProgress(0.5, message: "Loading artists...")
        return try await apiClient.getUserArtists(userId: userId)
    }
    
    private func preloadImage(url: String) async {
        guard let imageUrl = URL(string: url) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageUrl)
            // Data is now in URLCache
            _ = data
        } catch {
            // Silently fail for image preloading
            print("Failed to preload image: \(url)")
        }
    }
    
    private func updateProgress(_ progress: Double, message: String) {
        DispatchQueue.main.async {
            self.loadingProgress = progress
            self.loadingMessage = message
            self.loadingState = .loading(progress: progress)
        }
    }
    
    // MARK: - Cache Management
    
    private func getCachedContent(for timeRange: PrestigeTimeRange) -> PrestigeContentBundle? {
        guard let cached = cachedContent[timeRange],
              let fetchTime = lastFetchTime[timeRange] else {
            return nil
        }
        
        // Use appropriate cache duration based on content type
        let cacheDuration = switch timeRange {
        case .recentlyUpdated: recentlyUpdatedCacheDuration
        case .pinned: pinnedItemsCacheDuration  
        case .allTime: cacheValidityDuration
        }
        
        guard Date().timeIntervalSince(fetchTime) < cacheDuration else {
            return nil
        }
        
        return cached
    }
    
    private func cacheContent(_ bundle: PrestigeContentBundle, for timeRange: PrestigeTimeRange) {
        cachedContent[timeRange] = bundle
        lastFetchTime[timeRange] = Date()
    }
    
    func clearCache() {
        cachedContent.removeAll()
        lastFetchTime.removeAll()
    }
}

