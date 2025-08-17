//
//  FavoriteAlbumCard.swift
//  Card component for favorite albums carousel
//
//  Shows favorite albums in a compact card format.
//

import SwiftUI

struct FavoriteAlbumCard: View {
    let album: AlbumResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album image
            AsyncImage(url: URL(string: album.images.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Album info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(album.artists.first?.name ?? "Unknown Artist")
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
    FavoriteAlbumCard(
        album: AlbumResponse(
            id: "1",
            name: "Favorite Album",
            images: [ImageResponse(url: "", height: 300, width: 300)],
            artists: [TrackResponse.ArtistInfo(id: "artist_id", name: "Favorite Artist")]
        )
    )
    .padding()
}