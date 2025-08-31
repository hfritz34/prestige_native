//
//  FavoriteItemCard.swift
//  Card component for favorites carousel
//
//  Shows favorite tracks in a compact card format.
//

import SwiftUI

struct FavoriteItemCard: View {
    let track: TrackResponse
    let prestigeLevel: PrestigeLevel
    
    var body: some View {
        VStack(spacing: 4) {
            // Track image with heart overlay
            AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 130, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                // Heart icon overlay on bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(6)
                    }
                }
            )
            
            // Track info with prestige badge - invisible container for better centering
            VStack(spacing: 1) {
                Text(track.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(track.artists.first?.name ?? "Unknown Artist")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                // Prestige badge at bottom
                if prestigeLevel != .none {
                    PrestigeBadge(tier: prestigeLevel)
                        .scaleEffect(0.6)
                }
            }
            .frame(maxWidth: .infinity)
            
        }
        .frame(width: 130)
    }
}

#Preview {
    FavoriteItemCard(
        track: TrackResponse(
            id: "1",
            name: "Favorite Song",
            duration_ms: 180000,
            album: .init(id: "album_id", name: "Favorite Album", images: []),
            artists: [.init(id: "artist_id", name: "Favorite Artist")]
        ),
        prestigeLevel: .gold
    )
    .padding()
}