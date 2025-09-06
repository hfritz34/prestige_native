//
//  GridRatingCard.swift
//  Grid layout rating card component
//

import SwiftUI

struct GridRatingCard: View {
    let itemData: RatingItemData
    let rating: Rating?
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Artwork
                CachedAsyncImage(
                    url: itemData.imageUrl,
                    placeholder: Image(systemName: iconForItemType),
                    contentMode: .fill,
                    maxWidth: nil,
                    maxHeight: nil
                )
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 130, height: 130)
                .clipped()
                .modifier(ImageShapeModifier(itemType: itemData.itemType))
                .overlay(
                    // Rating badge overlay - show position for tracks, score for albums/artists
                    Group {
                        if let rating = rating {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    if itemData.itemType == .track {
                                        // Show position for tracks
                                        PositionBadge(position: rating.position, size: .small)
                                            .padding(6)
                                    } else {
                                        // Show rating for albums/artists
                                        RatingBadge(score: rating.personalScore, size: .small)
                                            .padding(6)
                                    }
                                }
                            }
                        }
                    }
                )
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 1) {
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
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            if let rating = rating {
                Button(action: onTap) {
                    Label("Rate Again", systemImage: "star.circle")
                }
                
                if let onDelete = onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove Rating", systemImage: "trash")
                    }
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

struct ImageShapeModifier: ViewModifier {
    let itemType: RatingItemType
    
    func body(content: Content) -> some View {
        if itemType == .artist {
            content.clipShape(Circle())
        } else {
            content.clipShape(RoundedRectangle(cornerRadius: 6))
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
            onTap: {},
            onDelete: {}
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
            onTap: {},
            onDelete: nil
        )
    }
    .padding()
}