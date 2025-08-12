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
    
    /// Get item details with caching
    func getItemDetails(itemId: String, itemType: RatingItemType) async throws -> ItemDetailsResponse {
        let cacheKey = "\(itemType.rawValue)_\(itemId)"
        
        // Check cache first
        if let cachedItem = itemCache[cacheKey] {
            print("📦 Cache hit for \(itemType.rawValue) \(itemId)")
            return cachedItem
        }
        
        // Fetch from API
        print("🌐 Fetching \(itemType.rawValue) \(itemId) from API")
        await MainActor.run { isLoading = true }
        
        do {
            let response = try await apiClient.get(
                "/api/library/item/\(itemType.rawValue)/\(itemId)",
                responseType: ItemDetailsResponse.self
            )
            
            // Cache the result
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
    
    /// Get multiple item details efficiently
    func getItemDetailsBatch(items: [(id: String, type: RatingItemType)]) async -> [ItemDetailsResponse] {
        var results: [ItemDetailsResponse] = []
        
        // Process in batches to avoid overwhelming the API
        let batchSize = 5
        let batches = items.chunked(into: batchSize)
        
        for (index, batch) in batches.enumerated() {
            let batchResults = await withTaskGroup(of: ItemDetailsResponse?.self) { group in
                for item in batch {
                    group.addTask {
                        do {
                            return try await self.getItemDetails(itemId: item.id, itemType: item.type)
                        } catch {
                            print("❌ Failed to fetch details for \(item.type.rawValue) \(item.id): \(error)")
                            return nil
                        }
                    }
                }
                
                var results: [ItemDetailsResponse] = []
                for await result in group {
                    if let result = result {
                        results.append(result)
                    }
                }
                return results
            }
            
            results.append(contentsOf: batchResults)
            
            // Small delay between batches to be API-friendly (except for last batch)
            if index < batches.count - 1 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
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