//
//  ProfileViewModel.swift
//  Profile Screen ViewModel
//
//  Manages profile data including user info, stats, and top content.
//  Integrates with ProfileService and AuthManager.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserResponse?
    @Published var topTracks: [UserTrackResponse] = []
    @Published var topAlbums: [UserAlbumResponse] = []
    @Published var topArtists: [UserArtistResponse] = []
    @Published var favoriteTracks: [TrackResponse] = []
    @Published var favoriteAlbums: [AlbumResponse] = []
    @Published var favoriteArtists: [ArtistResponse] = []
    @Published var selectedFavoriteType: ContentType = .albums
    @Published var recentlyPlayed: [RecentlyPlayedResponse] = []
    @Published var ratedTracks: [RatedItem] = []
    @Published var ratedAlbums: [RatedItem] = []
    @Published var ratedArtists: [RatedItem] = []
    @Published var selectedRatingType: RatingItemType = .album
    @Published var isLoading = false
    @Published var ratingsLoaded = false
    @Published var error: APIError?
    @Published var selectedTimeRange: TimeRange = .allTime
    @Published var userStatistics: UserStatisticsResponse?
    
    private let profileService: ProfileService
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()
    private var currentLoadingTask: Task<Void, Never>?
    
    // Computed properties for stats
    var totalListeningTime: Int {
        // Sum of top tracks listening time (in minutes)
        topTracks.reduce(0) { $0 + $1.totalTimeMinutes }
    }
    
    var totalUniqueArtists: Int {
        Set(topTracks.flatMap { $0.track.artists.map { $0.name } }).count
    }
    
    var topPrestigeLevel: PrestigeLevel {
        // Get highest prestige level from top tracks
        topTracks.map { $0.prestigeLevel }.max { $0.order < $1.order } ?? .none
    }
    
    init(profileService: ProfileService = ProfileService(), authManager: AuthManager = AuthManager.shared) {
        self.profileService = profileService
        self.authManager = authManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind to ProfileService published properties
        profileService.$userProfile
            .assign(to: \.userProfile, on: self)
            .store(in: &cancellables)
        
        profileService.$topTracks
            .assign(to: \.topTracks, on: self)
            .store(in: &cancellables)
        
        profileService.$topAlbums
            .assign(to: \.topAlbums, on: self)
            .store(in: &cancellables)
        
        profileService.$topArtists
            .assign(to: \.topArtists, on: self)
            .store(in: &cancellables)
        
        profileService.$favoriteTracks
            .assign(to: \.favoriteTracks, on: self)
            .store(in: &cancellables)
        
        profileService.$favoriteAlbums
            .assign(to: \.favoriteAlbums, on: self)
            .store(in: &cancellables)
        
        profileService.$favoriteArtists
            .assign(to: \.favoriteArtists, on: self)
            .store(in: &cancellables)
        
        profileService.$recentlyPlayed
            .assign(to: \.recentlyPlayed, on: self)
            .store(in: &cancellables)
        
        profileService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        profileService.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        profileService.$userStatistics
            .assign(to: \.userStatistics, on: self)
            .store(in: &cancellables)
    }
    
    func loadProfileData(userId: String? = nil) {
        // Require a valid user ID - no fallback
        guard let actualUserId = userId, !actualUserId.isEmpty else {
            print("❌ ProfileViewModel: No valid user ID provided, cannot load data")
            return
        }
        
        print("🔵 ProfileViewModel: Loading data for user: \(actualUserId)")
        
        // Cancel any existing loading task
        currentLoadingTask?.cancel()
        
        currentLoadingTask = Task {
            // Load profile data and ratings in parallel
            async let profileTask = profileService.loadAllProfileData(userId: actualUserId)
            async let ratingsTask = loadRatingsData()
            
            // Wait for both to complete
            let _ = await (profileTask, ratingsTask)
            
            await MainActor.run {
                currentLoadingTask = nil
            }
        }
    }
    
    /// Load all profile data synchronously and wait for completion
    @MainActor
    func loadProfileDataSynchronously(userId: String) async {
        print("🔵 ProfileViewModel: Loading profile data synchronously for user: \(userId)")
        
        // Set loading state
        isLoading = true
        error = nil
        
        do {
            // Load all data concurrently and wait for completion
            async let profileTask = profileService.loadAllProfileData(userId: userId)
            async let ratingsTask = loadRatingsData()
            
            // Wait for both to complete
            let _ = try await (profileTask, ratingsTask)
            
            print("✅ ProfileViewModel: Synchronous loading completed successfully")
        } catch {
            print("❌ ProfileViewModel: Synchronous loading failed: \(error)")
            self.error = error as? APIError ?? .networkError(error)
        }
        
        // Always set loading to false when done
        isLoading = false
    }
    
    func refreshData() {
        loadProfileData()
    }
    
    /// Refresh data synchronously for pull-to-refresh
    @MainActor
    func refreshDataSynchronously() async {
        // Cancel any existing loading task to prevent cancellation errors
        currentLoadingTask?.cancel()
        
        guard let userId = authManager.user?.id else { return }
        
        currentLoadingTask = Task {
            await loadProfileDataSynchronously(userId: userId)
        }
        
        await currentLoadingTask?.value
        currentLoadingTask = nil
    }
    
    /// Load ratings data for all types
    func loadRatingsData() async {
        do {
            print("🔵 ProfileViewModel: Loading ratings data...")
            // Load ratings for all types concurrently
            async let tracks = APIClient.shared.getUserRatings(itemType: "track")
            async let albums = APIClient.shared.getUserRatings(itemType: "album") 
            async let artists = APIClient.shared.getUserRatings(itemType: "artist")
            
            let (loadedTracks, loadedAlbums, loadedArtists) = try await (tracks, albums, artists)
            
            await MainActor.run {
                // Sort tracks by album first, then by position within each album
                self.ratedTracks = loadedTracks.sorted { track1, track2 in
                    let album1 = track1.itemData.albumName ?? ""
                    let album2 = track2.itemData.albumName ?? ""
                    
                    if album1 != album2 {
                        return album1 < album2 // Sort albums alphabetically
                    } else {
                        return track1.rating.position < track2.rating.position // Then by position within album
                    }
                }
                // Sort albums and artists by score (descending) to show highest rated first
                self.ratedAlbums = loadedAlbums.sorted { $0.rating.personalScore > $1.rating.personalScore }
                self.ratedArtists = loadedArtists.sorted { $0.rating.personalScore > $1.rating.personalScore }
                self.ratingsLoaded = true
                print("✅ ProfileViewModel: Loaded \(loadedTracks.count) track ratings, \(loadedAlbums.count) album ratings, \(loadedArtists.count) artist ratings")
            }
        } catch {
            await MainActor.run {
                self.error = error as? APIError ?? .networkError(error)
                self.ratingsLoaded = true // Set to true even on error so UI can proceed
            }
            print("❌ ProfileViewModel: Failed to load ratings data: \(error)")
        }
    }
    
    /// Get current ratings based on selected type
    var currentRatings: [RatedItem] {
        switch selectedRatingType {
        case .track: return ratedTracks // Now supports track ratings with positional ranking
        case .album: return ratedAlbums
        case .artist: return ratedArtists
        }
    }
    
    /// Get track ratings organized by album for better display
    var trackRatingsByAlbum: [(albumName: String, tracks: [RatedItem])] {
        // Group tracks by album name
        let grouped = Dictionary(grouping: ratedTracks) { track in
            track.itemData.albumName ?? "Unknown Album"
        }
        
        // Sort albums by best average position of their tracks, then by album name
        return grouped.sorted { album1, album2 in
            let avgPosition1 = album1.value.map(\.rating.position).reduce(0, +) / album1.value.count
            let avgPosition2 = album2.value.map(\.rating.position).reduce(0, +) / album2.value.count
            
            if avgPosition1 != avgPosition2 {
                return avgPosition1 < avgPosition2 // Better average position first
            }
            return album1.key < album2.key // Then alphabetical
        }.map { (albumName: $0.key, tracks: $0.value.sorted { $0.rating.position < $1.rating.position }) }
    }
    
    /// Change rating type selection
    func changeRatingType(to type: RatingItemType) {
        selectedRatingType = type
    }
    
    func changeFavoriteType(to type: ContentType) {
        selectedFavoriteType = type
        // Load favorites for the selected type
        Task {
            guard let userId = authManager.user?.id else { return }
            await loadFavorites(userId: userId, type: type)
        }
    }
    
    private func loadFavorites(userId: String, type: ContentType) async {
        switch type {
        case .tracks:
            await profileService.fetchFavoriteTracks(userId: userId)
        case .albums:
            await profileService.fetchFavoriteAlbums(userId: userId)
        case .artists:
            await profileService.fetchFavoriteArtists(userId: userId)
        }
    }
    
    func changeTimeRange(_ range: TimeRange, userId: String? = nil) {
        selectedTimeRange = range
        // Time range filtering will be implemented when API supports it
        loadProfileData(userId: userId)
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case lastMonth = "Last Month"
    case last6Months = "Last 6 Months"
    case lastYear = "Last Year"
    case allTime = "All Time"
    
    var apiValue: String {
        switch self {
        case .lastMonth: return "short_term"
        case .last6Months: return "medium_term"
        case .lastYear: return "long_term"
        case .allTime: return "all_time"
        }
    }
}