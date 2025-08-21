//
//  ImagePreloader.swift
//  Image Preloading Service
//
//  Preloads images in the background for smooth scrolling
//  and better user experience
//

import SwiftUI
import Foundation

@MainActor
class ImagePreloader: ObservableObject {
    static let shared = ImagePreloader()
    
    private var preloadQueue = DispatchQueue(label: "com.prestige.imagePreloader", qos: .utility)
    private var preloadedImages: Set<String> = []
    private var preloadTasks: [String: Task<Void, Never>] = [:]
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Preload a single image URL
    func preloadImage(_ url: String) {
        guard !url.isEmpty,
              !preloadedImages.contains(url),
              preloadTasks[url] == nil else { return }
        
        let task = Task {
            await performPreload(url: url)
        }
        
        preloadTasks[url] = task
    }
    
    /// Preload multiple image URLs
    func preloadImages(_ urls: [String]) {
        for url in urls {
            preloadImage(url)
        }
    }
    
    /// Preload images from prestige display items
    func preloadPrestigeImages(_ items: [PrestigeDisplayItem]) {
        let urls = items.compactMap { $0.imageUrl.isEmpty ? nil : $0.imageUrl }
        preloadImages(urls)
    }
    
    /// Preload images from album responses
    func preloadAlbumImages(_ albums: [UserAlbumResponse]) {
        let urls = albums.compactMap { $0.album.images.first?.url }
        preloadImages(urls)
    }
    
    /// Preload images from track responses
    func preloadTrackImages(_ tracks: [UserTrackResponse]) {
        let urls = tracks.compactMap { $0.track.album.images.first?.url }
        preloadImages(urls)
    }
    
    /// Preload images from artist responses
    func preloadArtistImages(_ artists: [UserArtistResponse]) {
        let urls = artists.compactMap { $0.artist.images.first?.url }
        preloadImages(urls)
    }
    
    /// Cancel all preload tasks
    func cancelAllPreloads() {
        for task in preloadTasks.values {
            task.cancel()
        }
        preloadTasks.removeAll()
    }
    
    /// Cancel preload for specific URL
    func cancelPreload(for url: String) {
        preloadTasks[url]?.cancel()
        preloadTasks.removeValue(forKey: url)
    }
    
    /// Check if image is preloaded
    func isPreloaded(_ url: String) -> Bool {
        return preloadedImages.contains(url)
    }
    
    /// Clear preloaded images cache
    func clearPreloadedCache() {
        preloadedImages.removeAll()
        print("🗑️ ImagePreloader cache cleared")
    }
    
    // MARK: - Private Implementation
    
    private func performPreload(url: String) async {
        guard let imageURL = URL(string: url) else { return }
        
        do {
            // Check if image is already in URLCache
            let request = URLRequest(url: imageURL)
            if let _ = URLCache.shared.cachedResponse(for: request) {
                await MainActor.run {
                    preloadedImages.insert(url)
                    preloadTasks.removeValue(forKey: url)
                }
                return
            }
            
            // Download and cache the image
            let (data, response) = try await URLSession.shared.data(from: imageURL)
            
            // Verify it's a valid image
            guard let image = UIImage(data: data) else { return }
            
            // Cache the response
            let cachedResponse = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cachedResponse, for: request)
            
            await MainActor.run {
                preloadedImages.insert(url)
                preloadTasks.removeValue(forKey: url)
            }
            
            print("📸 Preloaded image: \(url)")
            
        } catch {
            print("❌ Failed to preload image \(url): \(error)")
            await MainActor.run {
                preloadTasks.removeValue(forKey: url)
            }
        }
    }
}

// MARK: - View Extensions for Easy Integration

extension View {
    /// Preload images when view appears
    func preloadImages(_ urls: [String]) -> some View {
        self.onAppear {
            ImagePreloader.shared.preloadImages(urls)
        }
    }
    
    /// Preload prestige images when view appears
    func preloadPrestigeImages(_ items: [PrestigeDisplayItem]) -> some View {
        self.onAppear {
            ImagePreloader.shared.preloadPrestigeImages(items)
        }
    }
    
    /// Preload album images when view appears
    func preloadAlbumImages(_ albums: [UserAlbumResponse]) -> some View {
        self.onAppear {
            ImagePreloader.shared.preloadAlbumImages(albums)
        }
    }
    
    /// Preload track images when view appears
    func preloadTrackImages(_ tracks: [UserTrackResponse]) -> some View {
        self.onAppear {
            ImagePreloader.shared.preloadTrackImages(tracks)
        }
    }
    
    /// Preload artist images when view appears
    func preloadArtistImages(_ artists: [UserArtistResponse]) -> some View {
        self.onAppear {
            ImagePreloader.shared.preloadArtistImages(artists)
        }
    }
}

// MARK: - Smart Preloading Strategies

extension ImagePreloader {
    /// Preload images for upcoming content based on scroll position
    func preloadForScrolling(
        currentIndex: Int,
        totalItems: Int,
        items: [PrestigeDisplayItem],
        preloadWindow: Int = 10
    ) {
        let startIndex = max(0, currentIndex - preloadWindow/2)
        let endIndex = min(totalItems - 1, currentIndex + preloadWindow)
        
        let itemsToPreload = Array(items[startIndex...endIndex])
        preloadPrestigeImages(itemsToPreload)
    }
    
    /// Preload images with priority (visible items first)
    func preloadWithPriority(
        visibleItems: [PrestigeDisplayItem],
        upcomingItems: [PrestigeDisplayItem]
    ) {
        // Preload visible items immediately
        preloadPrestigeImages(visibleItems)
        
        // Preload upcoming items with delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            preloadPrestigeImages(upcomingItems)
        }
    }
}