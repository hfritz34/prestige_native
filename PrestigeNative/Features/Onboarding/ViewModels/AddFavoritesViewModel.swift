//
//  AddFavoritesViewModel.swift
//  ViewModel for Favorites Selection
//
//  Handles search and favorites management for onboarding.
//

import Foundation
import Combine

// MARK: - Spotify Item Model
struct SpotifyItem: Identifiable, Codable {
    let id: String
    let name: String
    let type: String // "track", "album", "artist"
    let imageUrl: String?
    let subtitle: String? // Artist name for tracks/albums
    
    enum CodingKeys: String, CodingKey {
        case id, name, type
        case imageUrl = "image_url"
        case subtitle
    }
}

class AddFavoritesViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [SpotifyItem] = []
    @Published var currentFavorites: [SpotifyItem] = []
    @Published var selectedType: ContentType = .albums
    @Published var isSearching = false
    @Published var isLoadingCategory = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var isSaving = false
    @Published var hasUnsavedChanges = false
    
    private var originalFavorites: [SpotifyItem] = []
    
    private var searchCancellable: AnyCancellable?
    private let apiClient = APIClient.shared
    
    init() {
        setupSearchDebounce()
        loadCurrentFavorites()
    }
    
    private func setupSearchDebounce() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard !query.isEmpty else {
                    self?.searchResults = []
                    return
                }
                Task {
                    await self?.performSearch(query: query)
                }
            }
    }
    
    private func performSearch(query: String) async {
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let searchType = mapContentTypeToSearchType(selectedType)
            let results = try await apiClient.searchSpotify(query: query, type: searchType)
            
            await MainActor.run {
                self.searchResults = mapSearchResultsToItems(results, type: searchType)
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.isSearching = false
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }
    
    private func mapContentTypeToSearchType(_ type: ContentType) -> String {
        switch type {
        case .tracks: return "track"
        case .albums: return "album"
        case .artists: return "artist"
        }
    }
    
    private func mapSearchResultsToItems(_ results: SpotifySearchResponse, type: String) -> [SpotifyItem] {
        switch type {
        case "track":
            return results.tracks?.items.map { track in
                SpotifyItem(
                    id: track.id,
                    name: track.name,
                    type: "track",
                    imageUrl: track.album?.images?.first?.url,
                    subtitle: track.artists?.first?.name
                )
            } ?? []
        case "album":
            return results.albums?.items.map { album in
                SpotifyItem(
                    id: album.id,
                    name: album.name,
                    type: "album",
                    imageUrl: album.images?.first?.url,
                    subtitle: album.artists?.first?.name
                )
            } ?? []
        case "artist":
            return results.artists?.items.map { artist in
                SpotifyItem(
                    id: artist.id,
                    name: artist.name,
                    type: "artist",
                    imageUrl: artist.images?.first?.url,
                    subtitle: "Artist"
                )
            } ?? []
        default:
            return []
        }
    }
    
    func loadCurrentFavorites() {
        Task {
            await MainActor.run {
                self.isLoadingCategory = true
            }
            
            do {
                guard let userId = AuthManager.shared.user?.id else { 
                    await MainActor.run {
                        self.isLoadingCategory = false
                    }
                    return 
                }
                
                let typeString = mapContentTypeToSearchType(selectedType)
                
                await MainActor.run {
                    self.currentFavorites = []
                }
                
                // The API endpoint returns different response types based on content type
                // For now, we'll use a generic approach and handle the response appropriately
                switch selectedType {
                case .tracks:
                    let trackFavorites = try await APIClient.shared.getFavorites(userId: userId, type: typeString)
                    await MainActor.run {
                        self.currentFavorites = trackFavorites.compactMap { userTrack in
                            SpotifyItem(
                                id: userTrack.track.id,
                                name: userTrack.track.name,
                                type: "track",
                                imageUrl: userTrack.track.album.images.first?.url,
                                subtitle: userTrack.track.artists.first?.name
                            )
                        }
                        self.originalFavorites = self.currentFavorites
                        self.hasUnsavedChanges = false
                        self.isLoadingCategory = false
                    }
                case .albums:
                    let albumFavorites = try await APIClient.shared.getAlbumFavorites(userId: userId)
                    await MainActor.run {
                        self.currentFavorites = albumFavorites.compactMap { userAlbum in
                            SpotifyItem(
                                id: userAlbum.album.id,
                                name: userAlbum.album.name,
                                type: "album",
                                imageUrl: userAlbum.album.images.first?.url,
                                subtitle: userAlbum.album.artists.first?.name
                            )
                        }
                        self.originalFavorites = self.currentFavorites
                        self.hasUnsavedChanges = false
                        self.isLoadingCategory = false
                    }
                case .artists:
                    let artistFavorites = try await APIClient.shared.getArtistFavorites(userId: userId)
                    await MainActor.run {
                        self.currentFavorites = artistFavorites.compactMap { userArtist in
                            SpotifyItem(
                                id: userArtist.artist.id,
                                name: userArtist.artist.name,
                                type: "artist",
                                imageUrl: userArtist.artist.images.first?.url,
                                subtitle: "Artist"
                            )
                        }
                        self.originalFavorites = self.currentFavorites
                        self.hasUnsavedChanges = false
                        self.isLoadingCategory = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.currentFavorites = []
                    self.originalFavorites = []
                    self.hasUnsavedChanges = false
                    self.isLoadingCategory = false
                }
                print("Failed to load favorites for \(selectedType): \(error)")
            }
        }
    }
    
    func toggleFavorite(_ item: SpotifyItem) {
        if let index = currentFavorites.firstIndex(where: { $0.id == item.id }) {
            currentFavorites.remove(at: index)
        } else {
            currentFavorites.append(item)
        }
        
        // Check if current state differs from original
        let currentIds = Set(currentFavorites.map { $0.id })
        let originalIds = Set(originalFavorites.map { $0.id })
        hasUnsavedChanges = currentIds != originalIds
    }
    
    func isFavorite(_ item: SpotifyItem) -> Bool {
        currentFavorites.contains(where: { $0.id == item.id })
    }
    
    func saveFavorites() async {
        await MainActor.run {
            isSaving = true
            errorMessage = ""
        }
        
        guard let userId = AuthManager.shared.user?.id else {
            await MainActor.run {
                isSaving = false
                errorMessage = "User not authenticated"
                showingError = true
            }
            return
        }
        
        // Calculate changes
        let originalIds = Set(originalFavorites.map { $0.id })
        let currentIds = Set(currentFavorites.map { $0.id })
        
        let itemsToAdd = currentFavorites.filter { !originalIds.contains($0.id) }
        let itemsToRemove = originalFavorites.filter { !currentIds.contains($0.id) }
        
        do {
            // Process removals
            for item in itemsToRemove {
                let type = item.type == "track" ? "track" : item.type == "album" ? "album" : "artist"
                _ = try await apiClient.toggleFavorite(userId: userId, type: type, itemId: item.id)
                print("✅ Removed favorite: \(item.name)")
            }
            
            // Process additions
            for item in itemsToAdd {
                let type = item.type == "track" ? "track" : item.type == "album" ? "album" : "artist"
                _ = try await apiClient.toggleFavorite(userId: userId, type: type, itemId: item.id)
                print("✅ Added favorite: \(item.name)")
            }
            
            await MainActor.run {
                // Update original state to match current state
                self.originalFavorites = self.currentFavorites
                self.hasUnsavedChanges = false
                self.isSaving = false
                print("✅ Successfully saved all favorites")
            }
            
            // Refresh the current favorites from the server to ensure consistency
            loadCurrentFavorites()
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.errorMessage = "Failed to save favorites: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }
}