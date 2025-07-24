//
//  HomeViewModel.swift
//  Home Screen ViewModel
//
//  Manages prestige data for home screen with type switching.
//  Integrates with ProfileService for data fetching.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var topTracks: [UserTrackResponse] = []
    @Published var topAlbums: [UserAlbumResponse] = []
    @Published var topArtists: [UserArtistResponse] = []
    @Published var selectedContentType: ContentType = .tracks
    @Published var selectedTimeRange: PrestigeTimeRange = .allTime
    @Published var isLoading = false
    @Published var error: APIError?
    
    private let profileService: ProfileService
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?

    init(profileService: ProfileService = ProfileService()) {
        self.profileService = profileService
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind to ProfileService published properties
        profileService.$topTracks
            .assign(to: \.topTracks, on: self)
            .store(in: &cancellables)
        
        profileService.$topAlbums
            .assign(to: \.topAlbums, on: self)
            .store(in: &cancellables)
        
        profileService.$topArtists
            .assign(to: \.topArtists, on: self)
            .store(in: &cancellables)
        
        profileService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        profileService.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        // Listen for content type changes and load appropriate data
        $selectedContentType
            .dropFirst() // Ignore initial value
            .sink { [weak self] type in
                guard let self = self, let userId = self.currentUserId else { return }
                Task {
                    await self.loadDataForType(type, userId: userId)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadHomeData(for userId: String) {
        self.currentUserId = userId
        Task {
            await loadDataForType(selectedContentType, userId: userId)
        }
    }
    
    private func loadDataForType(_ type: ContentType, userId: String) async {
        print("🔵 HomeViewModel: Loading \(type.displayName) for user: \(userId)")
        
        switch type {
        case .tracks:
            await profileService.fetchTopTracks(userId: userId, limit: 60)
        case .albums:
            await profileService.fetchTopAlbums(userId: userId, limit: 60)
        case .artists:
            await profileService.fetchTopArtists(userId: userId, limit: 60)
        }
    }

    func refreshData() {
        guard let userId = currentUserId else { return }
        Task {
            await loadDataForType(selectedContentType, userId: userId)
        }
    }
}

// MARK: - Supporting Types

enum ContentType: CaseIterable {
    case tracks
    case albums
    case artists
    
    var displayName: String {
        switch self {
        case .tracks: return "Tracks"
        case .albums: return "Albums"
        case .artists: return "Artists"
        }
    }
}

enum PrestigeTimeRange: CaseIterable {
    case allTime
    case recentlyPlayed
    case lastMonth
    
    var displayName: String {
        switch self {
        case .allTime: return "All Time"
        case .recentlyPlayed: return "Recently Played"
        case .lastMonth: return "Last Month"
        }
    }
}