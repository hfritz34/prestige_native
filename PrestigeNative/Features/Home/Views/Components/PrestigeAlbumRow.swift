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
        ZStack {
            // Background prestige tier image
            if album.prestigeLevel != .none && !album.prestigeLevel.imageName.isEmpty {
                Image(album.prestigeLevel.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.15)
                    .clipped()
            }
            
            // Content overlay
            HStack(spacing: 12) {
                // Rank number
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
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
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                // Album info
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.album.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(album.album.artists.first?.name ?? "Unknown Artist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(TimeFormatter.formatListeningTime(album.totalTime * 1000)) // Convert seconds to milliseconds
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Prestige badge
                PrestigeBadge(tier: album.prestigeLevel)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(album.prestigeLevel != .none && !album.prestigeLevel.imageName.isEmpty ? Color.black.opacity(0.6) : Color(.systemGray6))
        )
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