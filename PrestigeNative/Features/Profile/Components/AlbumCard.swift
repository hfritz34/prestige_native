//
//  AlbumCard.swift
//  Album card component for profile grid
//
//  Displays album artwork, name, and prestige info.
//

import SwiftUI

struct AlbumCard: View {
    let albumData: UserAlbumResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album Artwork
            AsyncImage(url: URL(string: albumData.album.images.first?.url ?? "")) { image in
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
            .frame(width: nil, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Album Info
            VStack(alignment: .leading, spacing: 4) {
                Text(albumData.album.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(albumData.album.artists.first?.name ?? "Unknown Artist")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Prestige Badge
                HStack {
                    if albumData.prestigeLevel != .none {
                        Image(albumData.prestigeLevel.imageName)
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    
                    Text(albumData.prestigeLevel.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
            }
        }
        .onTapGesture {
            // TODO: Navigate to album detail view
        }
    }
}

#Preview {
    AlbumCard(
        albumData: UserAlbumResponse(
            totalTime: 180000, // 3000 minutes in seconds
            album: AlbumResponse(
                id: "preview_id",
                name: "The Dark Side of the Moon",
                images: [],
                artists: [.init(id: "artist_id", name: "Pink Floyd")]
            ),
            userId: "preview_user"
        )
    )
    .frame(width: 170)
    .padding()
}