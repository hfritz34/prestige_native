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
    @Published var selectedType: ContentType = .tracks
    @Published var isSearching = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
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
                    subtitle: "\(artist.followers?.total ?? 0) followers"
                )
            } ?? []
        default:
            return []
        }
    }
    
    func loadCurrentFavorites() {
        Task {
            do {
                guard let userId = AuthManager.shared.user?.id else { return }
                
                let typeString = mapContentTypeToSearchType(selectedType)
                let favorites = try await APIClient.shared.getFavorites(userId: userId, type: typeString)
                
                await MainActor.run {
                    self.currentFavorites = favorites.compactMap { userTrack in
                        SpotifyItem(
                            id: userTrack.track.id,
                            name: userTrack.track.name,
                            type: "track",
                            imageUrl: userTrack.track.album.images.first?.url,
                            subtitle: userTrack.track.artists.first?.name
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.currentFavorites = []
                }
                print("Failed to load favorites: \(error)")
            }
        }
    }
    
    func toggleFavorite(_ item: SpotifyItem) {
        if let index = currentFavorites.firstIndex(where: { $0.id == item.id }) {
            currentFavorites.remove(at: index)
            removeFavoriteFromAPI(item)
        } else {
            currentFavorites.append(item)
            addFavoriteToAPI(item)
        }
    }
    
    func isFavorite(_ item: SpotifyItem) -> Bool {
        currentFavorites.contains(where: { $0.id == item.id })
    }
    
    private func addFavoriteToAPI(_ item: SpotifyItem) {
        Task {
            do {
                guard let userId = AuthManager.shared.user?.id else { return }
                let type = item.type == "track" ? "track" : item.type == "album" ? "album" : "artist"
                _ = try await apiClient.toggleFavorite(userId: userId, type: type, itemId: item.id)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add favorite: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
    
    private func removeFavoriteFromAPI(_ item: SpotifyItem) {
        Task {
            do {
                guard let userId = AuthManager.shared.user?.id else { return }
                let type = item.type == "track" ? "track" : item.type == "album" ? "album" : "artist"
                _ = try await apiClient.toggleFavorite(userId: userId, type: type, itemId: item.id)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
}