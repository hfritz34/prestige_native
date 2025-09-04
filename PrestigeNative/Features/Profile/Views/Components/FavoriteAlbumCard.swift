//
//  FavoriteAlbumCard.swift
//  Card component for favorite albums carousel
//
//  Shows favorite albums in a compact card format.
//

import SwiftUI

struct FavoriteAlbumCard: View {
    let album: AlbumResponse
    let prestigeLevel: PrestigeLevel
    
    var body: some View {
        VStack(spacing: 4) {
            // Album image with heart overlay
            AsyncImage(url: URL(string: album.images.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 160, height: 160)
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
            
            // Album info with prestige badge - invisible container for better centering
            VStack(spacing: 1) {
                Text(album.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(album.artists.first?.name ?? "Unknown Artist")
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
        .frame(width: 160)
    }
}

#Preview {
    FavoriteAlbumCard(
        album: AlbumResponse(
            id: "1",
            name: "Favorite Album",
            images: [ImageResponse(url: "", height: 300, width: 300)],
            artists: [TrackResponse.ArtistInfo(id: "artist_id", name: "Favorite Artist")]
        ),
        prestigeLevel: .gold
    )
    .padding()
}