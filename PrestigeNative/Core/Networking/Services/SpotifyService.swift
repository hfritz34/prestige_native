//
//  SpotifyService.swift
//  Spotify API integration service
//
//  This service handles Spotify-specific API calls like search,
//  equivalent to useSpotify.ts from the web application.
//

import Foundation
import Combine

class SpotifyService: ObservableObject {
    private let apiClient = APIClient.shared
    
    @Published var searchResults: SearchResults?
    @Published var isLoading = false
    @Published var error: APIError?
    
    // MARK: - Spotify Search
    
    /// Search Spotify catalog for tracks, albums, and artists
    func search(query: String, types: [SearchType] = [.track, .album, .artist]) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = nil
            }
            return
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            let searchParams = [
                "q": query,
                "type": types.map { $0.rawValue }.joined(separator: ","),
                "limit": "20"
            ]
            
            guard let url = APIEndpoints.fullURL(
                for: APIEndpoints.spotifySearch,
                parameters: searchParams
            ) else {
                throw APIError.invalidURL
            }
            
            let results: SearchResults = try await apiClient.get(
                url.absoluteString.replacingOccurrences(of: APIEndpoints.baseURL + "/", with: ""),
                responseType: SearchResults.self
            )
            
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
                self.error = nil
            }
        } catch let apiError as APIError {
            await MainActor.run {
                self.error = apiError
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
            }
        }
    }
    
    /// Clear search results
    func clearSearchResults() {
        searchResults = nil
    }
}

// MARK: - Supporting Types

enum SearchType: String, CaseIterable {
    case track = "track"
    case album = "album"
    case artist = "artist"
    
    var displayName: String {
        switch self {
        case .track: return "Tracks"
        case .album: return "Albums"
        case .artist: return "Artists"
        }
    }
}