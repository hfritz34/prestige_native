//
//  TopItemCard.swift
//  Card component for top items carousel
//
//  Shows track/album/artist in a compact card format for the Top section.
//

import SwiftUI

struct TopItemCard: View {
    private let track: UserTrackResponse?
    private let album: UserAlbumResponse?
    private let artist: UserArtistResponse?
    
    init(track: UserTrackResponse) {
        self.track = track
        self.album = nil
        self.artist = nil
    }
    
    init(album: UserAlbumResponse) {
        self.track = nil
        self.album = album
        self.artist = nil
    }
    
    init(artist: UserArtistResponse) {
        self.track = nil
        self.album = nil
        self.artist = artist
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(listeningTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120)
    }
    
    private var imageUrl: String {
        if let track = track {
            return track.track.album.images.first?.url ?? ""
        } else if let album = album {
            return album.album.images.first?.url ?? ""
        } else if let artist = artist {
            return artist.artist.images.first?.url ?? ""
        }
        return ""
    }
    
    private var title: String {
        if let track = track {
            return track.track.name
        } else if let album = album {
            return album.album.name
        } else if let artist = artist {
            return artist.artist.name
        }
        return ""
    }
    
    private var subtitle: String {
        if let track = track {
            return track.track.artists.first?.name ?? "Unknown Artist"
        } else if let album = album {
            return album.album.artists.first?.name ?? "Unknown Artist"
        } else if let artist = artist {
            return "Artist"
        }
        return ""
    }
    
    private var listeningTime: String {
        let totalTime: Int
        if let track = track {
            totalTime = track.totalTime
        } else if let album = album {
            totalTime = album.totalTime
        } else if let artist = artist {
            totalTime = artist.totalTime
        } else {
            totalTime = 0
        }
        
        let seconds = totalTime / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    HStack {
        TopItemCard(
            track: UserTrackResponse(
                totalTime: 120000,
                track: TrackResponse(
                    id: "1",
                    name: "Sample Track",
                    duration_ms: 180000,
                    album: .init(id: "album_id", name: "Sample Album", images: []),
                    artists: [.init(id: "artist_id", name: "Sample Artist")]
                ),
                userId: "user1"
            )
        )
    }
    .padding()
}
