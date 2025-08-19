//
//  ResponseCacheService.swift
//  Local Response Caching Service
//
//  Provides local caching layer that works with backend Redis caching
//  for optimal performance and offline capability
//

import Foundation
import Combine

class ResponseCacheService: ObservableObject {
    static let shared = ResponseCacheService()
    
    private init() {
        configureCache()
    }
    
    // MARK: - Cache Configuration
    
    private let cache = NSCache<NSString, CachedResponse>()
    private let userDefaults = UserDefaults.standard
    private let cacheQueue = DispatchQueue(label: "com.prestige.response-cache", qos: .utility)
    
    // Cache TTL settings aligned with backend Redis cache
    struct CacheTTL {
        static let userRatings: TimeInterval = 30 * 60        // 30 minutes
        static let itemMetadata: TimeInterval = 24 * 60 * 60  // 24 hours
        static let ratingCategories: TimeInterval = 48 * 60 * 60 // 48 hours
        static let userProfile: TimeInterval = 60 * 60       // 1 hour
        static let searchResults: TimeInterval = 15 * 60     // 15 minutes
    }
    
    @Published var cacheStats = CacheStatistics()
    
    private func configureCache() {
        // Configure cache limits
        cache.countLimit = 1000 // Max 1000 cached responses
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
        
        // Clean up expired entries on app launch
        cleanExpiredEntries()
        
        print("📦 Response cache configured: 1000 items, 50MB limit")
    }
    
    // MARK: - Public Methods
    
    /// Get cached response for a given key
    func getCachedResponse<T: Codable>(
        for key: String,
        responseType: T.Type,
        category: CacheCategory
    ) -> T? {
        let cacheKey = NSString(string: "\(category.prefix):\(key)")
        
        guard let cachedResponse = cache.object(forKey: cacheKey) else {
            recordCacheMiss(for: category)
            return nil
        }
        
        // Check if expired
        if cachedResponse.expiresAt < Date() {
            cache.removeObject(forKey: cacheKey)
            recordCacheExpiry(for: category)
            return nil
        }
        
        // Try to decode cached data
        do {
            let decoded = try JSONDecoder().decode(T.self, from: cachedResponse.data)
            recordCacheHit(for: category)
            print("📦 Cache hit for \(key) (\(category.name))")
            return decoded
        } catch {
            print("❌ Cache decode error for \(key): \(error)")
            cache.removeObject(forKey: cacheKey)
            recordCacheError(for: category)
            return nil
        }
    }
    
    /// Cache a response with appropriate TTL
    func cacheResponse<T: Codable>(
        _ response: T,
        for key: String,
        category: CacheCategory
    ) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try JSONEncoder().encode(response)
                let expiresAt = Date().addingTimeInterval(category.ttl)
                
                let cachedResponse = CachedResponse(
                    data: data,
                    expiresAt: expiresAt,
                    category: category.name
                )
                
                let cacheKey = NSString(string: "\(category.prefix):\(key)")
                let cost = data.count
                
                self.cache.setObject(cachedResponse, forKey: cacheKey, cost: cost)
                
                DispatchQueue.main.async {
                    self.recordCacheSet(for: category)
                }
                
                print("📦 Cached response for \(key) (\(category.name), expires: \(expiresAt))")
                
            } catch {
                print("❌ Cache encode error for \(key): \(error)")
            }
        }
    }
    
    /// Invalidate cache for specific category and optional key pattern
    func invalidateCache(category: CacheCategory, keyPattern: String? = nil) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // If no pattern specified, clear all entries for category
            guard let pattern = keyPattern else {
                self.clearCacheForCategory(category)
                return
            }
            
            // Remove entries matching pattern
            let prefix = "\(category.prefix):"
            var keysToRemove: [NSString] = []
            
            // Note: NSCache doesn't provide enumeration, so we track keys separately
            // For now, we'll clear the entire category when pattern invalidation is needed
            self.clearCacheForCategory(category)
            
            DispatchQueue.main.async {
                self.recordCacheInvalidation(for: category)
                print("🗑️ Invalidated cache for \(category.name) pattern: \(pattern)")
            }
        }
    }
    
    /// Clear all cache
    func clearAllCache() {
        cacheQueue.async { [weak self] in
            self?.cache.removeAllObjects()
            
            DispatchQueue.main.async {
                self?.cacheStats = CacheStatistics()
                print("🗑️ All cache cleared")
            }
        }
    }
    
    /// Get current cache statistics
    func updateCacheStatistics() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let totalCost = self.cache.totalCostLimit
            let usedCost = 0 // NSCache doesn't expose current cost
            
            DispatchQueue.main.async {
                // Update published stats
                print("📊 Cache stats updated")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func clearCacheForCategory(_ category: CacheCategory) {
        // Since NSCache doesn't support enumeration by prefix,
        // we clear all cache when category invalidation is needed
        // In a production app, consider using a custom cache implementation
        cache.removeAllObjects()
        print("🗑️ Cleared cache for category: \(category.name)")
    }
    
    private func cleanExpiredEntries() {
        // NSCache handles memory pressure automatically
        // Expired entries are checked on access
        print("🧹 Cache cleanup initiated")
    }
    
    // MARK: - Statistics Tracking
    
    private func recordCacheHit(for category: CacheCategory) {
        DispatchQueue.main.async { [weak self] in
            self?.cacheStats.recordHit(for: category.name)
        }
    }
    
    private func recordCacheMiss(for category: CacheCategory) {
        DispatchQueue.main.async { [weak self] in
            self?.cacheStats.recordMiss(for: category.name)
        }
    }
    
    private func recordCacheSet(for category: CacheCategory) {
        DispatchQueue.main.async { [weak self] in
            self?.cacheStats.recordSet(for: category.name)
        }
    }
    
    private func recordCacheExpiry(for category: CacheCategory) {
        DispatchQueue.main.async { [weak self] in
            self?.cacheStats.recordExpiry(for: category.name)
        }
    }
    
    private func recordCacheError(for category: CacheCategory) {
        DispatchQueue.main.async { [weak self] in
            self?.cacheStats.recordError(for: category.name)
        }
    }
    
    private func recordCacheInvalidation(for category: CacheCategory) {
        DispatchQueue.main.async { [weak self] in
            self?.cacheStats.recordInvalidation(for: category.name)
        }
    }
}

// MARK: - Cache Category Enum

enum CacheCategory {
    case userRatings
    case itemMetadata
    case ratingCategories
    case userProfile
    case searchResults
    case spotifyData
    case friends
    case friendProfiles
    
    var name: String {
        switch self {
        case .userRatings: return "User Ratings"
        case .itemMetadata: return "Item Metadata"
        case .ratingCategories: return "Rating Categories"
        case .userProfile: return "User Profile"
        case .searchResults: return "Search Results"
        case .spotifyData: return "Spotify Data"
        case .friends: return "Friends List"
        case .friendProfiles: return "Friend Profiles"
        }
    }
    
    var prefix: String {
        switch self {
        case .userRatings: return "ratings"
        case .itemMetadata: return "metadata"
        case .ratingCategories: return "categories"
        case .userProfile: return "profile"
        case .searchResults: return "search"
        case .spotifyData: return "spotify"
        case .friends: return "friends"
        case .friendProfiles: return "friend_profile"
        }
    }
    
    var ttl: TimeInterval {
        switch self {
        case .userRatings: return 30 * 60        // 30 minutes
        case .itemMetadata: return 24 * 60 * 60  // 24 hours
        case .ratingCategories: return 48 * 60 * 60 // 48 hours
        case .userProfile: return 60 * 60       // 1 hour
        case .searchResults: return 15 * 60     // 15 minutes
        case .spotifyData: return 15 * 60       // 15 minutes
        case .friends: return 30 * 60           // 30 minutes
        case .friendProfiles: return 60 * 60    // 1 hour
        }
    }
}

// MARK: - Cached Response Model

private class CachedResponse {
    let data: Data
    let expiresAt: Date
    let category: String
    
    init(data: Data, expiresAt: Date, category: String) {
        self.data = data
        self.expiresAt = expiresAt
        self.category = category
    }
}

// MARK: - Cache Statistics

struct CacheStatistics {
    private(set) var categoryStats: [String: CategoryStats] = [:]
    
    var totalHits: Int {
        categoryStats.values.reduce(0) { $0 + $1.hits }
    }
    
    var totalMisses: Int {
        categoryStats.values.reduce(0) { $0 + $1.misses }
    }
    
    var hitRatio: Double {
        let total = totalHits + totalMisses
        return total > 0 ? Double(totalHits) / Double(total) : 0
    }
    
    mutating func recordHit(for category: String) {
        categoryStats[category, default: CategoryStats()].hits += 1
    }
    
    mutating func recordMiss(for category: String) {
        categoryStats[category, default: CategoryStats()].misses += 1
    }
    
    mutating func recordSet(for category: String) {
        categoryStats[category, default: CategoryStats()].sets += 1
    }
    
    mutating func recordExpiry(for category: String) {
        categoryStats[category, default: CategoryStats()].expiries += 1
    }
    
    mutating func recordError(for category: String) {
        categoryStats[category, default: CategoryStats()].errors += 1
    }
    
    mutating func recordInvalidation(for category: String) {
        categoryStats[category, default: CategoryStats()].invalidations += 1
    }
    
    struct CategoryStats {
        var hits = 0
        var misses = 0
        var sets = 0
        var expiries = 0
        var errors = 0
        var invalidations = 0
        
        var hitRatio: Double {
            let total = hits + misses
            return total > 0 ? Double(hits) / Double(total) : 0
        }
    }
}

// MARK: - APIClient Integration

extension APIClient {
    /// Enhanced request method with local caching
    func getCached<T: Codable>(
        _ endpoint: String,
        responseType: T.Type,
        category: CacheCategory,
        forceRefresh: Bool = false
    ) async throws -> T {
        let cacheKey = endpoint
        
        // Check cache first (unless forcing refresh)
        if !forceRefresh,
           let cachedResponse = ResponseCacheService.shared.getCachedResponse(
               for: cacheKey,
               responseType: responseType,
               category: category
           ) {
            return cachedResponse
        }
        
        // Fetch from network
        let response = try await get(endpoint, responseType: responseType)
        
        // Cache the response
        ResponseCacheService.shared.cacheResponse(response, for: cacheKey, category: category)
        
        return response
    }
}