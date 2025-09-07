//
//  FriendTrackRankingRow.swift
//  Row component for displaying friend's track rankings
//

import SwiftUI

struct FriendTrackRankingRow: View {
    let track: FriendTrackRankingResponse
    let friendName: String
    
    private var prestigeLevel: PrestigeLevel {
        PrestigeLevel(rawValue: track.friendPrestigeTier) ?? .none
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Track ranking within album
            if let ranking = track.friendRankWithinAlbum {
                Text("🏆 #\(ranking)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primary)
                    .frame(width: 40, alignment: .leading)
            } else {
                Text("\(track.trackNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .center)
            }
            
            // Track Image
            CachedAsyncImage(
                url: track.trackImageUrl,
                placeholder: Image(systemName: "music.note"),
                contentMode: .fill
            )
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.trackName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let listeningTime = track.friendListeningTime {
                        Text("\(TimeFormatter.formatListeningTime(listeningTime * 1000))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let rating = track.friendRatingScore {
                        Text("• \(String(format: "%.1f", rating))★")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let position = track.friendPosition {
                        Text("• #\(position) overall")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons on bottom right (can be added later if needed)
            VStack {
                Spacer()
                // Buttons can be added here if needed
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    (Color(hex: prestigeLevel.color) ?? .gray).opacity(0.15),
                    (Color(hex: prestigeLevel.color) ?? .gray).opacity(0.05)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke((Color(hex: prestigeLevel.color) ?? .gray).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

#Preview {
    FriendTrackRankingRow(
        track: FriendTrackRankingResponse(
            trackId: "sample-track-id",
            trackName: "Bohemian Rhapsody",
            trackImageUrl: "https://example.com/image.jpg",
            trackNumber: 11,
            duration: 355000,
            friendId: "friend123",
            friendListeningTime: 1800,
            friendRatingScore: 9.2,
            friendPosition: 5,
            friendRankWithinAlbum: 1,
            friendPrestigeTier: "Gold"
        ),
        friendName: "Alex"
    )
    .padding()
}