//
//  PrestigeProgressService.swift
//  Service for fetching prestige progress data
//
//  Handles API calls to calculate user progress toward next prestige tiers
//

import Foundation
import UIKit
import Combine

@MainActor
class PrestigeProgressService: ObservableObject {
    static let shared = PrestigeProgressService()
    
    @Published var isLoading = false
    @Published var error: Error?
    
    private let apiClient = APIClient.shared
    
    // Cache for progress data with hourly refresh strategy
    private var progressCache: [String: PrestigeProgressResponse] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    
    // Hourly cache timeout - listening times only update on the hour
    private let hourlyCache: TimeInterval = 3600 // 1 hour
    
    // Timer for automatic hourly refresh
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        startHourlyRefreshTimer()
        setupAppLifecycleObservers()
    }
    
    // MARK: - Public Methods
    
    /// Fetch progress for current user's item
    func fetchUserProgress(itemId: String, itemType: ContentType) async -> PrestigeProgressResponse? {
        let cacheKey = "user_\(itemId)_\(itemType.rawValue)"
        
        // Check cache first
        if let cached = getCachedProgress(for: cacheKey) {
            return cached
        }
        
        isLoading = true
        error = nil
        
        do {
            let endpoint = "api/prestige-progress/\(itemType.rawValue)/\(itemId)"
            print("🔵 PrestigeProgressService: Making request to endpoint: \(endpoint)")
            print("🔵 PrestigeProgressService: Item type: \(itemType.rawValue), Item ID: \(itemId)")
            
            let response: PrestigeProgressResponse = try await apiClient.get(
                endpoint,
                responseType: PrestigeProgressResponse.self
            )
            
            print("✅ PrestigeProgressService: Successfully fetched real API progress for \(itemId)")
            print("✅ PrestigeProgressService: Current tier: \(response.currentLevel.displayName)")
            print("✅ PrestigeProgressService: Progress: \(response.progress.percentage)%")
            print("✅ PrestigeProgressService: Current value: \(response.progress.currentValue) min")
            
            // Cache the response
            cacheProgress(response, for: cacheKey)
            isLoading = false
            return response
            
        } catch {
            print("❌ PrestigeProgressService: Failed to fetch user prestige progress")
            print("❌ PrestigeProgressService: Error: \(error)")
            print("❌ PrestigeProgressService: Error description: \(error.localizedDescription)")
            
            // Log specific error types
            if let apiError = error as? APIError {
                print("❌ PrestigeProgressService: API Error type: \(apiError)")
            }
            
            if let urlError = error as? URLError {
                print("❌ PrestigeProgressService: URL Error code: \(urlError.code)")
                print("❌ PrestigeProgressService: URL Error description: \(urlError.localizedDescription)")
            }
            
            self.error = error
            isLoading = false
            return nil
        }
    }
    
    /// Fetch progress for friend's item
    func fetchFriendProgress(friendId: String, itemId: String, itemType: ContentType) async -> PrestigeProgressResponse? {
        let cacheKey = "friend_\(friendId)_\(itemId)_\(itemType.rawValue)"
        
        // Check cache first
        if let cached = getCachedProgress(for: cacheKey) {
            return cached
        }
        
        isLoading = true
        error = nil
        
        do {
            let endpoint = "api/friends/\(friendId)/prestige-progress/\(itemType.rawValue)/\(itemId)"
            print("🔵 PrestigeProgressService: Making friend request to endpoint: \(endpoint)")
            print("🔵 PrestigeProgressService: Friend ID: \(friendId), Item type: \(itemType.rawValue), Item ID: \(itemId)")
            
            let response: PrestigeProgressResponse = try await apiClient.get(
                endpoint,
                responseType: PrestigeProgressResponse.self
            )
            
            print("✅ PrestigeProgressService: Successfully fetched friend progress for \(itemId)")
            print("✅ PrestigeProgressService: Friend tier: \(response.currentLevel.displayName)")
            print("✅ PrestigeProgressService: Friend progress: \(response.progress.percentage)%")
            
            // Cache the response
            cacheProgress(response, for: cacheKey)
            isLoading = false
            return response
            
        } catch {
            print("❌ PrestigeProgressService: Failed to fetch friend prestige progress")
            print("❌ PrestigeProgressService: Friend ID: \(friendId), Error: \(error)")
            
            // Log specific error types  
            if let apiError = error as? APIError {
                print("❌ PrestigeProgressService: Friend API Error type: \(apiError)")
            }
            
            self.error = error
            isLoading = false
            return nil
        }
    }
    
    /// Clear all cached progress data
    func clearCache() {
        progressCache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    /// Clear cache for specific item
    func clearCache(for itemId: String) {
        let keysToRemove = progressCache.keys.filter { $0.contains(itemId) }
        keysToRemove.forEach { key in
            progressCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
    }
    
    /// Get time until next hourly refresh for UI feedback
    func timeUntilNextRefresh() -> TimeInterval {
        let now = Date()
        let calendar = Calendar.current
        
        // Get the start of the next hour
        guard let currentHour = calendar.dateInterval(of: .hour, for: now),
              let nextHour = calendar.date(byAdding: .hour, value: 1, to: currentHour.start) else {
            return 0
        }
        
        return nextHour.timeIntervalSince(now)
    }
    
    /// Check if any cached data needs refreshing (for background tasks)
    func hasStaleData() -> Bool {
        let now = Date()
        
        for (_, timestamp) in cacheTimestamps {
            if shouldRefreshCache(cachedAt: timestamp, currentTime: now) {
                return true
            }
        }
        
        return false
    }
    
    /// Refresh all cached progress data in background
    func refreshAllCachedData() async {
        let staleCacheKeys = cacheTimestamps.compactMap { (key, timestamp) in
            shouldRefreshCache(cachedAt: timestamp, currentTime: Date()) ? key : nil
        }
        
        // Refresh stale cache entries
        for key in staleCacheKeys {
            if let components = parseCacheKey(key) {
                if components.isUser {
                    _ = await fetchUserProgress(itemId: components.itemId, itemType: components.itemType)
                } else if let friendId = components.friendId {
                    _ = await fetchFriendProgress(friendId: friendId, itemId: components.itemId, itemType: components.itemType)
                }
            }
        }
    }
    
    /// Parse cache key to extract components
    private func parseCacheKey(_ key: String) -> (isUser: Bool, friendId: String?, itemId: String, itemType: ContentType)? {
        let parts = key.split(separator: "_")
        
        if parts.count >= 3 {
            if parts[0] == "user" {
                let itemId = String(parts[1])
                guard let itemType = ContentType(rawValue: String(parts[2])) else { return nil }
                return (isUser: true, friendId: nil, itemId: itemId, itemType: itemType)
            } else if parts[0] == "friend" && parts.count >= 4 {
                let friendId = String(parts[1])
                let itemId = String(parts[2])
                guard let itemType = ContentType(rawValue: String(parts[3])) else { return nil }
                return (isUser: false, friendId: friendId, itemId: itemId, itemType: itemType)
            }
        }
        
        return nil
    }
    
    // MARK: - Background Refresh & Lifecycle
    
    /// Start timer that refreshes cache at the top of each hour
    private func startHourlyRefreshTimer() {
        stopHourlyRefreshTimer()
        
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate time until next hour
        guard let currentHour = calendar.dateInterval(of: .hour, for: now),
              let nextHour = calendar.date(byAdding: .hour, value: 1, to: currentHour.start) else {
            return
        }
        
        let timeUntilNextHour = nextHour.timeIntervalSince(now)
        
        // Schedule timer to fire at the top of the next hour, then every hour
        refreshTimer = Timer.scheduledTimer(withTimeInterval: timeUntilNextHour, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.performHourlyRefresh()
                self?.scheduleRecurringHourlyTimer()
            }
        }
    }
    
    /// Schedule recurring hourly timer after the first refresh
    private func scheduleRecurringHourlyTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: hourlyCache, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performHourlyRefresh()
            }
        }
    }
    
    /// Stop the hourly refresh timer
    private func stopHourlyRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    /// Perform background refresh of stale cache data
    private func performHourlyRefresh() async {
        guard hasStaleData() else { return }
        
        print("🔄 PrestigeProgressService: Performing hourly refresh of stale cache data...")
        await refreshAllCachedData()
    }
    
    /// Setup app lifecycle observers for cache management
    private func setupAppLifecycleObservers() {
        // Listen for app becoming active to refresh stale data
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    if self?.hasStaleData() == true {
                        await self?.refreshAllCachedData()
                    }
                    self?.startHourlyRefreshTimer() // Restart timer in case it was invalidated
                }
            }
            .store(in: &cancellables)
        
        // Stop timer when app goes to background to save resources
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.stopHourlyRefreshTimer()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
        cancellables.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func getCachedProgress(for key: String) -> PrestigeProgressResponse? {
        guard let cached = progressCache[key],
              let timestamp = cacheTimestamps[key] else {
            // Cache miss
            return nil
        }
        
        let now = Date()
        
        // Check if we need to refresh based on hourly listening time updates
        if shouldRefreshCache(cachedAt: timestamp, currentTime: now) {
            // Cache expired - remove and return nil to trigger refresh
            progressCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
            return nil
        }
        
        return cached
    }
    
    /// Determines if cache should be refreshed based on intelligent hourly logic
    private func shouldRefreshCache(cachedAt: Date, currentTime: Date) -> Bool {
        let calendar = Calendar.current
        
        // Get the top of the hour when data was cached
        let cachedHour = calendar.dateInterval(of: .hour, for: cachedAt)?.start ?? cachedAt
        
        // Get the current top of the hour
        let currentHour = calendar.dateInterval(of: .hour, for: currentTime)?.start ?? currentTime
        
        // If we're in a different hour than when cached, refresh
        // This ensures we check for new data after listening times update
        if currentHour > cachedHour {
            return true
        }
        
        // Fallback: if somehow more than 1 hour has passed, definitely refresh
        if currentTime.timeIntervalSince(cachedAt) > hourlyCache {
            return true
        }
        
        return false
    }
    
    private func cacheProgress(_ progress: PrestigeProgressResponse, for key: String) {
        progressCache[key] = progress
        cacheTimestamps[key] = Date()
    }
}

// MARK: - Mock Data for Development

extension PrestigeProgressService {
    /// Generate mock progress data for development/testing
    func generateMockProgress(for item: PrestigeDisplayItem) -> PrestigeProgressResponse? {
        // Only return mock data if we have a valid item
        guard !item.spotifyId.isEmpty else { return nil }
        
        let currentTier = item.prestigeLevel
        let nextTier = currentTier.nextLevel
        
        // Generate consistent progress values based on item ID (for deterministic mock data)
        let seedValue = abs(item.spotifyId.hashValue)
        let mockProgress = 0.15 + (Double(seedValue % 70) / 100.0) // 0.15 to 0.85
        let mockCurrentValue = 50.0 + Double(seedValue % 450) // 50 to 500
        let mockNextThreshold = mockCurrentValue / mockProgress
        let mockRemainingMinutes = (mockNextThreshold - mockCurrentValue) * (0.8 + (Double(seedValue % 40) / 100.0)) // 0.8 to 1.2
        
        return PrestigeProgressResponse(
            itemId: item.spotifyId,
            itemType: item.contentType.rawValue,
            itemName: item.name,
            currentLevel: PrestigeProgressLevel(
                tier: currentTier.rawValue,
                displayName: currentTier.displayName,
                color: currentTier.color,
                imageName: currentTier.imageName,
                threshold: mockCurrentValue
            ),
            nextLevel: nextTier != nil ? PrestigeProgressLevel(
                tier: nextTier!.rawValue,
                displayName: nextTier!.displayName,
                color: nextTier!.color,
                imageName: nextTier!.imageName,
                threshold: mockNextThreshold
            ) : nil,
            progress: ProgressDetails(
                currentValue: mockCurrentValue,
                nextThreshold: nextTier != nil ? mockNextThreshold : nil,
                percentage: mockProgress * 100,
                isMaxLevel: nextTier == nil
            ),
            estimatedTimeToNext: nextTier != nil ? TimeEstimation(
                minutesRemaining: mockRemainingMinutes,
                formattedTime: formatMockTime(mockRemainingMinutes),
                estimationType: "based_on_recent_activity"
            ) : nil
        )
    }
    
    private func formatMockTime(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            return remainingHours > 0 ? "\(days)d \(remainingHours)h" : "\(days)d"
        } else if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}