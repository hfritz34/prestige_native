//
//  PersonalizedDemoService.swift
//  Personalized Demo Data Service
//
//  Creates personalized demo content using the user's favorite albums
//  or falls back to curated defaults if no favorites exist.
//

import Foundation
import SwiftUI

class PersonalizedDemoService: ObservableObject {
    static let shared = PersonalizedDemoService()
    
    @Published var demoAlbums: [DemoAlbumData] = []
    @Published var isReady = false
    
    private let profileService = ProfileService()
    
    private init() {}
    
    // Default fallback albums for users with no favorites
    private let defaultAlbums: [DemoAlbumData] = [
        DemoAlbumData(
            name: "ASTROWORLD",
            artistName: "Travis Scott", 
            imageUrl: "https://i.scdn.co/image/ab67616d0000b273072e9faef2ef7b6db63834a3"
        ),
        DemoAlbumData(
            name: "Two Star & The Dream Police",
            artistName: "Mk.gee",
            imageUrl: "https://i.scdn.co/image/ab67616d0000b273038b1c2017f14c805cf5b7e9"
        ),
        DemoAlbumData(
            name: "London's Saviour", 
            artistName: "fakemink",
            imageUrl: "https://i.scdn.co/image/ab67616d0000b273e09e5aed7d747f5692b183ea"
        ),
        DemoAlbumData(
            name: "BOY ANONYMOUS",
            artistName: "Paris Texas",
            imageUrl: "https://i.scdn.co/image/ab67616d0000b273a3fed508a9b88a492b589873"
        ),
        DemoAlbumData(
            name: "Gemini Rights",
            artistName: "Steve Lacy",
            imageUrl: "https://i.scdn.co/image/ab67616d0000b27368968350c2550e36d96344ee"
        ),
        DemoAlbumData(
            name: "Melt My Eyez See Your Future",
            artistName: "Denzel Curry",
            imageUrl: "https://i.scdn.co/image/ab67616d0000b2734bc96187df5d76e1d2e14118"
        )
    ]
    
    /// Load personalized demo data using user's favorites or defaults
    func loadPersonalizedDemoData(userId: String) async {
        await MainActor.run {
            isReady = false
        }
        
        // Try to fetch user's favorite albums
        await profileService.fetchFavoriteAlbums(userId: userId, limit: 6)
        
        let personalizedAlbums: [DemoAlbumData]
        
        if !profileService.favoriteAlbums.isEmpty {
            // Use user's favorite albums
            personalizedAlbums = profileService.favoriteAlbums.map { album in
                DemoAlbumData(
                    name: album.name,
                    artistName: album.artists.first?.name ?? "Unknown Artist",
                    imageUrl: album.images.first?.url ?? ""
                )
            }
            print("✅ Using \(personalizedAlbums.count) personalized albums from user favorites")
        } else {
            // Fallback to curated defaults
            personalizedAlbums = defaultAlbums
            print("📦 Using default curated albums - no user favorites found")
        }
        
        await MainActor.run {
            self.demoAlbums = personalizedAlbums
            self.isReady = true
        }
    }
    
    /// Get albums for specific demo sections
    func getProgressionAlbums() -> [DemoAlbumData] {
        return Array(demoAlbums.prefix(6))
    }
    
    func getFeaturedAlbum() -> DemoAlbumData {
        return demoAlbums.first ?? defaultAlbums.first!
    }
    
    func getComparisonAlbums() -> (left: DemoAlbumData?, right: DemoAlbumData?) {
        let albums = Array(demoAlbums.prefix(2))
        if albums.count >= 2 {
            return (left: albums[0], right: albums[1])
        } else if demoAlbums.count >= 1 {
            return (left: demoAlbums[0], right: nil)
        } else {
            return (left: nil, right: nil)
        }
    }
    
    func getFriendsComparisonAlbum() -> DemoAlbumData? {
        if demoAlbums.indices.contains(2) {
            return demoAlbums[2]
        } else if !demoAlbums.isEmpty {
            return demoAlbums[0] // Use first album if not enough favorites
        } else {
            return nil
        }
    }
}

struct DemoAlbumData {
    let name: String
    let artistName: String
    let imageUrl: String
}