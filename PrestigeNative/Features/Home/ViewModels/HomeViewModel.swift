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
    @Published var isLoading = false
    @Published var error: APIError?
    
    private let profileService: ProfileService
    private var cancellables = Set<AnyCancellable>()
    
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
            .sink { [weak self] type in
                Task {
                    await self?.loadDataForType(type, userId: nil)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadHomeData() {
        Task {
            await loadDataForType(selectedContentType)
        }
    }
    
    private func loadDataForType(_ type: ContentType, userId: String? = nil) async {
        // Require a valid user ID - no fallback
        guard let actualUserId = userId, !actualUserId.isEmpty else {
            print("❌ HomeViewModel: No valid user ID provided, cannot load data")
            return
        }
        
        print("🔵 HomeViewModel: Loading \(type.displayName) for user: \(actualUserId)")
        
        switch type {
        case .tracks:
            await profileService.fetchTopTracks(userId: actualUserId, limit: 25)
        case .albums:
            await profileService.fetchTopAlbums(userId: actualUserId, limit: 25)
        case .artists:
            await profileService.fetchTopArtists(userId: actualUserId, limit: 25)
        }
    }
    
    func loadDataForUser(_ userId: String) {
        Task {
            await loadDataForType(selectedContentType, userId: userId)
        }
    }
    
    func refreshData() {
        loadHomeData()
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