//
//  LibraryService.swift
//  Library-related API calls and item metadata management
//
//  This service handles fetching item details and caching metadata
//  to ensure comparison items have proper names and images.
//

import Foundation
import Combine

// Response model for item details API
struct ItemDetailsResponse: Codable {
    let id: String
    let name: String
    let itemType: String
    let imageUrl: String?
    let artists: [String]?
    let albumName: String?
}

class LibraryService: ObservableObject {
    private let apiClient: APIClient
    
    // In-memory cache for item details
    private var itemCache: [String: ItemDetailsResponse] = [:]
    
    @Published var isLoading = false
    @Published var error: APIError?
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    /// Get item details with enhanced caching
    func getItemDetails(itemId: String, itemType: RatingItemType) async throws -> ItemDetailsResponse {
        let cacheKey = "\(itemType.rawValue)_\(itemId)"
        
        // Check local memory cache first for immediate response
        if let cachedItem = itemCache[cacheKey] {
            print("📦 Memory cache hit for \(itemType.rawValue) \(itemId)")
            return cachedItem
        }
        
        // Check response cache service
        let endpoint = APIEndpoints.itemDetails(itemType: itemType.rawValue, itemId: itemId)
        
        print("🌐 Fetching \(itemType.rawValue) \(itemId) from API")
        await MainActor.run { isLoading = true }
        
        do {
            let response = try await apiClient.getCached(
                endpoint,
                responseType: ItemDetailsResponse.self,
                category: .itemMetadata
            )
            
            // Cache in memory for immediate future access
            itemCache[cacheKey] = response
            
            await MainActor.run { 
                isLoading = false 
                error = nil
            }
            
            return response
        } catch {
            await MainActor.run { 
                isLoading = false
                self.error = error as? APIError ?? .networkError(error)
            }
            throw error
        }
    }
    
    /// Get multiple item details efficiently using batch endpoint
    func getItemDetailsBatch(items: [(id: String, type: RatingItemType)]) async -> [ItemDetailsResponse] {
        guard !items.isEmpty else { return [] }
        
        // Check cache first for all items
        var cachedResults: [ItemDetailsResponse] = []
        var uncachedItems: [(id: String, type: RatingItemType)] = []
        
        for item in items {
            let cacheKey = "\(item.type.rawValue)_\(item.id)"
            if let cachedItem = itemCache[cacheKey] {
                cachedResults.append(cachedItem)
            } else {
                uncachedItems.append(item)
            }
        }
        
        // If all items are cached, return immediately
        if uncachedItems.isEmpty {
            print("📦 All \(items.count) items found in cache")
            return cachedResults
        }
        
        print("🌐 Fetching \(uncachedItems.count) items via batch endpoint (cached: \(cachedResults.count))")
        
        // Use new batch endpoint for uncached items
        let batchResults = await fetchItemsBatch(uncachedItems)
        
        // Cache the new results
        for result in batchResults {
            let cacheKey = "\(result.itemType)_\(result.id)"
            itemCache[cacheKey] = result
        }
        
        // Combine cached and fresh results
        return cachedResults + batchResults
    }
    
    /// Internal method to call the new batch API endpoint
    private func fetchItemsBatch(_ items: [(id: String, type: RatingItemType)]) async -> [ItemDetailsResponse] {
        guard !items.isEmpty else { return [] }
        
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        
        do {
            // Build batch request
            var requestBuilder = BatchRequestBuilder()
            requestBuilder.addItems(items)
            let batchRequest = requestBuilder.build()
            
            // Call batch endpoint
            let batchResponse = try await apiClient.post(
                APIEndpoints.batchItemDetails,
                body: batchRequest,
                responseType: BatchItemResponse.self
            )
            
            // Convert batch response to ItemDetailsResponse
            let results = batchResponse.items.map { batchItem in
                ItemDetailsResponse(from: batchItem)
            }
            
            await MainActor.run { error = nil }
            print("✅ Batch endpoint returned \(results.count) items")
            
            return results
            
        } catch let apiError as APIError {
            print("❌ Batch request failed: \(apiError.localizedDescription)")
            await MainActor.run { error = apiError }
            
            // Fallback to individual requests for critical operations
            return await fallbackToIndividualRequests(items)
            
        } catch {
            print("❌ Unexpected batch error: \(error)")
            await MainActor.run { self.error = .networkError(error) }
            
            // Fallback to individual requests
            return await fallbackToIndividualRequests(items)
        }
    }
    
    /// Fallback method when batch endpoint fails
    private func fallbackToIndividualRequests(_ items: [(id: String, type: RatingItemType)]) async -> [ItemDetailsResponse] {
        print("🔄 Falling back to individual requests for \(items.count) items")
        
        // Process in smaller batches to avoid overwhelming API during fallback
        let batchSize = 3
        let batches = items.chunked(into: batchSize)
        var results: [ItemDetailsResponse] = []
        
        for (index, batch) in batches.enumerated() {
            let batchResults = await withTaskGroup(of: ItemDetailsResponse?.self) { group in
                for item in batch {
                    group.addTask {
                        do {
                            return try await self.getItemDetails(itemId: item.id, itemType: item.type)
                        } catch {
                            print("❌ Fallback failed for \(item.type.rawValue) \(item.id): \(error)")
                            return nil
                        }
                    }
                }
                
                var batchResults: [ItemDetailsResponse] = []
                for await result in group {
                    if let result = result {
                        batchResults.append(result)
                    }
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
            
            // Longer delay between batches during fallback to respect rate limits
            if index < batches.count - 1 {
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
            }
        }
        
        return results
    }
    
    /// Clear the cache (useful for memory management)
    func clearCache() {
        itemCache.removeAll()
        print("🗑️ LibraryService cache cleared")
    }
    
    /// Get cache statistics
    func getCacheStats() -> (count: Int, memory: String) {
        let count = itemCache.count
        let memoryUsage = MemoryLayout.size(ofValue: itemCache) + 
                         itemCache.values.reduce(0) { $0 + MemoryLayout.size(ofValue: $1) }
        let memoryString = ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .memory)
        return (count, memoryString)
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}