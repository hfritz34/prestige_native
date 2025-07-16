//
//  FriendsService.swift
//  Friends and social features API calls
//
//  This service handles all friend-related API operations,
//  equivalent to useFriends.tsx from the web application.
//

import Foundation
import Combine

class FriendsService: ObservableObject {
    private let apiClient = APIClient.shared
    
    @Published var friends: [FriendResponse] = []
    @Published var searchResults: [UserResponse] = []
    @Published var isLoading = false
    @Published var error: APIError?
    
    // MARK: - Friends Management
    
    /// Fetch user's friends list
    func fetchFriends(userId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            let friendsList = try await apiClient.getFriends(userId: userId)
            await MainActor.run {
                self.friends = friendsList
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
    
    /// Add a new friend
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
            }
            return true
        } catch let apiError as APIError {
            await MainActor.run {
                self.error = apiError
                self.isLoading = false
            }
            return false
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
            }
            return false
        }
    }
    
    /// Remove a friend
    func removeFriend(friendId: String) async -> Bool {
        await MainActor.run { isLoading = true }
        
        do {
            try await apiClient.removeFriend(friendId: friendId)
            await MainActor.run {
                self.friends.removeAll { $0.friendId == friendId }
                self.isLoading = false
                self.error = nil
            }
            return true
        } catch let apiError as APIError {
            await MainActor.run {
                self.error = apiError
                self.isLoading = false
            }
            return false
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
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
}