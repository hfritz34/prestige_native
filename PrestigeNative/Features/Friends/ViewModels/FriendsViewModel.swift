//
//  FriendsViewModel.swift
//  Friends management view model
//

import Foundation
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [FriendResponse] = []
    @Published var searchResults: [UserResponse] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Friends Management
    
    func loadFriends() async {
        guard let userId = authManager.user?.id else { return }
        
        isLoading = true
        error = nil
        
        do {
            let friendsList = try await apiClient.getFriends(userId: userId)
            self.friends = friendsList
        } catch {
            self.error = error.localizedDescription
            print("Error loading friends: \(error)")
        }
        
        isLoading = false
    }
    
    func searchUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        do {
            let results = try await apiClient.searchUsers(query: query)
            // Filter out current user and existing friends
            self.searchResults = results.filter { user in
                user.id != authManager.user?.id &&
                !friends.contains { $0.friendId == user.id }
            }
        } catch {
            self.error = error.localizedDescription
            print("Error searching users: \(error)")
        }
    }
    
    func addFriend(friendId: String) async {
        do {
            let newFriend = try await apiClient.addFriend(friendId: friendId)
            friends.append(newFriend)
            // Remove from search results
            searchResults.removeAll { $0.id == friendId }
        } catch {
            self.error = error.localizedDescription
            print("Error adding friend: \(error)")
        }
    }
    
    func removeFriend(friendId: String) async {
        do {
            try await apiClient.removeFriend(friendId: friendId)
            friends.removeAll { $0.friendId == friendId }
        } catch {
            self.error = error.localizedDescription
            print("Error removing friend: \(error)")
        }
    }
    
    func clearSearchResults() {
        searchResults = []
    }
    
    func isFriend(userId: String) -> Bool {
        return friends.contains { $0.friendId == userId }
    }
    
    // MARK: - Friend Comparison
    
    func getFriendsWithItem(itemType: String, itemId: String) async -> [FriendResponse] {
        guard let userId = authManager.user?.id else { return [] }
        
        do {
            // This will call the endpoint to get friends who have listened to this item
            let endpoint: String
            switch itemType {
            case "track":
                endpoint = "friendships/\(userId)/friends/listened-to-track/\(itemId)"
            case "album":
                endpoint = "friendships/\(userId)/friends/listened-to-album/\(itemId)"
            case "artist":
                endpoint = "friendships/\(userId)/friends/listened-to-artist/\(itemId)"
            default:
                return []
            }
            
            return try await apiClient.get(endpoint, responseType: [FriendResponse].self)
        } catch {
            print("Error getting friends with item: \(error)")
            return []
        }
    }
}