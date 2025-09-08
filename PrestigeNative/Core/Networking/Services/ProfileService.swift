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
    @Published var favoriteAlbums: [AlbumResponse] = []
    @Published var favoriteArtists: [ArtistResponse] = []
    @Published var userProfile: UserResponse?
    @Published var userStatistics: UserStatisticsResponse?
    
    @Published var isLoading = false
    @Published var error: APIError?
    
    // MARK: - Profile Data Methods
    
    /// Fetch user's top tracks with prestige levels
    func fetchTopTracks(userId: String, limit: Int = 60) async {
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
    func fetchTopAlbums(userId: String, limit: Int = 60) async {
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
    func fetchTopArtists(userId: String, limit: Int = 30) async {
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
            print("🔵 Fetching recently played for user: \(userId) with limit: \(limit)")
            let recent: [RecentlyPlayedResponse] = try await apiClient.get(
                "\(APIEndpoints.recentlyPlayed(userId: userId))?limit=\(limit)",
                responseType: [RecentlyPlayedResponse].self
            )
            print("✅ Successfully fetched \(recent.count) recently played tracks")
            await MainActor.run {
                self.recentlyPlayed = Array(recent.prefix(limit))
                self.isLoading = false
                self.error = nil
            }
        } catch let apiError as APIError {
            print("❌ Recently played API error: \(apiError)")
            await MainActor.run {
                // Only set error if we're not in a concurrent loading context
                if !self.isLoading {
                    self.error = apiError
                }
                self.isLoading = false
            }
        } catch {
            print("❌ Recently played network error: \(error)")
            await MainActor.run {
                // Only set error if we're not in a concurrent loading context
                if !self.isLoading {
                    self.error = .networkError(error)
                }
                self.isLoading = false
            }
        }
    }
    
    /// Fetch user's favorite tracks
    func fetchFavoriteTracks(userId: String, limit: Int = 10) async {
        await MainActor.run { isLoading = true }
        
        do {
            let userFavorites = try await apiClient.getFavorites(userId: userId, type: "track")
            let trackResponses = userFavorites.map { $0.track }
            
            await MainActor.run {
                self.favoriteTracks = Array(trackResponses.prefix(limit))
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
    
    func fetchFavoriteAlbums(userId: String, limit: Int = 10) async {
        await MainActor.run { isLoading = true }
        
        do {
            print("🔵 Fetching favorite albums for user: \(userId)")
            let userFavorites = try await apiClient.getAlbumFavorites(userId: userId)
            print("✅ Successfully fetched \(userFavorites.count) favorite albums")
            let albumResponses = userFavorites.map { $0.album }
            
            await MainActor.run {
                self.favoriteAlbums = Array(albumResponses.prefix(limit))
                self.isLoading = false
                self.error = nil
                print("📱 Updated favoriteAlbums with \(self.favoriteAlbums.count) albums")
            }
        } catch let apiError as APIError {
            print("❌ Favorite albums API error: \(apiError)")
            await MainActor.run {
                self.error = apiError
                self.isLoading = false
            }
        } catch {
            print("❌ Favorite albums network error: \(error)")
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
            }
        }
    }
    
    func fetchFavoriteArtists(userId: String, limit: Int = 10) async {
        await MainActor.run { isLoading = true }
        
        do {
            print("🔵 Fetching favorite artists for user: \(userId)")
            let userFavorites = try await apiClient.getArtistFavorites(userId: userId)
            print("✅ Successfully fetched \(userFavorites.count) favorite artists")
            let artistResponses = userFavorites.map { $0.artist }
            
            await MainActor.run {
                self.favoriteArtists = Array(artistResponses.prefix(limit))
                self.isLoading = false
                self.error = nil
                print("📱 Updated favoriteArtists with \(self.favoriteArtists.count) artists")
            }
        } catch let apiError as APIError {
            print("❌ Favorite artists API error: \(apiError)")
            await MainActor.run {
                self.error = apiError
                self.isLoading = false
            }
        } catch {
            print("❌ Favorite artists network error: \(error)")
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
    
    /// Fetch user statistics (friends, ratings, prestiges)
    func fetchUserStatistics(userId: String) async {
        await MainActor.run { isLoading = true }
        
        do {
            print("🔵 Fetching user statistics for user: \(userId)")
            let statistics: UserStatisticsResponse = try await apiClient.get(
                "/users/\(userId)/statistics",
                responseType: UserStatisticsResponse.self
            )
            print("✅ Successfully fetched user statistics: \(statistics.friendsCount) friends, \(statistics.ratingsCount) ratings, \(statistics.prestigesCount) prestiges")
            await MainActor.run {
                self.userStatistics = statistics
                self.isLoading = false
                self.error = nil
            }
        } catch let apiError as APIError {
            print("❌ User statistics API error: \(apiError)")
            await MainActor.run {
                // Only set error if we're not in a concurrent loading context
                if !self.isLoading {
                    self.error = apiError
                }
                self.isLoading = false
            }
        } catch {
            print("❌ User statistics network error: \(error)")
            await MainActor.run {
                // Only set error if we're not in a concurrent loading context
                if !self.isLoading {
                    self.error = .networkError(error)
                }
                self.isLoading = false
            }
        }
    }
    
    /// Fetch recently updated items from hourly batch processing
    func fetchRecentlyUpdated(userId: String) async -> RecentlyUpdatedResponse {
        do {
            // Get items updated in the last 24 hours for better results
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            let formatter = ISO8601DateFormatter()
            let sinceParam = formatter.string(from: oneDayAgo)

            let endpoint = APIEndpoints.recentlyUpdated(userId: userId, since: sinceParam)

            print("🔵 Fetching recently updated items for user: \(userId)")
            let response: RecentlyUpdatedResponse = try await apiClient.get(
                endpoint,
                responseType: RecentlyUpdatedResponse.self
            )

            print("✅ Successfully fetched recently updated items: \(response.tracks.count) tracks, \(response.albums.count) albums, \(response.artists.count) artists")

            await MainActor.run {
                self.error = nil
            }

            return response

        } catch let apiError as APIError {
            print("❌ Recently updated API error: \(apiError)")
            await MainActor.run {
                self.error = apiError
            }
            return RecentlyUpdatedResponse()

        } catch {
            print("❌ Recently updated network error: \(error)")
            await MainActor.run {
                self.error = .networkError(error)
            }
            return RecentlyUpdatedResponse()
        }
    }

    /// Load all profile data at once
    func loadAllProfileData(userId: String) async {
        // Clear any previous errors at start
        await MainActor.run {
            self.error = nil
            self.isLoading = true
        }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchTopTracks(userId: userId) }
            group.addTask { await self.fetchTopAlbums(userId: userId) }
            group.addTask { await self.fetchTopArtists(userId: userId) }
            group.addTask { await self.fetchRecentlyPlayed(userId: userId, limit: 30) }
            group.addTask { await self.fetchFavoriteTracks(userId: userId) }
            group.addTask { await self.fetchFavoriteAlbums(userId: userId) }
            group.addTask { await self.fetchFavoriteArtists(userId: userId) }
            group.addTask { await self.fetchUserProfile(userId: userId) }
            group.addTask { await self.fetchUserStatistics(userId: userId) }
        }
        
        // Mark loading as complete
        await MainActor.run {
            self.isLoading = false
        }
    }
}