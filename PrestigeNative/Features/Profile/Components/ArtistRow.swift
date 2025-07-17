//
//  ArtistRow.swift
//  Artist row component for profile list
//
//  Displays artist info with prestige level.
//

import SwiftUI

struct ArtistRow: View {
    let artistData: UserArtistResponse
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Number
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .frame(width: 30, alignment: .leading)
            
            // Artist Image
            AsyncImage(url: URL(string: artistData.artist.artistImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .foregroundColor(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.mic")
                            .foregroundColor(.gray)
                            .font(.caption)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            // Artist Info
            VStack(alignment: .leading, spacing: 4) {
                Text(artistData.artist.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                // Listening Stats
                Text(artistData.totalTimeMinutes.listeningTimeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Prestige Badge
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    if artistData.prestigeLevel != .none {
                        Image(artistData.prestigeLevel.imageName)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    
                    Text(artistData.prestigeLevel.displayName)
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
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            // TODO: Navigate to artist detail view
        }
    }
}

#Preview {
    ArtistRow(
        artistData: UserArtistResponse(
            totalTime: 240000, // 4000 minutes in seconds
            artist: ArtistResponse(
                id: "preview_id",
                name: "The Beatles",
                images: [ImageResponse(url: "", height: 640, width: 640)],
                spotifyUrl: ""
            ),
            userId: "preview_user"
        ),
        rank: 1
    )
    .padding()
}