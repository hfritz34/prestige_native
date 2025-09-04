//
//  FriendAlbumRankingRow.swift
//  Row component for displaying friend's album rankings
//

import SwiftUI

struct FriendAlbumRankingRow: View {
    let album: FriendAlbumRatingResponse
    let friendName: String
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Album rank
            Text("#\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Theme.primary)
                .frame(width: 24, alignment: .center)
            
            // Album Image
            CachedAsyncImage(
                url: album.albumImageUrl,
                placeholder: Image(systemName: "square.stack"),
                contentMode: .fill
            )
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Album Info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.albumName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(album.trackCount) tracks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let listeningTime = album.friendListeningTime {
                        Text("• \(TimeFormatter.formatListeningTime(listeningTime * 1000))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let rating = album.friendRatingScore {
                        Text("• \(String(format: "%.1f", rating))★")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Pins and Favorites + Prestige
            HStack(spacing: 8) {
                // Status indicators
                HStack(spacing: 4) {
                    if album.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    if album.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // Prestige Badge for friend's album
                PrestigeBadge(
                    tier: PrestigeLevel(rawValue: album.friendPrestigeTier) ?? .none
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
        .cornerRadius(8)
    }
}

#Preview {
    FriendAlbumRankingRow(
        album: FriendAlbumRatingResponse(
            albumId: "sample-album-id",
            albumName: "A Night at the Opera",
            albumImageUrl: "https://example.com/album.jpg",
            releaseDate: Date(),
            trackCount: 12,
            friendId: "friend123",
            friendListeningTime: 7200,
            friendRatingScore: 8.8,
            friendPosition: 3,
            friendPrestigeTier: "Emerald",
            isPinned: true,
            isFavorite: false
        ),
        friendName: "Alex",
        rank: 3
    )
    .padding()
}