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
                // Artwork - constrained sizing for better grid layout
                CachedAsyncImage(
                    url: itemData.imageUrl,
                    placeholder: Image(systemName: iconForItemType),
                    contentMode: .fill,
                    maxWidth: imageSize,
                    maxHeight: imageSize
                )
                .aspectRatio(1, contentMode: .fill)
                .frame(width: imageSize, height: imageSize)
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
            .frame(minHeight: cardHeight) // Device-specific minimum height
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
    
    // Device-specific image sizing based on actual device widths
    private var imageSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        switch screenWidth {
        case ..<380:    // iPhone SE (375)
            return 85
        case 380..<400: // iPhone 12/13/14/15 mini (375), iPhone 12/13 Pro, iPhone 14/15 (390-393)
            return 95  // Smaller images for iPhone 12 to prevent overlap
        case 400..<420: // iPhone 16 Pro (402), iPhone 11/XR (414)
            return 105
        case 420..<435: // iPhone 12/13/14/15 Pro Max/Plus (428-430)
            return 115
        default:        // iPhone 16 Pro Max (440+)
            return 125  // Larger images for bigger screens
        }
    }
    
    // Device-specific card height based on actual device widths
    private var cardHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        switch screenWidth {
        case ..<380:    // iPhone SE (375)
            return 135
        case 380..<400: // iPhone 12/13/14/15 mini (375), iPhone 12/13 Pro, iPhone 14/15 (390-393)
            return 145
        case 400..<420: // iPhone 16 Pro (402), iPhone 11/XR (414)
            return 155
        case 420..<435: // iPhone 12/13/14/15 Pro Max/Plus (428-430)
            return 165
        default:        // iPhone 16 Pro Max (440+)
            return 175
        }
    }
}

struct ImageShapeModifier: ViewModifier {
    let itemType: RatingItemType
    
    func body(content: Content) -> some View {
        // Use consistent rounded rectangle shape for all content types
        content.clipShape(RoundedRectangle(cornerRadius: 6))
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