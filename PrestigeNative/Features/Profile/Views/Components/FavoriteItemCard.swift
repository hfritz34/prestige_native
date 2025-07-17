//
//  FavoriteItemCard.swift
//  Card component for favorites carousel
//
//  Shows favorite tracks in a compact card format.
//

import SwiftUI

struct FavoriteItemCard: View {
    let track: TrackResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Track image
            AsyncImage(url: URL(string: track.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(track.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Favorite indicator
            HStack {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Spacer()
            }
        }
        .frame(width: 120)
    }
}

#Preview {
    FavoriteItemCard(
        track: TrackResponse(
            id: "1",
            name: "Favorite Song",
            imageUrl: "https://via.placeholder.com/300",
            spotifyUrl: "",
            albumName: "Favorite Album",
            artistName: "Favorite Artist",
            durationMs: 180000
        )
    )
    .padding()
}