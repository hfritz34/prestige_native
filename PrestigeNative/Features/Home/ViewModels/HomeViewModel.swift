//
//  HomeViewModel.swift
//  Home Screen ViewModel
//
//  Manages prestige data for home screen with unified loading
//  and content type switching.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var topTracks: [UserTrackResponse] = []
    @Published var topAlbums: [UserAlbumResponse] = []
    @Published var topArtists: [UserArtistResponse] = []
    @Published var selectedContentType: ContentType = .albums
    @Published var selectedTimeRange: PrestigeTimeRange = .allTime
    @Published var loadingState: LoadingState = .idle
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = ""
    @Published var error: APIError?
    
    private let loadingCoordinator: LoadingCoordinator
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    @Published var hasInitiallyLoaded = false

    init(loadingCoordinator: LoadingCoordinator = LoadingCoordinator()) {
        self.loadingCoordinator = loadingCoordinator
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind to LoadingCoordinator state
        loadingCoordinator.$loadingState
            .assign(to: \.loadingState, on: self)
            .store(in: &cancellables)
        
        loadingCoordinator.$loadingProgress
            .assign(to: \.loadingProgress, on: self)
            .store(in: &cancellables)
        
        loadingCoordinator.$loadingMessage
            .assign(to: \.loadingMessage, on: self)
            .store(in: &cancellables)
        
        // Update data when content bundle changes
        loadingCoordinator.$contentBundle
            .compactMap { $0 }
            .sink { [weak self] bundle in
                self?.updateContent(from: bundle)
            }
            .store(in: &cancellables)
        
        // Listen for time range changes
        $selectedTimeRange
            .dropFirst() // Ignore initial value
            .sink { [weak self] (timeRange: PrestigeTimeRange) in
                guard let self = self, let userId = self.currentUserId else { return }
                Task {
                    // Set loading state immediately when time range changes
                    await MainActor.run {
                        self.loadingState = .loading(progress: 0.1)
                    }
                    await self.loadAllData(for: userId, forceRefresh: false)
                }
            }
            .store(in: &cancellables)
    }
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var hasError: Bool {
        loadingState.hasError
    }
    
    func loadHomeData(for userId: String) {
        self.currentUserId = userId
        Task {
            await loadAllData(for: userId, forceRefresh: !hasInitiallyLoaded)
            hasInitiallyLoaded = true
        }
    }
    
    func loadHomeDataAsync(for userId: String) async {
        self.currentUserId = userId
        await loadAllData(for: userId, forceRefresh: !hasInitiallyLoaded)
        await MainActor.run {
            hasInitiallyLoaded = true
        }
    }
    
    private func loadAllData(for userId: String, forceRefresh: Bool) async {
        // Load all content types at once
        await loadingCoordinator.loadAllContent(
            for: userId,
            timeRange: selectedTimeRange,
            forceRefresh: forceRefresh
        )
        
        // Preload images for current content type
        await loadingCoordinator.preloadImages(for: selectedContentType, limit: 50)
        
        // Also preload images for other content types in the background
        Task {
            for contentType in ContentType.allCases where contentType != selectedContentType {
                await loadingCoordinator.preloadImages(for: contentType, limit: 30)
            }
        }
    }
    
    private func updateContent(from bundle: PrestigeContentBundle) {
        self.topTracks = bundle.tracks
        self.topAlbums = bundle.albums
        self.topArtists = bundle.artists
        
        // Extract error if loading failed
        if case .error(let apiError) = loadingState {
            self.error = apiError
        } else {
            self.error = nil
        }
    }

    func refreshData() {
        guard let userId = currentUserId else { return }
        Task {
            await loadAllData(for: userId, forceRefresh: true)
        }
    }
    
    func retryLoading() {
        guard let userId = currentUserId else { return }
        Task {
            await loadAllData(for: userId, forceRefresh: true)
        }
    }
}

// MARK: - Supporting Types

enum ContentType: CaseIterable {
    case albums
    case tracks
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
    case recentlyUpdated
    case pinned
    
    var displayName: String {
        switch self {
        case .allTime: return "All Time"
        case .recentlyUpdated: return "Recent"
        case .pinned: return "Pinned Items"
        }
    }
}