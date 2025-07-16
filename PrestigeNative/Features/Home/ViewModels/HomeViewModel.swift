//
//  HomeViewModel.swift
//  Home Screen ViewModel
//
//  Manages home screen data including recently played tracks and top tracks.
//  Integrates with ProfileService for data fetching.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var recentlyPlayed: [RecentlyPlayedResponse] = []
    @Published var topTracks: [UserTrackResponse] = []
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
        profileService.$recentlyPlayed
            .assign(to: \.recentlyPlayed, on: self)
            .store(in: &cancellables)
        
        profileService.$topTracks
            .assign(to: \.topTracks, on: self)
            .store(in: &cancellables)
        
        profileService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        profileService.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    func loadHomeData() {
        // Using mock user ID for now - will be replaced with actual user ID from AuthManager
        let userId = "current_user_id"
        
        Task {
            await profileService.fetchRecentlyPlayed(userId: userId, limit: 10)
            await profileService.fetchTopTracks(userId: userId, limit: 25)
        }
    }
    
    func refreshData() {
        loadHomeData()
    }
}