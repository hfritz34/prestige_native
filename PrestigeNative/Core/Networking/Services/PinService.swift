//
//  PinService.swift
//  Pin Service for Managing Pinned Items
//
//  Handles pinning and unpinning of tracks, albums, and artists
//

import Foundation

@MainActor
class PinService: ObservableObject {
    static let shared = PinService()
    
    @Published var pinnedTracks: Set<String> = []
    @Published var pinnedAlbums: Set<String> = []
    @Published var pinnedArtists: Set<String> = []
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - Pin Toggle Methods
    
    func togglePin(itemId: String, itemType: ContentType) async -> Bool {
        do {
            let isPinned = isItemPinned(itemId: itemId, itemType: itemType)
            
            if isPinned {
                try await unpinItem(itemId: itemId, itemType: itemType)
                removeFromPinnedSet(itemId: itemId, itemType: itemType)
                return false
            } else {
                try await pinItem(itemId: itemId, itemType: itemType)
                addToPinnedSet(itemId: itemId, itemType: itemType)
                return true
            }
        } catch {
            print("Error toggling pin for \(itemType) \(itemId): \(error)")
            return isItemPinned(itemId: itemId, itemType: itemType)
        }
    }
    
    func isItemPinned(itemId: String, itemType: ContentType) -> Bool {
        switch itemType {
        case .tracks:
            return pinnedTracks.contains(itemId)
        case .albums:
            return pinnedAlbums.contains(itemId)
        case .artists:
            return pinnedArtists.contains(itemId)
        }
    }
    
    // MARK: - API Methods
    
    private func pinItem(itemId: String, itemType: ContentType) async throws {
        guard let userId = AuthManager.shared.user?.id else {
            throw PinServiceError.noUserId
        }
        
        // Use the new dedicated pin methods from APIClient
        switch itemType {
        case .tracks:
            try await apiClient.togglePinTrack(userId: userId, trackId: itemId)
        case .albums:
            try await apiClient.togglePinAlbum(userId: userId, albumId: itemId)
        case .artists:
            try await apiClient.togglePinArtist(userId: userId, artistId: itemId)
        }
    }
    
    private func unpinItem(itemId: String, itemType: ContentType) async throws {
        guard let userId = AuthManager.shared.user?.id else {
            throw PinServiceError.noUserId
        }
        
        // Use the same toggle endpoint - it handles both pin and unpin
        switch itemType {
        case .tracks:
            try await apiClient.togglePinTrack(userId: userId, trackId: itemId)
        case .albums:
            try await apiClient.togglePinAlbum(userId: userId, albumId: itemId)
        case .artists:
            try await apiClient.togglePinArtist(userId: userId, artistId: itemId)
        }
    }
    
    func loadPinnedItems() async {
        do {
            guard let userId = AuthManager.shared.user?.id else {
                print("No user ID available for loading pinned items")
                return
            }
            
            let pinnedItemsResponse = try await apiClient.getPinnedItems(userId: userId)
            
            pinnedTracks = Set(pinnedItemsResponse.tracks.map { $0.track.id })
            pinnedAlbums = Set(pinnedItemsResponse.albums.map { $0.album.id })
            pinnedArtists = Set(pinnedItemsResponse.artists.map { $0.artist.id })
            
        } catch {
            print("Error loading pinned items: \(error)")
        }
    }
    
    // MARK: - Local State Management
    
    private func addToPinnedSet(itemId: String, itemType: ContentType) {
        switch itemType {
        case .tracks:
            pinnedTracks.insert(itemId)
        case .albums:
            pinnedAlbums.insert(itemId)
        case .artists:
            pinnedArtists.insert(itemId)
        }
    }
    
    private func removeFromPinnedSet(itemId: String, itemType: ContentType) {
        switch itemType {
        case .tracks:
            pinnedTracks.remove(itemId)
        case .albums:
            pinnedAlbums.remove(itemId)
        case .artists:
            pinnedArtists.remove(itemId)
        }
    }
}

// MARK: - API Models

struct EmptyRequest: Codable {}

struct EmptyResponse: Codable {}

enum PinServiceError: Error {
    case noUserId
}


// MARK: - ContentType Extension

extension ContentType {
    var pinApiValue: String {
        switch self {
        case .tracks: return "track"
        case .albums: return "album"
        case .artists: return "artist"
        }
    }
}