//
//  FavoritesGridCard.swift
//  Grid card component for favorites selection
//
//  Used in both onboarding and settings to display items in grid format
//  with selection highlighting matching the main rate page style.
//

import SwiftUI

struct FavoritesGridCard: View {
    let item: SpotifyItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Artwork
                CachedAsyncImage(
                    url: item.imageUrl,
                    placeholder: Image(systemName: iconForItemType),
                    contentMode: .fill,
                    maxWidth: nil,
                    maxHeight: nil
                )
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .modifier(ImageShapeModifier(itemType: mapItemType(item.type)))
                .overlay(
                    // Selection highlight overlay
                    RoundedRectangle(cornerRadius: getCornerRadius())
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                )
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 140, maxHeight: 180) // More flexible height range for better device compatibility
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var iconForItemType: String {
        switch item.type {
        case "track": return "music.note"
        case "album": return "square.stack"
        case "artist": return "person.fill"
        default: return "music.note"
        }
    }
    
    private func mapItemType(_ type: String) -> RatingItemType {
        switch type {
        case "track": return .track
        case "album": return .album
        case "artist": return .artist
        default: return .track
        }
    }
    
    private func getCornerRadius() -> CGFloat {
        return item.type == "artist" ? 50 : 6 // Circular for artists, rounded rectangle for tracks/albums
    }
}

// Reuse the ImageShapeModifier from GridRatingCard for consistency
extension FavoritesGridCard {
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
}

#Preview {
    LazyVGrid(columns: [
        GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8),
        GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8),
        GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8)
    ], spacing: 12) {
        FavoritesGridCard(
            item: SpotifyItem(
                id: "1",
                name: "Blinding Lights",
                type: "track",
                imageUrl: nil,
                subtitle: "The Weeknd"
            ),
            isSelected: true,
            onTap: {}
        )
        
        FavoritesGridCard(
            item: SpotifyItem(
                id: "2",
                name: "Future Nostalgia",
                type: "album",
                imageUrl: nil,
                subtitle: "Dua Lipa"
            ),
            isSelected: false,
            onTap: {}
        )
        
        FavoritesGridCard(
            item: SpotifyItem(
                id: "3",
                name: "Taylor Swift",
                type: "artist",
                imageUrl: nil,
                subtitle: "Artist"
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}