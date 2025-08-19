//
//  FriendsService.swift
//  Enhanced Friends and Social Features Service
//
//  This service handles all friend-related API operations with Redis caching,
//  social discovery, and real-time features. Equivalent to useFriends.tsx
//  from the web application with mobile optimizations.
//

import Foundation
import Combine

class FriendsService: ObservableObject {
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    @Published var friends: [FriendResponse] = []
    @Published var searchResults: [UserResponse] = []
    @Published var isLoading = false
    @Published var error: APIError?
    @Published var socialDiscoveryResults: [String: [FriendResponse]] = [:] // itemId -> friends
    
    // MARK: - Friends Management
    
    /// Fetch user's friends list with caching
    func fetchFriends(userId: String? = nil, forceRefresh: Bool = false) async {
        let targetUserId = userId ?? authManager.user?.id
        guard let targetUserId = targetUserId else {
            await MainActor.run {
                self.error = .authenticationError
            }
            return
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            let friendsList = try await apiClient.getFriends(userId: targetUserId, forceRefresh: forceRefresh)
            await MainActor.run {
                self.friends = friendsList
                self.isLoading = false
                self.error = nil
                print("📦 Friends loaded: \(friendsList.count) friends (cached: \(!forceRefresh))")
            }
        } catch let apiError as APIError {
            await MainActor.run {
                self.error = apiError
                self.isLoading = false
                print("❌ Failed to fetch friends: \(apiError.localizedDescription)")
            }
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
                print("❌ Network error fetching friends: \(error.localizedDescription)")
            }
        }
    }
    
    /// Search for users to add as friends
    func searchUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            let results = try await apiClient.searchUsers(query: query)
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
    
    /// Add a new friend with optimistic updates
    func addFriend(friendId: String) async -> Bool {
        await MainActor.run { isLoading = true }
        
        do {
            let newFriend = try await apiClient.addFriend(friendId: friendId)
            await MainActor.run {
                self.friends.append(newFriend)
                // Remove from search results if present
                self.searchResults.removeAll { $0.id == friendId }
                self.isLoading = false
                self.error = nil
                print("✅ Friend added: \(newFriend.name) (\(newFriend.friendId))")
            }
            return true
        } catch let apiError as APIError {
            await MainActor.run {
                self.error = apiError
                self.isLoading = false
                print("❌ Failed to add friend: \(apiError.localizedDescription)")
            }
            return false
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
                print("❌ Network error adding friend: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    /// Remove a friend with optimistic updates
    func removeFriend(friendId: String) async -> Bool {
        // Store friend for potential rollback
        let removedFriend = friends.first { $0.friendId == friendId }
        
        // Optimistically remove from UI
        await MainActor.run {
            self.friends.removeAll { $0.friendId == friendId }
            self.isLoading = true
        }
        
        do {
            try await apiClient.removeFriend(friendId: friendId)
            await MainActor.run {
                self.isLoading = false
                self.error = nil
                print("✅ Friend removed: \(friendId)")
            }
            return true
        } catch let apiError as APIError {
            // Rollback on error
            await MainActor.run {
                if let friend = removedFriend {
                    self.friends.append(friend)
                }
                self.error = apiError
                self.isLoading = false
                print("❌ Failed to remove friend: \(apiError.localizedDescription)")
            }
            return false
        } catch {
            // Rollback on error
            await MainActor.run {
                if let friend = removedFriend {
                    self.friends.append(friend)
                }
                self.error = .networkError(error)
                self.isLoading = false
                print("❌ Network error removing friend: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    /// Clear search results
    func clearSearchResults() {
        searchResults = []
    }
    
    /// Check if user is already a friend
    func isFriend(userId: String) -> Bool {
        return friends.contains { $0.friendId == userId }
    }
    
    // MARK: - Social Discovery Features
    
    /// Find friends who listened to a specific track
    func findFriendsWithTrack(trackId: String) async -> [FriendResponse] {
        guard let userId = authManager.user?.id else { return [] }
        
        do {
            let friendsWithTrack = try await apiClient.getFriendsWithTrack(userId: userId, trackId: trackId)
            await MainActor.run {
                socialDiscoveryResults["track_\(trackId)"] = friendsWithTrack
            }
            return friendsWithTrack
        } catch {
            print("❌ Error finding friends with track: \(error)")
            return []
        }
    }
    
    /// Find friends who listened to a specific album
    func findFriendsWithAlbum(albumId: String) async -> [FriendResponse] {
        guard let userId = authManager.user?.id else { return [] }
        
        do {
            let friendsWithAlbum = try await apiClient.getFriendsWithAlbum(userId: userId, albumId: albumId)
            await MainActor.run {
                socialDiscoveryResults["album_\(albumId)"] = friendsWithAlbum
            }
            return friendsWithAlbum
        } catch {
            print("❌ Error finding friends with album: \(error)")
            return []
        }
    }
    
    /// Find friends who listened to a specific artist
    func findFriendsWithArtist(artistId: String) async -> [FriendResponse] {
        guard let userId = authManager.user?.id else { return [] }
        
        do {
            let friendsWithArtist = try await apiClient.getFriendsWithArtist(userId: userId, artistId: artistId)
            await MainActor.run {
                socialDiscoveryResults["artist_\(artistId)"] = friendsWithArtist
            }
            return friendsWithArtist
        } catch {
            print("❌ Error finding friends with artist: \(error)")
            return []
        }
    }
    
    /// Get cached social discovery results
    func getCachedSocialDiscovery(itemType: String, itemId: String) -> [FriendResponse]? {
        return socialDiscoveryResults["\(itemType)_\(itemId)"]
    }
    
    /// Clear social discovery cache
    func clearSocialDiscoveryCache() {
        socialDiscoveryResults.removeAll()
    }
    
    // MARK: - Friend Profile Details
    
    /// Get detailed friend profile
    func getFriendProfile(friendId: String, forceRefresh: Bool = false) async -> FriendResponse? {
        guard let userId = authManager.user?.id else { return nil }
        
        do {
            let friendProfile = try await apiClient.getFriendProfile(
                userId: userId,
                friendId: friendId,
                forceRefresh: forceRefresh
            )
            return friendProfile
        } catch {
            print("❌ Error fetching friend profile: \(error)")
            return nil
        }
    }
    
    /// Get friend's listening data for a specific item
    func getFriendListeningData(friendId: String, itemType: String, itemId: String) async -> FriendListeningData? {
        do {
            switch itemType {
            case "track":
                return try await apiClient.getFriendTrackTime(friendId: friendId, trackId: itemId)
            case "album":
                return try await apiClient.getFriendAlbumTime(friendId: friendId, albumId: itemId)
            case "artist":
                return try await apiClient.getFriendArtistTime(friendId: friendId, artistId: itemId)
            default:
                return nil
            }
        } catch {
            print("❌ Error fetching friend listening data: \(error)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    /// Force refresh friends data from server
    func refreshFriendsData() async {
        await fetchFriends(forceRefresh: true)
    }
    
    /// Clear all friends cache
    func clearFriendsCache() async {
        await ResponseCacheService.shared.invalidateWithRedis(category: .friends)
        await ResponseCacheService.shared.invalidateWithRedis(category: .friendProfiles)
        clearSocialDiscoveryCache()
    }
}