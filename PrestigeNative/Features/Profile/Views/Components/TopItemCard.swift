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
        VStack(spacing: 4) {
            // Image
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Title, subtitle, and prestige badge - invisible container for better centering
            VStack(spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(listeningTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Prestige badge at bottom
                if prestigeLevel != .none {
                    PrestigeBadge(tier: prestigeLevel)
                        .scaleEffect(0.6)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .top)
            
            Spacer(minLength: 0)
        }
        .frame(width: 160)
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
        
        // Convert seconds to milliseconds for TimeFormatter (API sends seconds)
        return TimeFormatter.formatListeningTime(totalTime * 1000)
    }
    
    private var prestigeLevel: PrestigeLevel {
        if let track = track {
            return track.prestigeLevel
        } else if let album = album {
            return album.prestigeLevel
        } else if let artist = artist {
            return artist.prestigeLevel
        }
        return .none
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
                userId: "user1",
                isPinned: false
            )
        )
    }
    .padding()
}
