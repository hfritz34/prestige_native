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
    @Published var recentlyPlayed: [TrackResponse] = []
    @Published var isLoading = false
    @Published var error: APIError?
    @Published var selectedTimeRange: TimeRange = .allTime
    
    private let profileService: ProfileService
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for stats
    var totalListeningTime: Int {
        // Sum of top tracks listening time (in minutes)
        topTracks.reduce(0) { $0 + $1.totalTimeMinutes }
    }
    
    var totalUniqueArtists: Int {
        Set(topTracks.map { $0.track.artistName }).count
    }
    
    var topPrestigeLevel: PrestigeLevel {
        // Get highest prestige level from top tracks
        topTracks.map { $0.prestigeLevel }.max { $0.order < $1.order } ?? .none
    }
    
    init(profileService: ProfileService = ProfileService(), authManager: AuthManager = AuthManager()) {
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
        
        profileService.$recentlyPlayed
            .assign(to: \.recentlyPlayed, on: self)
            .store(in: &cancellables)
        
        profileService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        profileService.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    func loadProfileData(userId: String? = nil) {
        // Require a valid user ID - no fallback
        guard let actualUserId = userId, !actualUserId.isEmpty else {
            print("❌ ProfileViewModel: No valid user ID provided, cannot load data")
            return
        }
        
        print("🔵 ProfileViewModel: Loading data for user: \(actualUserId)")
        
        Task {
            await profileService.loadAllProfileData(userId: actualUserId)
        }
    }
    
    func refreshData() {
        loadProfileData()
    }
    
    func changeTimeRange(_ range: TimeRange, userId: String? = nil) {
        selectedTimeRange = range
        // TODO: Implement time range filtering when API supports it
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