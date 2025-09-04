//
//  FriendProfileViewModel.swift
//  Enhanced Friend Profile View Model with Caching
//

import Foundation
import Combine

@MainActor
class FriendProfileViewModel: ObservableObject {
    @Published var friend: FriendResponse?
    @Published var topTracks: [UserTrackResponse] = []
    @Published var topAlbums: [UserAlbumResponse] = []
    @Published var topArtists: [UserArtistResponse] = []
    @Published var favoriteTracks: [UserTrackResponse] = []
    @Published var favoriteAlbums: [UserAlbumResponse] = []
    @Published var favoriteArtists: [UserArtistResponse] = []
    @Published var recentTracks: [TrackResponse] = []
    @Published var currentRatings: [RatedItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isInFriendContext: Bool = false
    
    private let friendsService = FriendsService()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    private let friendContext = FriendContextService()
    
    var totalTracks: Int {
        return topTracks.count
    }
    
    var totalAlbums: Int {
        return topAlbums.count
    }
    
    var totalArtists: Int {
        return topArtists.count
    }
    
    func loadFriendProfile(friendId: String, forceRefresh: Bool = false) async {
        isLoading = true
        error = nil
        
        // Load detailed friend profile with caching
        if let friendProfile = await friendsService.getFriendProfile(
            friendId: friendId,
            forceRefresh: forceRefresh
        ) {
            self.friend = friendProfile
            
            // Extract rich profile data if available
            self.topTracks = friendProfile.topTracks ?? []
            self.topAlbums = friendProfile.topAlbums ?? []
            self.topArtists = friendProfile.topArtists ?? []
            self.favoriteTracks = friendProfile.favoriteTracks ?? []
            self.favoriteAlbums = friendProfile.favoriteAlbums ?? []
            self.favoriteArtists = friendProfile.favoriteArtists ?? []
            
            print("✅ Friend profile loaded: \(friendProfile.name) with \(topTracks.count) top tracks")
        } else {
            self.error = "Failed to load friend profile"
            print("❌ Failed to load friend profile for: \(friendId)")
        }
        
        isLoading = false
    }
    
    /// Force refresh friend profile data
    func refreshProfile(friendId: String) async {
        await loadFriendProfile(friendId: friendId, forceRefresh: true)
    }
    
    /// Get friend's listening data for comparison
    func getFriendListeningData(itemType: String, itemId: String) async -> FriendListeningData? {
        guard let friendId = friend?.friendId else { return nil }
        
        return await friendsService.getFriendListeningData(
            friendId: friendId,
            itemType: itemType,
            itemId: itemId
        )
    }
    
    // MARK: - Friend Context Navigation Methods
    // These methods create PrestigeDisplayItems with friend's data for UI reuse
    
    /// Navigate to friend's track detail view with their context
    func navigateToFriendTrack(trackId: String, trackName: String, imageUrl: String, artistName: String?) async -> PrestigeDisplayItem? {
        guard let friendId = friend?.friendId else { return nil }
        
        do {
            let trackDetails = try await friendContext.getFriendTrackDetails(
                friendId: friendId, 
                trackId: trackId
            )
            isInFriendContext = true
            
            // Transform to PrestigeDisplayItem for UI reuse
            return friendContext.transformToPrestigeDisplayItem(
                trackDetails,
                albumName: nil,
                artistName: artistName
            )
        } catch {
            self.error = "Failed to load friend's track details: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Navigate to friend's album detail view with their context  
    func navigateToFriendAlbum(albumId: String, albumName: String, imageUrl: String, artistName: String?) async -> PrestigeDisplayItem? {
        guard let friendId = friend?.friendId else { return nil }
        
        do {
            let albumDetails = try await friendContext.getFriendAlbumDetails(
                friendId: friendId, 
                albumId: albumId
            )
            isInFriendContext = true
            
            // Transform to PrestigeDisplayItem for UI reuse
            return friendContext.transformToPrestigeDisplayItem(
                albumDetails,
                albumName: albumName,
                artistName: artistName
            )
        } catch {
            self.error = "Failed to load friend's album details: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Navigate to friend's artist detail view with their context
    func navigateToFriendArtist(artistId: String, artistName: String, imageUrl: String) async -> PrestigeDisplayItem? {
        guard let friendId = friend?.friendId else { return nil }
        
        do {
            let artistDetails = try await friendContext.getFriendArtistDetails(
                friendId: friendId, 
                artistId: artistId
            )
            isInFriendContext = true
            
            // Transform to PrestigeDisplayItem for UI reuse
            return friendContext.transformToPrestigeDisplayItem(
                artistDetails,
                albumName: nil,
                artistName: artistName
            )
        } catch {
            self.error = "Failed to load friend's artist details: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Get friend's track rankings for an album (for use in friend's album detail view)
    func getFriendAlbumTracks(albumId: String) async -> [FriendTrackRankingResponse] {
        guard let friendId = friend?.friendId else { return [] }
        
        do {
            return try await friendContext.getFriendAlbumTrackRankings(
                friendId: friendId, 
                albumId: albumId
            )
        } catch {
            self.error = "Failed to load friend's album tracks: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Get friend's album ratings for an artist (for use in friend's artist detail view)
    func getFriendArtistAlbums(artistId: String) async -> [FriendAlbumRatingResponse] {
        guard let friendId = friend?.friendId else { return [] }
        
        do {
            return try await friendContext.getFriendArtistAlbumRankings(
                friendId: friendId, 
                artistId: artistId
            )
        } catch {
            self.error = "Failed to load friend's artist albums: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Get enhanced comparison data between user and friend
    func getEnhancedComparison(itemId: String, itemType: String) async -> EnhancedItemComparisonResponse? {
        guard let friendId = friend?.friendId else { return nil }
        
        do {
            switch itemType.lowercased() {
            case "track":
                return try await friendContext.getEnhancedTrackComparison(trackId: itemId, friendId: friendId)
            case "album":
                return try await friendContext.getEnhancedAlbumComparison(albumId: itemId, friendId: friendId)
            case "artist":
                return try await friendContext.getEnhancedArtistComparison(artistId: itemId, friendId: friendId)
            default:
                return nil
            }
        } catch {
            self.error = "Failed to load comparison data: \(error.localizedDescription)"
            return nil
        }
    }
}