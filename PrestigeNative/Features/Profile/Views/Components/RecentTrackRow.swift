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
            AsyncImage(url: URL(string: track.imageUrl)) { image in
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
                
                Text(track.artistName)
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
            imageUrl: "https://via.placeholder.com/300",
            spotifyUrl: "",
            albumName: "Recent Album",
            artistName: "Recent Artist",
            durationMs: 180000
        )
    )
    .padding()
}