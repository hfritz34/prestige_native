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
    @Published var isLoading = false
    @Published var error: String?
    
    private let friendsService = FriendsService()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
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
}