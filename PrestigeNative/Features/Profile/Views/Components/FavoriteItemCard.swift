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
            AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { image in
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
                
                Text(track.artists.first?.name ?? "Unknown Artist")
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
            duration_ms: 180000,
            album: .init(id: "album_id", name: "Favorite Album", images: []),
            artists: [.init(id: "artist_id", name: "Favorite Artist")]
        )
    )
    .padding()
}