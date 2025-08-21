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
        let endpoint = "pin"
        let body = PinRequest(
            itemId: itemId,
            itemType: itemType.pinApiValue
        )
        
        let _: EmptyResponse = try await apiClient.request(
            endpoint: endpoint,
            method: .POST,
            body: body
        )
    }
    
    private func unpinItem(itemId: String, itemType: ContentType) async throws {
        let endpoint = "pin"
        let body = UnpinRequest(
            itemId: itemId,
            itemType: itemType.pinApiValue
        )
        
        let _: EmptyResponse = try await apiClient.request(
            endpoint: endpoint,
            method: .DELETE,
            body: body
        )
    }
    
    func loadPinnedItems() async {
        do {
            // Load pinned tracks
            let pinnedTracksResponse: PinnedItemsResponse = try await apiClient.request(
                endpoint: "pin/tracks",
                method: .GET
            )
            pinnedTracks = Set(pinnedTracksResponse.items.map { $0.itemId })
            
            // Load pinned albums
            let pinnedAlbumsResponse: PinnedItemsResponse = try await apiClient.request(
                endpoint: "pin/albums",
                method: .GET
            )
            pinnedAlbums = Set(pinnedAlbumsResponse.items.map { $0.itemId })
            
            // Load pinned artists
            let pinnedArtistsResponse: PinnedItemsResponse = try await apiClient.request(
                endpoint: "pin/artists",
                method: .GET
            )
            pinnedArtists = Set(pinnedArtistsResponse.items.map { $0.itemId })
            
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

struct PinRequest: Codable {
    let itemId: String
    let itemType: String
}

struct UnpinRequest: Codable {
    let itemId: String
    let itemType: String
}

struct EmptyResponse: Codable {}

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