//
//  RateLimitService.swift
//  API Rate Limiting and Request Throttling
//
//  Implements client-side rate limiting to respect backend limits
//  and prevent 429 responses before they happen
//

import Foundation

class RateLimitService: ObservableObject {
    static let shared = RateLimitService()
    
    private init() {}
    
    // Rate limit windows and counts
    private struct RateLimit {
        let maxRequests: Int
        let windowDuration: TimeInterval
        var requestTimes: [Date] = []
        
        mutating func canMakeRequest() -> Bool {
            let now = Date()
            let windowStart = now.addingTimeInterval(-windowDuration)
            
            // Remove old requests outside the window
            requestTimes = requestTimes.filter { $0 > windowStart }
            
            return requestTimes.count < maxRequests
        }
        
        mutating func recordRequest() {
            requestTimes.append(Date())
        }
        
        func timeUntilNextSlot() -> TimeInterval {
            guard !requestTimes.isEmpty else { return 0 }
            let oldestRequest = requestTimes.min() ?? Date()
            let windowEnd = oldestRequest.addingTimeInterval(windowDuration)
            return max(0, windowEnd.timeIntervalSinceNow)
        }
    }
    
    // Define rate limits matching backend configuration
    private var rateLimits: [String: RateLimit] = [
        "rating": RateLimit(maxRequests: 25, windowDuration: 60), // 30 req/min with buffer
        "library": RateLimit(maxRequests: 90, windowDuration: 60), // 100 req/min with buffer
        "spotify": RateLimit(maxRequests: 55, windowDuration: 60), // 60 req/min with buffer
        "general": RateLimit(maxRequests: 280, windowDuration: 60) // 300 req/min with buffer
    ]
    
    @Published var isThrottled = false
    @Published var throttleReason: String?
    
    // MARK: - Public Methods
    
    /// Check if a request can be made for the given endpoint category
    func canMakeRequest(for category: RateLimitCategory) async -> Bool {
        let categoryKey = category.key
        
        guard var limit = rateLimits[categoryKey] else {
            return true // Unknown category, allow request
        }
        
        if limit.canMakeRequest() {
            limit.recordRequest()
            rateLimits[categoryKey] = limit
            
            await MainActor.run {
                isThrottled = false
                throttleReason = nil
            }
            
            return true
        } else {
            let waitTime = limit.timeUntilNextSlot()
            await MainActor.run {
                isThrottled = true
                throttleReason = "Rate limited for \(category.displayName). Wait \(Int(waitTime))s"
            }
            
            print("🚦 Rate limit reached for \(category.displayName). Wait \(waitTime)s")
            return false
        }
    }
    
    /// Wait for rate limit to clear for the given category
    func waitForRateLimit(for category: RateLimitCategory) async {
        let categoryKey = category.key
        
        guard var limit = rateLimits[categoryKey] else { return }
        
        if !limit.canMakeRequest() {
            let waitTime = limit.timeUntilNextSlot()
            if waitTime > 0 {
                print("⏳ Waiting \(waitTime)s for \(category.displayName) rate limit")
                await MainActor.run {
                    isThrottled = true
                    throttleReason = "Waiting for \(category.displayName) rate limit"
                }
                
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                
                await MainActor.run {
                    isThrottled = false
                    throttleReason = nil
                }
            }
        }
    }
    
    /// Record a successful request for the given category
    func recordRequest(for category: RateLimitCategory) {
        let categoryKey = category.key
        if var limit = rateLimits[categoryKey] {
            limit.recordRequest()
            rateLimits[categoryKey] = limit
        }
    }
    
    /// Get current usage statistics for a category
    func getUsageStats(for category: RateLimitCategory) -> (current: Int, max: Int, resetIn: TimeInterval) {
        let categoryKey = category.key
        guard var limit = rateLimits[categoryKey] else {
            return (0, 0, 0)
        }
        
        // Clean up old requests
        let now = Date()
        let windowStart = now.addingTimeInterval(-limit.windowDuration)
        limit.requestTimes = limit.requestTimes.filter { $0 > windowStart }
        rateLimits[categoryKey] = limit
        
        let resetTime = limit.requestTimes.min()?.addingTimeInterval(limit.windowDuration).timeIntervalSinceNow ?? 0
        
        return (
            current: limit.requestTimes.count,
            max: limit.maxRequests,
            resetIn: max(0, resetTime)
        )
    }
    
    /// Reset all rate limit counters (useful for testing)
    func resetAllLimits() {
        for key in rateLimits.keys {
            rateLimits[key]?.requestTimes.removeAll()
        }
        
        Task { @MainActor in
            isThrottled = false
            throttleReason = nil
        }
    }
}

// MARK: - Rate Limit Categories

enum RateLimitCategory {
    case rating
    case library
    case spotify
    case general
    
    var key: String {
        switch self {
        case .rating: return "rating"
        case .library: return "library"
        case .spotify: return "spotify"
        case .general: return "general"
        }
    }
    
    var displayName: String {
        switch self {
        case .rating: return "Rating API"
        case .library: return "Library API"
        case .spotify: return "Spotify API"
        case .general: return "General API"
        }
    }
    
    /// Determine category from endpoint path
    static func from(endpoint: String) -> RateLimitCategory {
        let lowercaseEndpoint = endpoint.lowercased()
        
        if lowercaseEndpoint.contains("/api/rating/") {
            return .rating
        } else if lowercaseEndpoint.contains("/api/library/") {
            return .library
        } else if lowercaseEndpoint.contains("/spotify/") {
            return .spotify
        } else {
            return .general
        }
    }
}

// MARK: - APIClient Integration

// Note: Rate limiting is now handled in the main APIClient methods
// The RateLimitService can be integrated directly in APIClient methods as needed