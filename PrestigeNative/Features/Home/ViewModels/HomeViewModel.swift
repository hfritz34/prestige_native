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
                    await self?.loadDataForType(type)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadHomeData() {
        Task {
            await loadDataForType(selectedContentType)
        }
    }
    
    private func loadDataForType(_ type: ContentType) async {
        // Using mock user ID for now - will be replaced with actual user ID from AuthManager
        let userId = "current_user_id"
        
        switch type {
        case .tracks:
            await profileService.fetchTopTracks(userId: userId, limit: 25)
        case .albums:
            await profileService.fetchTopAlbums(userId: userId, limit: 25)
        case .artists:
            await profileService.fetchTopArtists(userId: userId, limit: 25)
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