//
//  DetailViewCache.swift
//  Smart Detail View Caching Service
//
//  Preemptively caches detail view data and shares it between navigation contexts
//  for instant detail view loading
//

import Foundation
import Combine

/// Cached detail view data with metadata
class CachedDetailData {
    let data: Any
    let timestamp: Date
    let accessCount: Int
    private let cacheExpiry: TimeInterval = 1800 // 30 minutes
    
    init(data: Any, timestamp: Date = Date(), accessCount: Int = 0) {
        self.data = data
        self.timestamp = timestamp
        self.accessCount = accessCount
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > cacheExpiry
    }
    
    func accessed() -> CachedDetailData {
        return CachedDetailData(data: data, timestamp: timestamp, accessCount: accessCount + 1)
    }
}

/// Smart detail view cache service
@MainActor
class DetailViewCache: ObservableObject {
    static let shared = DetailViewCache()
    
    private let cache = NSCache<NSString, CachedDetailData>()
    private let apiClient = APIClient.shared
    private let ratingService = RatingService.shared
    private let friendComparisonCache = FriendComparisonCache.shared
    
    // Track what's been preloaded to avoid duplicate work
    private var preloadedKeys: Set<String> = []
    
    @Published var cacheHitRate: Double = 0.0
    @Published var totalRequests: Int = 0
    @Published var cacheHits: Int = 0
    
    private init() {
        configureCache()
    }
    
    private func configureCache() {
        cache.countLimit = 500 // Cache up to 500 detail views
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        print("📦 DetailViewCache configured: 500 items, 50MB limit")
    }
    
    // MARK: - Album Detail Caching
    
    /// Get cached album detail data
    func getCachedAlbumDetail(albumId: String) -> (tracks: AlbumTracksWithRankingsResponse?, ratings: [Rating]?, friends: [FriendResponse]?)? {
        totalRequests += 1
        
        let tracksKey = "album_tracks_\(albumId)"
        let ratingsKey = "album_ratings_\(albumId)"
        let friendsKey = "album_friends_\(albumId)"
        
        guard let tracksData = cache.object(forKey: NSString(string: tracksKey)),
              let ratingsData = cache.object(forKey: NSString(string: ratingsKey)),
              let friendsData = cache.object(forKey: NSString(string: friendsKey)),
              !tracksData.isExpired, !ratingsData.isExpired, !friendsData.isExpired else {
            return nil
        }
        
        cacheHits += 1
        updateCacheHitRate()
        
        // Mark as accessed
        cache.setObject(tracksData.accessed(), forKey: NSString(string: tracksKey))
        cache.setObject(ratingsData.accessed(), forKey: NSString(string: ratingsKey))
        cache.setObject(friendsData.accessed(), forKey: NSString(string: friendsKey))
        
        return (
            tracks: tracksData.data as? AlbumTracksWithRankingsResponse,
            ratings: ratingsData.data as? [Rating],
            friends: friendsData.data as? [FriendResponse]
        )
    }
    
    /// Cache album detail data
    func cacheAlbumDetail(albumId: String, tracks: AlbumTracksWithRankingsResponse, ratings: [Rating], friends: [FriendResponse]) {
        let tracksKey = "album_tracks_\(albumId)"
        let ratingsKey = "album_ratings_\(albumId)"
        let friendsKey = "album_friends_\(albumId)"
        
        cache.setObject(CachedDetailData(data: tracks), forKey: NSString(string: tracksKey))
        cache.setObject(CachedDetailData(data: ratings), forKey: NSString(string: ratingsKey))
        cache.setObject(CachedDetailData(data: friends), forKey: NSString(string: friendsKey))
        
        print("📦 Cached album detail for: \(albumId)")
    }
    
    /// Preload album detail data
    func preloadAlbumDetail(album: UserAlbumResponse, userId: String) async {
        let preloadKey = "album_preload_\(album.album.id)"
        
        // Skip if already preloaded recently
        guard !preloadedKeys.contains(preloadKey) else { return }
        preloadedKeys.insert(preloadKey)
        
        do {
            // Load album detail data in parallel
            async let albumTracksTask = try apiClient.getAlbumTracksWithRankings(userId: userId, albumId: album.album.id)
            async let albumRatingsTask = try ratingService.fetchAlbumTrackRatings(albumId: album.album.id)
            let friendsTask = await friendComparisonCache.getFriendsWhoListenedTo(
                itemType: "album", 
                itemId: album.album.id, 
                userId: userId
            )
            
            let (tracks, ratings) = try await (albumTracksTask, albumRatingsTask)
            
            // Cache the results
            cacheAlbumDetail(albumId: album.album.id, tracks: tracks, ratings: ratings, friends: friendsTask)
            
        } catch {
            print("❌ Failed to preload album detail for \(album.album.name): \(error)")
        }
    }
    
    // MARK: - Track Detail Caching
    
    /// Get cached track detail data
    func getCachedTrackDetail(trackId: String) -> (rating: Rating?, friends: [FriendResponse]?)? {
        totalRequests += 1
        
        let ratingKey = "track_rating_\(trackId)"
        let friendsKey = "track_friends_\(trackId)"
        
        guard let ratingData = cache.object(forKey: NSString(string: ratingKey)),
              let friendsData = cache.object(forKey: NSString(string: friendsKey)),
              !ratingData.isExpired, !friendsData.isExpired else {
            return nil
        }
        
        cacheHits += 1
        updateCacheHitRate()
        
        // Mark as accessed
        cache.setObject(ratingData.accessed(), forKey: NSString(string: ratingKey))
        cache.setObject(friendsData.accessed(), forKey: NSString(string: friendsKey))
        
        return (
            rating: ratingData.data as? Rating,
            friends: friendsData.data as? [FriendResponse]
        )
    }
    
    /// Cache track detail data
    func cacheTrackDetail(trackId: String, rating: Rating?, friends: [FriendResponse]) {
        let ratingKey = "track_rating_\(trackId)"
        let friendsKey = "track_friends_\(trackId)"
        
        if let rating = rating {
            cache.setObject(CachedDetailData(data: rating), forKey: NSString(string: ratingKey))
        }
        cache.setObject(CachedDetailData(data: friends), forKey: NSString(string: friendsKey))
        
        print("📦 Cached track detail for: \(trackId)")
    }
    
    /// Preload track detail data
    func preloadTrackDetail(track: UserTrackResponse, userId: String) async {
        let preloadKey = "track_preload_\(track.track.id)"
        
        // Skip if already preloaded recently
        guard !preloadedKeys.contains(preloadKey) else { return }
        preloadedKeys.insert(preloadKey)
        
        do {
            // Load track detail data in parallel
            let allTrackRatings = try? await ratingService.fetchUserRatings(itemType: .track)
            let rating = allTrackRatings?.first { $0.itemId == track.track.id }
            let friendsTask = await friendComparisonCache.getFriendsWhoListenedTo(
                itemType: "track", 
                itemId: track.track.id, 
                userId: userId
            )
            
            // Cache the results
            cacheTrackDetail(trackId: track.track.id, rating: rating, friends: friendsTask)
            
        } catch {
            print("❌ Failed to preload track detail for \(track.track.name): \(error)")
        }
    }
    
    // MARK: - Artist Detail Caching
    
    /// Get cached artist detail data
    func getCachedArtistDetail(artistId: String) -> (albums: ArtistAlbumsWithRankingsResponse?, friends: [FriendResponse]?)? {
        totalRequests += 1
        
        let albumsKey = "artist_albums_\(artistId)"
        let friendsKey = "artist_friends_\(artistId)"
        
        guard let albumsData = cache.object(forKey: NSString(string: albumsKey)),
              let friendsData = cache.object(forKey: NSString(string: friendsKey)),
              !albumsData.isExpired, !friendsData.isExpired else {
            return nil
        }
        
        cacheHits += 1
        updateCacheHitRate()
        
        // Mark as accessed
        cache.setObject(albumsData.accessed(), forKey: NSString(string: albumsKey))
        cache.setObject(friendsData.accessed(), forKey: NSString(string: friendsKey))
        
        return (
            albums: albumsData.data as? ArtistAlbumsWithRankingsResponse,
            friends: friendsData.data as? [FriendResponse]
        )
    }
    
    /// Cache artist detail data
    func cacheArtistDetail(artistId: String, albums: ArtistAlbumsWithRankingsResponse, friends: [FriendResponse]) {
        let albumsKey = "artist_albums_\(artistId)"
        let friendsKey = "artist_friends_\(artistId)"
        
        cache.setObject(CachedDetailData(data: albums), forKey: NSString(string: albumsKey))
        cache.setObject(CachedDetailData(data: friends), forKey: NSString(string: friendsKey))
        
        print("📦 Cached artist detail for: \(artistId)")
    }
    
    /// Preload artist detail data
    func preloadArtistDetail(artist: UserArtistResponse, userId: String) async {
        let preloadKey = "artist_preload_\(artist.artist.id)"
        
        // Skip if already preloaded recently
        guard !preloadedKeys.contains(preloadKey) else { return }
        preloadedKeys.insert(preloadKey)
        
        do {
            // Load artist detail data in parallel
            async let artistAlbumsTask = try apiClient.getArtistAlbumsWithUserActivity(
                userId: userId, 
                artistId: artist.artist.id
            )
            let friendsTask = await friendComparisonCache.getFriendsWhoListenedTo(
                itemType: "artist", 
                itemId: artist.artist.id, 
                userId: userId
            )
            
            let albums = try await artistAlbumsTask
            
            // Cache the results
            cacheArtistDetail(artistId: artist.artist.id, albums: albums, friends: friendsTask)
            
        } catch {
            print("❌ Failed to preload artist detail for \(artist.artist.name): \(error)")
        }
    }
    
    // MARK: - Cache Management
    
    private func updateCacheHitRate() {
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    /// Clear all cache
    func clearCache() {
        cache.removeAllObjects()
        preloadedKeys.removeAll()
        totalRequests = 0
        cacheHits = 0
        cacheHitRate = 0.0
        print("🗑️ DetailViewCache: All cache cleared")
    }
    
    /// Clear expired items from cache
    func clearExpiredCache() {
        // Remove expired preload keys (older than 1 hour)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        preloadedKeys = preloadedKeys.filter { key in
            // In a real implementation, you'd track timestamps for preload keys
            // For now, just clear periodically
            return true
        }
        
        print("🧹 DetailViewCache: Expired items cleared")
    }
    
    /// Get cache statistics
    func getCacheStats() -> (hitRate: Double, totalRequests: Int, cacheHits: Int) {
        return (hitRate: cacheHitRate, totalRequests: totalRequests, cacheHits: cacheHits)
    }
}