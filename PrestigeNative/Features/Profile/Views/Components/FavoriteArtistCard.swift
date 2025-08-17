//
//  FavoriteArtistCard.swift
//  Card component for favorite artists carousel
//
//  Shows favorite artists in a compact card format.
//

import SwiftUI

struct FavoriteArtistCard: View {
    let artist: ArtistResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artist image
            AsyncImage(url: URL(string: artist.images.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle()) // Artists typically use circular images
            
            // Artist info
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text("Artist")
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
    FavoriteArtistCard(
        artist: ArtistResponse(
            id: "1", 
            name: "Favorite Artist",
            images: [ImageResponse(url: "", height: 300, width: 300)]
        )
    )
    .padding()
}