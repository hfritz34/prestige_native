//
//  PrestigeGridCard.swift
//  Grid-style prestige card for 3-column layout
//
//  Square design with prestige tier framing the artwork and small rank indicator.
//

import SwiftUI

struct PrestigeGridCard: View {
    let item: PrestigeDisplayItem
    let rank: Int
    
    init(item: PrestigeDisplayItem, rank: Int) {
        self.item = item
        self.rank = rank
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Main card with artwork and prestige frame
            ZStack {
                // Background container with proper clipping
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .overlay(
                        Group {
                            // Prestige tier background image
                            if item.prestigeLevel != .none && !item.prestigeLevel.imageName.isEmpty {
                                Image(item.prestigeLevel.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(0.35)
                            }
                            
                            // Color overlay for better contrast
                            LinearGradient(
                                colors: [
                                    Color(hex: item.prestigeLevel.color)?.opacity(0.3) ?? Color.gray.opacity(0.3),
                                    Color(hex: item.prestigeLevel.color)?.opacity(0.1) ?? Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color(hex: item.prestigeLevel.color) ?? Color.gray,
                                lineWidth: 2
                            )
                    )
                
                VStack(spacing: 8) {
                    // Rank badge and rating/position
                    HStack {
                        Text("\(rank)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.black.opacity(0.7)))
                        
                        Spacer()
                        
                        // Show album position for tracks, rating for albums/artists
                        if item.contentType == .tracks, let position = item.albumPosition {
                            HStack(spacing: 2) {
                                Text("🏆")
                                    .font(.caption2)
                                Text("#\(position)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                        } else if item.contentType != .tracks, let rating = item.rating {
                            HStack(spacing: 2) {
                                Image(systemName: rating >= 7 ? "star.fill" : rating >= 4 ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                    .font(.caption2)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(rating >= 7 ? .green : rating >= 4 ? .yellow : .red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                        }
                    }
                    
                    // Album artwork
                    CachedAsyncImage(
                        url: item.imageUrl,
                        placeholder: Image(systemName: getIconForType()),
                        contentMode: .fill,
                        maxWidth: 80,
                        maxHeight: 80
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    // Prestige badge
                    PrestigeBadge(tier: item.prestigeLevel)
                        .scaleEffect(0.8)
                }
                .padding(8)
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Title and subtitle
            VStack(spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(item.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(TimeFormatter.formatListeningTime(item.totalTimeMilliseconds))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: item.prestigeLevel.color) ?? .blue)
            }
        }
    }
    
    private func getIconForType() -> String {
        if item.subtitle == "Artist" {
            return "music.mic"
        } else if item.subtitle.contains("tracks") || item.name.contains("Album") {
            return "square.stack"
        } else {
            return "music.note"
        }
    }
}


#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
        ForEach(0..<9) { index in
            PrestigeGridCard(
                item: PrestigeDisplayItem(
                    name: "Sample Track \(index + 1)",
                    subtitle: "Sample Artist",
                    imageUrl: "",
                    totalTimeMilliseconds: (index + 1) * 120000,
                    prestigeLevel: [.bronze, .silver, .gold, .diamond][index % 4],
                    spotifyId: "sample-track-\(index + 1)",
                    contentType: .tracks,
                    albumPosition: index + 1,
                    rating: Double(7 + index % 3),
                    isPinned: index % 3 == 0,
                    albumId: nil,
                    albumName: nil
                ),
                rank: index + 1
            )
        }
    }
    .padding()
}