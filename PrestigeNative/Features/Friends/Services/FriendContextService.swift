//
//  FriendContextService.swift
//  Service for handling friend-context data and navigation
//

import Foundation

class FriendContextService: ObservableObject {
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    // MARK: - Friend Context Item Details
    
    /// Get friend's detailed track information with their ratings
    func getFriendTrackDetails(friendId: String, trackId: String) async throws -> FriendItemDetailsResponse {
        guard let userId = authManager.user?.id else {
            throw APIError.authenticationError
        }
        
        return try await apiClient.getFriendTrackDetails(userId: userId, friendId: friendId, trackId: trackId)
    }
    
    /// Get friend's detailed album information with their ratings
    func getFriendAlbumDetails(friendId: String, albumId: String) async throws -> FriendItemDetailsResponse {
        guard let userId = authManager.user?.id else {
            throw APIError.authenticationError
        }
        
        return try await apiClient.getFriendAlbumDetails(userId: userId, friendId: friendId, albumId: albumId)
    }
    
    /// Get friend's detailed artist information with their ratings
    func getFriendArtistDetails(friendId: String, artistId: String) async throws -> FriendItemDetailsResponse {
        guard let userId = authManager.user?.id else {
            throw APIError.authenticationError
        }
        
        return try await apiClient.getFriendArtistDetails(userId: userId, friendId: friendId, artistId: artistId)
    }
    
    // MARK: - Friend Rankings
    
    /// Get friend's track rankings within a specific album
    func getFriendAlbumTrackRankings(friendId: String, albumId: String) async throws -> [FriendTrackRankingResponse] {
        guard let userId = authManager.user?.id else {
            throw APIError.authenticationError
        }
        
        return try await apiClient.getFriendAlbumTrackRankings(userId: userId, friendId: friendId, albumId: albumId)
    }
    
    /// Get friend's album ratings within a specific artist
    func getFriendArtistAlbumRankings(friendId: String, artistId: String) async throws -> [FriendAlbumRatingResponse] {
        guard let userId = authManager.user?.id else {
            throw APIError.authenticationError
        }
        
        return try await apiClient.getFriendArtistAlbumRankings(userId: userId, friendId: friendId, artistId: artistId)
    }
    
    // MARK: - Enhanced Comparisons
    
    /// Get enhanced comparison data between user and friend for a track
    func getEnhancedTrackComparison(trackId: String, friendId: String) async throws -> EnhancedItemComparisonResponse {
        guard let userId = authManager.user?.id else {
            throw APIError.authenticationError
        }
        
        return try await apiClient.getEnhancedTrackComparison(userId: userId, trackId: trackId, friendId: friendId)
    }
    
    /// Get enhanced comparison data between user and friend for an album
    func getEnhancedAlbumComparison(albumId: String, friendId: String) async throws -> EnhancedItemComparisonResponse {
        guard let userId = authManager.user?.id else {
            throw APIError.authenticationError
        }
        
        return try await apiClient.getEnhancedAlbumComparison(userId: userId, albumId: albumId, friendId: friendId)
    }
    
    /// Get enhanced comparison data between user and friend for an artist
    func getEnhancedArtistComparison(artistId: String, friendId: String) async throws -> EnhancedItemComparisonResponse {
        guard let userId = authManager.user?.id else {
            throw APIError.authenticationError
        }
        
        return try await apiClient.getEnhancedArtistComparison(userId: userId, artistId: artistId, friendId: friendId)
    }
    
    // MARK: - Data Transformation Methods
    // Critical: Transform friend API responses into PrestigeDisplayItem format for UI reuse
    
    /// Transform FriendItemDetailsResponse to PrestigeDisplayItem
    /// This is key to reusing existing UI components with friend's data
    func transformToPrestigeDisplayItem(
        _ friendDetails: FriendItemDetailsResponse,
        albumName: String? = nil,
        artistName: String? = nil
    ) -> PrestigeDisplayItem {
        // Determine content type
        let contentType: ContentType
        switch friendDetails.itemType.lowercased() {
        case "track": contentType = .tracks
        case "album": contentType = .albums
        case "artist": contentType = .artists
        default: contentType = .tracks
        }
        
        // Parse prestige level from string
        let prestigeLevel = PrestigeLevel(rawValue: friendDetails.friendPrestigeTier) ?? .none
        
        // Convert listening time from seconds to milliseconds for consistency
        let totalTimeMilliseconds = (friendDetails.friendListeningTime ?? 0) * 1000
        
        // Create subtitle based on item type
        let subtitle: String
        switch contentType {
        case .tracks:
            subtitle = artistName ?? "Unknown Artist"
        case .albums:
            subtitle = artistName ?? "Unknown Artist"
        case .artists:
            subtitle = "Artist"
        }
        
        return PrestigeDisplayItem(
            name: friendDetails.itemName,
            subtitle: subtitle,
            imageUrl: friendDetails.itemImageUrl,
            totalTimeMilliseconds: totalTimeMilliseconds,
            prestigeLevel: prestigeLevel,
            spotifyId: friendDetails.itemId,
            contentType: contentType,
            albumPosition: friendDetails.friendRankWithinAlbum,
            rating: friendDetails.friendRatingScore,
            isPinned: friendDetails.isPinned,
            albumId: nil, // Will be populated if available
            albumName: albumName
        )
    }
    
    /// Transform FriendTrackRankingResponse to PrestigeDisplayItem
    func transformTrackRankingToPrestigeDisplayItem(
        _ trackRanking: FriendTrackRankingResponse,
        albumName: String? = nil
    ) -> PrestigeDisplayItem {
        let prestigeLevel = PrestigeLevel(rawValue: trackRanking.friendPrestigeTier) ?? .none
        let totalTimeMilliseconds = (trackRanking.friendListeningTime ?? 0) * 1000
        
        return PrestigeDisplayItem(
            name: trackRanking.trackName,
            subtitle: albumName ?? "Unknown Album",
            imageUrl: trackRanking.trackImageUrl,
            totalTimeMilliseconds: totalTimeMilliseconds,
            prestigeLevel: prestigeLevel,
            spotifyId: trackRanking.trackId,
            contentType: .tracks,
            albumPosition: trackRanking.friendRankWithinAlbum,
            rating: trackRanking.friendRatingScore,
            isPinned: false,
            albumId: nil,
            albumName: albumName
        )
    }
    
    /// Transform FriendAlbumRatingResponse to PrestigeDisplayItem
    func transformAlbumRatingToPrestigeDisplayItem(
        _ albumRating: FriendAlbumRatingResponse,
        artistName: String? = nil
    ) -> PrestigeDisplayItem {
        let prestigeLevel = PrestigeLevel(rawValue: albumRating.friendPrestigeTier) ?? .none
        let totalTimeMilliseconds = (albumRating.friendListeningTime ?? 0) * 1000
        
        return PrestigeDisplayItem(
            name: albumRating.albumName,
            subtitle: artistName ?? "Unknown Artist",
            imageUrl: albumRating.albumImageUrl,
            totalTimeMilliseconds: totalTimeMilliseconds,
            prestigeLevel: prestigeLevel,
            spotifyId: albumRating.albumId,
            contentType: .albums,
            albumPosition: albumRating.friendPosition,
            rating: albumRating.friendRatingScore,
            isPinned: albumRating.isPinned,
            albumId: albumRating.albumId,
            albumName: albumRating.albumName
        )
    }
}

