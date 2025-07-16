//
//  TopTrackRow.swift
//  Row component for top tracks with prestige badges
//
//  Displays track ranking, info, and prestige level.
//

import SwiftUI

struct TopTrackRow: View {
    let track: UserTrackResponse
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Number
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .frame(width: 30, alignment: .leading)
            
            // Track Image
            AsyncImage(url: URL(string: track.track.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                            .font(.caption)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Track Info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.track.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(track.track.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Prestige Badge and Stats
            VStack(alignment: .trailing, spacing: 2) {
                // Prestige Badge
                HStack(spacing: 4) {
                    if track.prestigeLevel != .none {
                        Image(track.prestigeLevel.imageName)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    
                    Text(track.prestigeLevel.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.2))
                        )
                        .foregroundColor(.purple)
                }
                
                // Listening Time
                Text(track.totalTimeMinutes.listeningTimeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            // TODO: Navigate to track detail view
        }
    }
}

#Preview {
    TopTrackRow(
        track: UserTrackResponse(
            totalTime: 75000, // 1250 minutes in seconds
            track: TrackResponse(
                id: "preview_id",
                name: "Bohemian Rhapsody",
                imageUrl: "",
                spotifyUrl: "",
                albumName: "A Night at the Opera",
                artistName: "Queen",
                durationMs: 355000
            ),
            userId: "preview_user"
        ),
        rank: 1
    )
    .padding()
}