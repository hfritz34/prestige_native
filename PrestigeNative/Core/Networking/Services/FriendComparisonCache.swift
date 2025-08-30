//
//  FriendComparisonCache.swift
//  Friend Comparison Data Cache Service
//
//  iOS equivalent of React Query patterns from web app, optimized for friend
//  time queries and comparison data with NSCache and efficient batching
//

import Foundation
import Combine

/// Cached friend data with expiration
class CachedFriendData {
    let data: Any
    let timestamp: Date
    let cacheExpiry: TimeInterval = 600 // 10 minutes

    init(data: Any, timestamp: Date = Date()) {
        self.data = data
        self.timestamp = timestamp
    }

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > cacheExpiry
    }
}

/// Friend comparison cache service for iOS
@MainActor
class FriendComparisonCache: ObservableObject {
    static let shared = FriendComparisonCache()
    
    private let cache = NSCache<NSString, CachedFriendData>()
    private let apiClient = APIClient.shared
    
    @Published var friendTimes: [String: [String: Double]] = [:] // itemType -> [friendId_itemId: time]
    @Published var friendsWhoListened: [String: [FriendResponse]] = [:] // itemType_itemId -> friends
    @Published var isLoading: [String: Bool] = [:] // Track loading states for different queries
    
    private init() {
        // Configure NSCache
        cache.countLimit = 1000 // Maximum 1000 cached items
        cache.totalCostLimit = 1024 * 1024 * 10 // 10MB limit
    }
    
    // MARK: - Friend Time Queries
    
    /// Get friend's listening time for a specific item (with caching)
    func getFriendItemTime(friendId: String, itemType: String, itemId: String) async -> Double {
        let cacheKey = "\(friendId)_\(itemType)_\(itemId)"
        
        // Check cache first
        if let cached = cache.object(forKey: NSString(string: cacheKey)),
           !cached.isExpired,
           let time = cached.data as? Double {
            return time
        }
        
        // Fetch from API
        do {
            var time: Double = 0
            
            switch itemType {
            case "track":
                let data = try await apiClient.getFriendTrackTime(friendId: friendId, trackId: itemId)
                time = Double(data.totalTime)
            case "album":
                let data = try await apiClient.getFriendAlbumTime(friendId: friendId, albumId: itemId)
                time = Double(data.totalTime)
            case "artist":
                let data = try await apiClient.getFriendArtistTime(friendId: friendId, artistId: itemId)
                time = Double(data.totalTime)
            default:
                return 0
            }
            
            // Cache the result
            let cachedData = CachedFriendData(data: time)
            cache.setObject(cachedData, forKey: NSString(string: cacheKey))
            
            // Update published state
            if friendTimes[itemType] == nil {
                friendTimes[itemType] = [:]
            }
            friendTimes[itemType]?[cacheKey] = time
            
            return time
        } catch {
            print("❌ FriendComparisonCache: Error fetching friend time - \(error)")
            return 0
        }
    }
    
    /// Get cached friend time without API call
    func getCachedFriendTime(friendId: String, itemType: String, itemId: String) -> Double? {
        let cacheKey = "\(friendId)_\(itemType)_\(itemId)"
        
        if let cached = cache.object(forKey: NSString(string: cacheKey)),
           !cached.isExpired,
           let time = cached.data as? Double {
            return time
        }
        
        return nil
    }
    
    /// Cache friend time manually (for batch operations)
    func cacheFriendTime(friendId: String, itemType: String, itemId: String, time: Double) {
        let cacheKey = "\(friendId)_\(itemType)_\(itemId)"
        let cachedData = CachedFriendData(data: time)
        cache.setObject(cachedData, forKey: NSString(string: cacheKey))
        
        // Update published state
        if friendTimes[itemType] == nil {
            friendTimes[itemType] = [:]
        }
        friendTimes[itemType]?[cacheKey] = time
    }
    
    // MARK: - Batch Loading for Performance
    
    /// Load friend times for multiple friends and a single item (optimized for item detail views)
    func loadFriendTimesForItem(itemType: String, itemId: String, friendIds: [String]) async {
        let loadingKey = "\(itemType)_\(itemId)_batch"
        isLoading[loadingKey] = true
        
        // Use TaskGroup to load friend times concurrently but with limits (max 5 concurrent)
        await withTaskGroup(of: (String, Double).self, body: { group in
            for friendId in friendIds.prefix(5) { // Limit to 5 concurrent requests
                group.addTask {
                    let time = await self.getFriendItemTime(friendId: friendId, itemType: itemType, itemId: itemId)
                    return (friendId, time)
                }
            }
            
            // Handle remaining friends in batches if more than 5
            if friendIds.count > 5 {
                let remainingFriends = Array(friendIds.dropFirst(5))
                let batches = remainingFriends.chunked(into: 5)
                for batch in batches {
                    for friendId in batch {
                        group.addTask {
                            let time = await self.getFriendItemTime(friendId: friendId, itemType: itemType, itemId: itemId)
                            return (friendId, time)
                        }
                    }
                }
            }
            
            // Collect results
            for await (friendId, time) in group {
                cacheFriendTime(friendId: friendId, itemType: itemType, itemId: itemId, time: time)
            }
        })
        
        isLoading[loadingKey] = false
        print("✅ FriendComparisonCache: Batch loaded times for \(friendIds.count) friends on \(itemType) \(itemId)")
    }
    
    // MARK: - Social Discovery with Caching
    
    /// Get friends who listened to a specific item (with caching)
    func getFriendsWhoListenedTo(itemType: String, itemId: String, userId: String) async -> [FriendResponse] {
        let cacheKey = "\(itemType)_\(itemId)"
        
        // Check cache first
        if let cachedFriends = friendsWhoListened[cacheKey] {
            return cachedFriends
        }
        
        // Check if already loading
        if isLoading[cacheKey] == true {
            // Wait a bit and return cached result if available
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            return friendsWhoListened[cacheKey] ?? []
        }
        
        isLoading[cacheKey] = true
        
        do {
            var friends: [FriendResponse] = []
            
            switch itemType {
            case "track":
                friends = try await apiClient.getFriendsWithTrack(userId: userId, trackId: itemId)
            case "album":
                friends = try await apiClient.getFriendsWithAlbum(userId: userId, albumId: itemId)
            case "artist":
                friends = try await apiClient.getFriendsWithArtist(userId: userId, artistId: itemId)
            default:
                friends = []
            }
            
            // Cache the result
            friendsWhoListened[cacheKey] = friends
            isLoading[cacheKey] = false
            
            print("✅ FriendComparisonCache: Found \(friends.count) friends for \(itemType) \(itemId)")
            return friends
            
        } catch {
            print("❌ FriendComparisonCache: Error fetching friends who listened - \(error)")
            isLoading[cacheKey] = false
            return []
        }
    }
    
    /// Get cached friends who listened (no API call)
    func getCachedFriendsWhoListened(itemType: String, itemId: String) -> [FriendResponse]? {
        let cacheKey = "\(itemType)_\(itemId)"
        return friendsWhoListened[cacheKey]
    }
    
    // MARK: - Cache Management
    
    /// Clear all cache
    func clearCache() {
        cache.removeAllObjects()
        friendTimes.removeAll()
        friendsWhoListened.removeAll()
        isLoading.removeAll()
        print("🗑️ FriendComparisonCache: All cache cleared")
    }
    
    /// Clear cache for specific item
    func clearCacheForItem(itemType: String, itemId: String) {
        let cacheKey = "\(itemType)_\(itemId)"
        friendsWhoListened.removeValue(forKey: cacheKey)
        
        // Clear friend times for this item
        if var itemTimes = friendTimes[itemType] {
            let keysToRemove = itemTimes.keys.filter { $0.contains(itemId) }
            for key in keysToRemove {
                itemTimes.removeValue(forKey: key)
                cache.removeObject(forKey: NSString(string: key))
            }
            friendTimes[itemType] = itemTimes
        }
        
        print("🗑️ FriendComparisonCache: Cache cleared for \(itemType) \(itemId)")
    }
    
    /// Clear expired items from cache
    func clearExpiredCache() {
        // NSCache handles some of this automatically, but we can clean our published properties
        for (itemType, times) in friendTimes {
            var updatedTimes = times
            for (key, _) in times {
                if let cached = cache.object(forKey: NSString(string: key)), cached.isExpired {
                    updatedTimes.removeValue(forKey: key)
                    cache.removeObject(forKey: NSString(string: key))
                }
            }
            friendTimes[itemType] = updatedTimes
        }
        
        print("🧹 FriendComparisonCache: Expired items cleared")
    }
    
    // MARK: - Debugging Helpers
    
    /// Get cache statistics
    func getCacheStats() -> (totalItems: Int, friendTimesCount: Int, friendsWhoListenedCount: Int) {
        let friendTimesCount = friendTimes.values.reduce(0) { $0 + $1.count }
        let friendsWhoListenedCount = friendsWhoListened.count
        
        return (
            totalItems: friendTimesCount + friendsWhoListenedCount,
            friendTimesCount: friendTimesCount,
            friendsWhoListenedCount: friendsWhoListenedCount
        )
    }
}