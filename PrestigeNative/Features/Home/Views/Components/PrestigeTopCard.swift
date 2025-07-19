//
//  PrestigeTopCard.swift
//  Top prestige card component for displaying the top 3 prestiges
//
//  Large card with prestige tier background image and content overlay.
//

import SwiftUI

struct PrestigeTopCard: View {
    let item: PrestigeDisplayItem
    let rank: Int
    
    var body: some View {
        ZStack {
            // Background prestige tier image
            Image(item.prestigeLevel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 280)
                .clipped()
                .opacity(0.3)
            
            // Content overlay
            VStack(spacing: 12) {
                // Rank number
                Text("#\(rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                
                Spacer()
                
                // Item image
                AsyncImage(url: URL(string: item.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Item info
                VStack(spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Text(TimeFormatter.formatListeningTime(item.totalTimeSeconds * 1000))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 16)
        }
        .frame(width: 200, height: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.black.opacity(0.3)],
                    startPoint: .bottom,
                    endPoint: .top
                ))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
}

// MARK: - Supporting Types

struct PrestigeDisplayItem {
    let name: String
    let subtitle: String
    let imageUrl: String
    let totalTimeSeconds: Int
    let prestigeLevel: PrestigeLevel
    
    // Convenience initializers for different item types
    static func fromTrack(_ track: UserTrackResponse) -> PrestigeDisplayItem {
        return PrestigeDisplayItem(
            name: track.track.name,
            subtitle: track.track.artists.first?.name ?? "Unknown Artist",
            imageUrl: track.track.album.images.first?.url ?? "",
            totalTimeSeconds: track.totalTime,
            prestigeLevel: track.prestigeLevel
        )
    }
    
    static func fromAlbum(_ album: UserAlbumResponse) -> PrestigeDisplayItem {
        return PrestigeDisplayItem(
            name: album.album.name,
            subtitle: album.album.artists.first?.name ?? "Unknown Artist",
            imageUrl: album.album.images.first?.url ?? "",
            totalTimeSeconds: album.totalTime,
            prestigeLevel: album.prestigeLevel
        )
    }
    
    static func fromArtist(_ artist: UserArtistResponse) -> PrestigeDisplayItem {
        return PrestigeDisplayItem(
            name: artist.artist.name,
            subtitle: "Artist",
            imageUrl: artist.artist.images.first?.url ?? "",
            totalTimeSeconds: artist.totalTime,
            prestigeLevel: artist.prestigeLevel
        )
    }
}

#Preview {
    HStack(spacing: 16) {
        PrestigeTopCard(
            item: PrestigeDisplayItem(
                name: "Sample Track",
                subtitle: "Sample Artist",
                imageUrl: "",
                totalTimeSeconds: 7200, // 2 hours
                prestigeLevel: .gold
            ),
            rank: 1
        )
        
        PrestigeTopCard(
            item: PrestigeDisplayItem(
                name: "Another Track",
                subtitle: "Another Artist",
                imageUrl: "",
                totalTimeSeconds: 3600, // 1 hour
                prestigeLevel: .silver
            ),
            rank: 2
        )
    }
    .padding()
    .background(Color.black)
}