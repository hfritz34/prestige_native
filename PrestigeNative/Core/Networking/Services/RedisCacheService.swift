//
//  RedisCacheService.swift
//  Redis Distributed Cache Service
//
//  Provides distributed caching with Azure Redis Cache
//  Works alongside ResponseCacheService for multi-layer caching
//

import Foundation
import Combine

// MARK: - Redis Cache Service

class RedisCacheService: ObservableObject {
    static let shared = RedisCacheService()
    
    private let session = URLSession.shared
    private var redisBaseURL: String?
    private var redisKey: String?
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    @Published var isConnected = false
    @Published var connectionError: String?
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration
    
    private func loadConfiguration() {
        // Load Redis configuration from environment or plist
        if let path = Bundle.main.path(forResource: "RedisConfig", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            redisBaseURL = dict["RedisURL"] as? String
            redisKey = dict["RedisKey"] as? String
        }
        
        // Fallback to environment variables
        if redisBaseURL == nil {
            redisBaseURL = ProcessInfo.processInfo.environment["REDIS_URL"]
        }
        if redisKey == nil {
            redisKey = ProcessInfo.processInfo.environment["REDIS_KEY"]
        }
        
        validateConnection()
    }
    
    func configure(url: String, key: String) {
        redisBaseURL = url
        redisKey = key
        validateConnection()
    }
    
    private func validateConnection() {
        guard redisBaseURL != nil && redisKey != nil else {
            isConnected = false
            connectionError = "Redis configuration missing"
            print("⚠️ Redis not configured - using local cache only")
            return
        }
        
        isConnected = true
        connectionError = nil
        print("✅ Redis configured: \(redisBaseURL ?? "")")
    }
    
    // MARK: - Cache Operations
    
    /// Get value from Redis cache
    func get<T: Codable>(_ key: String, type: T.Type) async -> T? {
        guard isConnected, let baseURL = redisBaseURL else {
            return nil
        }
        
        // For Azure Redis Cache, we'll use the REST API proxy endpoint
        // In production, consider using a proper Redis client library
        
        do {
            // Create a hash of the key for consistent caching
            let cacheKey = createCacheKey(key)
            
            // For now, we'll use a simple HTTP endpoint that proxies to Redis
            // This would be implemented on the backend
            let url = URL(string: "\(baseURL)/cache/\(cacheKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            if let redisKey = redisKey {
                request.setValue(redisKey, forHTTPHeaderField: "X-Redis-Key")
            }
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let decoded = try jsonDecoder.decode(RedisCacheResponse<T>.self, from: data)
            
            // Check if expired
            if let expiresAt = decoded.expiresAt, expiresAt < Date() {
                return nil
            }
            
            print("📦 Redis cache hit: \(key)")
            return decoded.value
            
        } catch {
            print("❌ Redis get error: \(error)")
            return nil
        }
    }
    
    /// Set value in Redis cache
    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval) async {
        guard isConnected, let baseURL = redisBaseURL else {
            return
        }
        
        do {
            let cacheKey = createCacheKey(key)
            let expiresAt = Date().addingTimeInterval(ttl)
            
            let cacheData = RedisCacheData(
                value: value,
                expiresAt: expiresAt,
                ttl: Int(ttl)
            )
            
            let url = URL(string: "\(baseURL)/cache/\(cacheKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let redisKey = redisKey {
                request.setValue(redisKey, forHTTPHeaderField: "X-Redis-Key")
            }
            
            request.httpBody = try jsonEncoder.encode(cacheData)
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("📦 Redis cache set: \(key) (TTL: \(Int(ttl))s)")
            }
            
        } catch {
            print("❌ Redis set error: \(error)")
        }
    }
    
    /// Delete value from Redis cache
    func delete(_ key: String) async {
        guard isConnected, let baseURL = redisBaseURL else {
            return
        }
        
        do {
            let cacheKey = createCacheKey(key)
            let url = URL(string: "\(baseURL)/cache/\(cacheKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            
            if let redisKey = redisKey {
                request.setValue(redisKey, forHTTPHeaderField: "X-Redis-Key")
            }
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("🗑️ Redis cache deleted: \(key)")
            }
            
        } catch {
            print("❌ Redis delete error: \(error)")
        }
    }
    
    /// Delete all keys matching pattern
    func deletePattern(_ pattern: String) async {
        guard isConnected, let baseURL = redisBaseURL else {
            return
        }
        
        do {
            let url = URL(string: "\(baseURL)/cache/pattern/\(pattern)")!
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            
            if let redisKey = redisKey {
                request.setValue(redisKey, forHTTPHeaderField: "X-Redis-Key")
            }
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("🗑️ Redis pattern deleted: \(pattern)")
            }
            
        } catch {
            print("❌ Redis pattern delete error: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createCacheKey(_ key: String) -> String {
        // Create a consistent cache key format
        return "prestige:ios:\(key)"
            .replacingOccurrences(of: "/", with: ":")
            .replacingOccurrences(of: " ", with: "_")
    }
}

// MARK: - Cache Response Models

struct RedisCacheResponse<T: Codable>: Codable {
    let value: T
    let expiresAt: Date?
    let metadata: CacheMetadata?
}

struct RedisCacheData<T: Codable>: Codable {
    let value: T
    let expiresAt: Date
    let ttl: Int
}

struct CacheMetadata: Codable {
    let createdAt: Date
    let hitCount: Int?
    let lastAccessed: Date?
}

// MARK: - Integration with ResponseCacheService

extension ResponseCacheService {
    /// Enhanced get with Redis fallback
    func getWithRedis<T: Codable>(
        for key: String,
        responseType: T.Type,
        category: CacheCategory
    ) async -> T? {
        // Check local cache first
        if let localValue = getCachedResponse(
            for: key,
            responseType: responseType,
            category: category
        ) {
            return localValue
        }
        
        // Check Redis cache
        if let redisValue = await RedisCacheService.shared.get(
            "\(category.prefix):\(key)",
            type: responseType
        ) {
            // Store in local cache for faster subsequent access
            cacheResponse(redisValue, for: key, category: category)
            return redisValue
        }
        
        return nil
    }
    
    /// Enhanced cache with Redis sync
    func cacheWithRedis<T: Codable>(
        _ response: T,
        for key: String,
        category: CacheCategory
    ) async {
        // Cache locally
        cacheResponse(response, for: key, category: category)
        
        // Cache in Redis
        await RedisCacheService.shared.set(
            "\(category.prefix):\(key)",
            value: response,
            ttl: category.ttl
        )
    }
    
    /// Invalidate both local and Redis cache
    func invalidateWithRedis(category: CacheCategory, keyPattern: String? = nil) async {
        // Invalidate local cache
        invalidateCache(category: category, keyPattern: keyPattern)
        
        // Invalidate Redis cache
        if let pattern = keyPattern {
            await RedisCacheService.shared.deletePattern("\(category.prefix):\(pattern)*")
        } else {
            await RedisCacheService.shared.deletePattern("\(category.prefix):*")
        }
    }
}

// MARK: - Configuration Helper

struct RedisConfiguration {
    static func createConfigFile(url: String, key: String) {
        let config = [
            "RedisURL": url,
            "RedisKey": key
        ] as NSDictionary
        
        if let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first {
            let configPath = documentsPath.appendingPathComponent("RedisConfig.plist")
            config.write(to: configPath, atomically: true)
            print("✅ Redis config saved to: \(configPath)")
        }
    }
}