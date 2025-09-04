//
//  PrestigeArtistRow.swift
//  Artist row component for prestige display
//
//  Shows artist prestige with badge, ranking, and listening time.
//

import SwiftUI

struct PrestigeArtistRow: View {
    let artist: UserArtistResponse
    let rank: Int
    
    var body: some View {
        ZStack {
            // Background prestige tier image - properly contained
            if artist.prestigeLevel != .none && !artist.prestigeLevel.imageName.isEmpty {
                Image(artist.prestigeLevel.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.8)
                    .scaleEffect(1.1)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Content overlay
            HStack(spacing: 12) {
                // Rank number
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(width: 30)
                
                // Artist image
                AsyncImage(url: URL(string: artist.artist.images.first?.url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                // Artist info
                VStack(alignment: .leading, spacing: 4) {
                    Text(artist.artist.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Artist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(TimeFormatter.formatListeningTime(artist.totalTime * 1000)) // Convert seconds to milliseconds
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Prestige badge
                PrestigeBadge(tier: artist.prestigeLevel, showText: false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(artist.prestigeLevel != .none && !artist.prestigeLevel.imageName.isEmpty ? Color.black.opacity(0.6) : Color(.systemGray6))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
}

#Preview {
    PrestigeArtistRow(
        artist: UserArtistResponse(
            totalTime: 360000,
            artist: ArtistResponse(
                id: "1",
                name: "Sample Artist",
                images: [ImageResponse(url: "https://via.placeholder.com/300", height: 300, width: 300)]
            ),
            userId: "user1"
        ),
        rank: 1
    )
    .padding()
}