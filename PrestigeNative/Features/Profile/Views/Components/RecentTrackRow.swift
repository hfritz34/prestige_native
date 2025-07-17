//
//  RecentTrackRow.swift
//  Row component for recently played tracks
//
//  Shows recently played track info in a simple list format.
//

import SwiftUI

struct RecentTrackRow: View {
    let track: TrackResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Track image
            AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(track.artists.first?.name ?? "Unknown Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Recently played indicator
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RecentTrackRow(
        track: TrackResponse(
            id: "1",
            name: "Recent Song",
            duration_ms: 180000,
            album: .init(id: "album_id", name: "Recent Album", images: []),
            artists: [.init(id: "artist_id", name: "Recent Artist")]
        )
    )
    .padding()
}