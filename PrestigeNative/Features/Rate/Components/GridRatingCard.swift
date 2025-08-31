//
//  GridRatingCard.swift
//  Grid layout rating card component
//

import SwiftUI

struct GridRatingCard: View {
    let itemData: RatingItemData
    let rating: Rating?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Artwork
                CachedAsyncImage(
                    url: itemData.imageUrl,
                    placeholder: Image(systemName: iconForItemType),
                    contentMode: .fill,
                    maxWidth: nil,
                    maxHeight: nil
                )
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    // Rating badge overlay
                    Group {
                        if let rating = rating {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    RatingBadge(score: rating.personalScore, size: .small)
                                        .padding(6)
                                }
                            }
                        }
                    }
                )
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(itemData.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    if let subtitle = getSubtitle() {
                        Text(subtitle)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(
                ZStack {
                    Color(UIColor.systemBackground)
                        .opacity(0.8)
                    Color.white.opacity(0.05)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
            )
            .cornerRadius(12)
            .shadow(color: Theme.shadowLight, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            if let rating = rating {
                Button(action: onTap) {
                    Label("Rate Again", systemImage: "star.circle")
                }
                
                Button(role: .destructive) {
                    // Note: We'd need to pass in the delete action for this to work
                    Label("Remove Rating", systemImage: "trash")
                } label: {
                    Label("Remove Rating", systemImage: "trash")
                }
            } else {
                Button(action: onTap) {
                    Label("Rate", systemImage: "star")
                }
            }
        }
    }
    
    private var iconForItemType: String {
        switch itemData.itemType {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "person.fill"
        }
    }
    
    private func getSubtitle() -> String? {
        switch itemData.itemType {
        case .track:
            return itemData.artists?.joined(separator: ", ")
        case .album:
            return itemData.artists?.joined(separator: ", ")
        case .artist:
            return "Artist"
        }
    }
}

// Preview
#Preview {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 12) {
        GridRatingCard(
            itemData: RatingItemData(
                id: "1",
                name: "Blinding Lights",
                imageUrl: nil,
                artists: ["The Weeknd"],
                albumName: "After Hours",
                albumId: nil,
                itemType: .track
            ),
            rating: Rating(
                itemId: "1",
                itemType: .track,
                albumId: nil,
                categoryId: 1,
                category: nil,
                position: 0,
                personalScore: 9.5,
                rankWithinAlbum: nil,
                isNewRating: false
            ),
            onTap: {}
        )
        
        GridRatingCard(
            itemData: RatingItemData(
                id: "2",
                name: "Future Nostalgia",
                imageUrl: nil,
                artists: ["Dua Lipa"],
                albumName: nil,
                albumId: nil,
                itemType: .album
            ),
            rating: nil,
            onTap: {}
        )
    }
    .padding()
}