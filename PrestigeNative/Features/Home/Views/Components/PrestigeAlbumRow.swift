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
                
                Text("\(formatListeningTime(album.totalTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Prestige badge
            PrestigeBadge(tier: getPrestigeTier(for: album.totalTime))
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
    
    private func getPrestigeTier(for totalTime: Int) -> PrestigeLevel {
        let minutes = totalTime / (1000 * 60)
        
        switch minutes {
        case 0..<60:
            return .bronze
        case 60..<180:
            return .silver
        case 180..<360:
            return .gold
        case 360..<720:
            return .diamond
        default:
            return .darkMatter
        }
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