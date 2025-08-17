//
//  PrestigeTrackRow.swift
//  Track row component for prestige display
//
//  Shows track prestige with badge, ranking, and listening time.
//

import SwiftUI

struct PrestigeTrackRow: View {
    let track: UserTrackResponse
    let rank: Int
    
    var body: some View {
        ZStack {
            // Background prestige tier image
            if track.prestigeLevel != .none && !track.prestigeLevel.imageName.isEmpty {
                Image(track.prestigeLevel.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.35)
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
                
                // Track image
                AsyncImage(url: URL(string: track.track.album.images.first?.url ?? "")) { image in
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
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.track.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(track.track.artists.first?.name ?? "Unknown Artist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(TimeFormatter.formatListeningTime(track.totalTime * 1000)) // Convert seconds to milliseconds
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Prestige badge
                PrestigeBadge(tier: track.prestigeLevel)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(track.prestigeLevel != .none && !track.prestigeLevel.imageName.isEmpty ? Color.black.opacity(0.6) : Color(.systemGray6))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
}

#Preview {
    PrestigeTrackRow(
        track: UserTrackResponse(
            totalTime: 120000,
            track: TrackResponse(
                id: "1",
                name: "Sample Track",
                duration_ms: 180000,
                album: .init(id: "album_id", name: "Sample Album", images: []),
                artists: [.init(id: "artist_id", name: "Sample Artist")]
            ),
            userId: "user1"
        ),
        rank: 1
    )
    .padding()
}