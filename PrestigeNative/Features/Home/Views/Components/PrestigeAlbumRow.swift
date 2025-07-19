//
//  PrestigeAlbumRow.swift
//  Album row component for prestige display
//
//  Shows album prestige with badge, ranking, and listening time.
//

import SwiftUI

struct PrestigeAlbumRow: View {
    let album: UserAlbumResponse
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            // Album image
            AsyncImage(url: URL(string: album.album.images.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Album info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.album.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(album.album.artists.first?.name ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(TimeFormatter.formatListeningTime(album.totalTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Prestige badge
            PrestigeBadge(tier: album.prestigeLevel)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
}

#Preview {
    PrestigeAlbumRow(
        album: UserAlbumResponse(
            totalTime: 240000,
            album: AlbumResponse(
                id: "1",
                name: "Sample Album",
                images: [],
                artists: [.init(id: "artist_id", name: "Sample Artist")]
            ),
            userId: "user1"
        ),
        rank: 1
    )
    .padding()
}