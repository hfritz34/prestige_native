//
//  ProfileService.swift
//  Profile-related API calls and data management
//
//  This service handles all profile-related API operations,
//  equivalent to useProfile.tsx from the web application.
//

import Foundation
import Combine

class ProfileService: ObservableObject {
    private let apiClient = APIClient.shared
    
    @Published var topTracks: [UserTrackResponse] = []
    @Published var topAlbums: [UserAlbumResponse] = []
    @Published var topArtists: [UserArtistResponse] = []
    @Published var recentlyPlayed: [RecentlyPlayedResponse] = []
    @Published var favoriteTracks: [TrackResponse] = []
    @Published var userProfile: UserResponse?
    
    @Published var isLoading = false
    @Published var error: APIError?
    
    // MARK: - Profile Data Methods
    
    /// Fetch user's top tracks with prestige levels
    func fetchTopTracks(userId: String, limit: Int = 25) async {
        await MainActor.run { isLoading = true }
        
        do {
            let tracks = try await apiClient.getUserTracks(userId: userId)
            await MainActor.run {
                self.topTracks = Array(tracks.prefix(limit))
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
    
    /// Fetch user's top albums with prestige levels
    func fetchTopAlbums(userId: String, limit: Int = 25) async {
        await MainActor.run { isLoading = true }
        
        do {
            let albums = try await apiClient.getUserAlbums(userId: userId)
            await MainActor.run {
                self.topAlbums = Array(albums.prefix(limit))
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
    
    /// Fetch user's top artists with prestige levels
    func fetchTopArtists(userId: String, limit: Int = 25) async {
        await MainActor.run { isLoading = true }
        
        do {
            let artists = try await apiClient.getUserArtists(userId: userId)
            await MainActor.run {
                self.topArtists = Array(artists.prefix(limit))
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
    
    /// Fetch user's recently played tracks
    func fetchRecentlyPlayed(userId: String, limit: Int = 10) async {
        await MainActor.run { isLoading = true }
        
        do {
            let recent: [RecentlyPlayedResponse] = try await apiClient.get(
                APIEndpoints.recentlyPlayed(userId: userId),
                responseType: [RecentlyPlayedResponse].self
            )
            await MainActor.run {
                self.recentlyPlayed = Array(recent.prefix(limit))
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
    
    /// Fetch user's favorite tracks
    func fetchFavoriteTracks(userId: String, limit: Int = 10) async {
        await MainActor.run { isLoading = true }
        
        do {
            let favorites: [TrackResponse] = try await apiClient.get(
                APIEndpoints.favoriteTracks(userId: userId),
                responseType: [TrackResponse].self
            )
            await MainActor.run {
                self.favoriteTracks = Array(favorites.prefix(limit))
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
    
    /// Fetch user profile information
    func fetchUserProfile(userId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            let profile = try await apiClient.getUserProfile(userId: userId)
            await MainActor.run {
                self.userProfile = profile
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
    
    /// Update user nickname
    func updateNickname(_ nickname: String) async -> Bool {
        await MainActor.run { isLoading = true }
        
        do {
            let updatedProfile = try await apiClient.updateNickname(nickname)
            await MainActor.run {
                self.userProfile = updatedProfile
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
    
    /// Load all profile data at once
    func loadAllProfileData(userId: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchTopTracks(userId: userId) }
            group.addTask { await self.fetchTopAlbums(userId: userId) }
            group.addTask { await self.fetchTopArtists(userId: userId) }
            group.addTask { await self.fetchRecentlyPlayed(userId: userId) }
            group.addTask { await self.fetchFavoriteTracks(userId: userId) }
            group.addTask { await self.fetchUserProfile(userId: userId) }
        }
    }
}