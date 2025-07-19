//
//  RecentTrackRow.swift
//  Row component for recently played tracks
//
//  Shows recently played track info in a simple list format.
//

import SwiftUI

struct RecentTrackRow: View {
    let track: RecentlyPlayedResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Track image (larger size to match web app)
            AsyncImage(url: URL(string: track.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.trackName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(track.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    RecentTrackRow(
        track: RecentlyPlayedResponse(
            trackName: "Recent Song",
            artistName: "Recent Artist",
            imageUrl: "https://i.scdn.co/image/ab67616d0000b273d6160eebe5448876e265e48a",
            id: "1"
        )
    )
    .padding()
}