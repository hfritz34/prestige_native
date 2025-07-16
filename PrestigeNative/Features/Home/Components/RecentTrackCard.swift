//
//  RecentTrackCard.swift
//  Card component for recently played tracks
//
//  Displays track info in a horizontal scrolling card format.
//

import SwiftUI

struct RecentTrackCard: View {
    let track: RecentlyPlayedResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Track Image
            AsyncImage(url: URL(string: track.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Track Info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.trackName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(track.artistName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 120, alignment: .leading)
        }
        .onTapGesture {
            // TODO: Navigate to track detail view
        }
    }
}

#Preview {
    RecentTrackCard(
        track: RecentlyPlayedResponse(
            trackName: "Bohemian Rhapsody",
            artistName: "Queen",
            imageUrl: "",
            id: "preview_id"
        )
    )
    .padding()
}