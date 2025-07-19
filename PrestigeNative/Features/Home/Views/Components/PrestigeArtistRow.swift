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
        HStack(spacing: 12) {
            // Rank number
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
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
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            // Artist info
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.artist.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(formatListeningTime(artist.totalTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Prestige badge
            PrestigeBadge(tier: artist.prestigeLevel)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatListeningTime(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
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