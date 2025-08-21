//
//  RatingItemCard.swift
//  Rating Item Card Component
//
//  Card component for displaying track/album/artist items
//  with artwork, metadata, and rating information
//

import SwiftUI
import Foundation

struct RatingItemCard: View {
    let itemData: RatingItemData
    let rating: Rating?
    let showRating: Bool
    let onTap: (() -> Void)?
    let onSwipeRight: (() -> Void)?
    let onSwipeLeft: (() -> Void)?
    
    init(
        itemData: RatingItemData,
        rating: Rating? = nil,
        showRating: Bool = true,
        onTap: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        onSwipeLeft: (() -> Void)? = nil
    ) {
        self.itemData = itemData
        self.rating = rating
        self.showRating = showRating
        self.onTap = onTap
        self.onSwipeRight = onSwipeRight
        self.onSwipeLeft = onSwipeLeft
    }
    
    private var subtitle: String {
        switch itemData.itemType {
        case .track:
            return itemData.artists?.joined(separator: ", ") ?? ""
        case .album:
            return itemData.artists?.joined(separator: ", ") ?? ""
        case .artist:
            return "Artist"
        }
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Artwork
                CachedAsyncImage(
                    url: itemData.imageUrl,
                    placeholder: Image(systemName: iconForItemType),
                    contentMode: .fill,
                    maxWidth: 64,
                    maxHeight: 64
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(itemData.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    // Subtitle
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    
                    // Album name for tracks
                    if itemData.itemType == .track, let albumName = itemData.albumName {
                        Text(albumName)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Rating Badge
                if showRating, let rating = rating {
                    RatingIndicator(rating: rating)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    // Only treat as swipe if mostly horizontal to avoid fighting vertical scrolling
                    guard abs(dx) > abs(dy), abs(dx) > 80 else { return }
                    if dx > 0 { onSwipeRight?() } else { onSwipeLeft?() }
                }
        )
    }
    
    private var iconForItemType: String {
        switch itemData.itemType {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "person.fill"
        }
    }
}

// MARK: - Rating Indicator

struct RatingIndicator: View {
    let rating: Rating
    
    private var color: Color {
        if let colorHex = rating.category?.colorHex {
            return Color(hex: colorHex) ?? .gray
        }
        
        // Fallback based on score
        if rating.personalScore >= 7 {
            return .green
        } else if rating.personalScore >= 4 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var emoji: String {
        rating.category?.emoji ?? {
            if rating.personalScore >= 7 {
                return "⭐"
            } else if rating.personalScore >= 4 {
                return "👍"
            } else {
                return "👎"
            }
        }()
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(emoji)
                .font(.title2)
            
            Text(rating.displayScore)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Compact Item Row

struct CompactRatingItemRow: View {
    let itemData: RatingItemData
    let rating: Rating?
    let showPosition: Bool
    let onTap: (() -> Void)?
    
    init(
        itemData: RatingItemData,
        rating: Rating? = nil,
        showPosition: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.itemData = itemData
        self.rating = rating
        self.showPosition = showPosition
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // Position number
                if showPosition, let position = rating?.position {
                    Text("\(position + 1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                }
                
                // Artwork
                AsyncImage(url: URL(string: itemData.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(itemData.name)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    if let artists = itemData.artists {
                        Text(artists.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Score
                if let rating = rating {
                    Text(rating.displayScore)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(scoreColor(for: rating.personalScore))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 7 {
            return .green
        } else if score >= 4 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Loading Card

struct RatingItemLoadingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 64, height: 64)
                .shimmering()
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 16)
                    .shimmering()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 12)
                    .shimmering()
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Preview

#Preview("Item Cards") {
    VStack(spacing: 16) {
        RatingItemCard(
            itemData: RatingItemData(
                id: "1",
                name: "Blinding Lights",
                imageUrl: nil,
                artists: ["The Weeknd"],
                albumName: "After Hours",
                itemType: .track
            ),
            rating: Rating(
                itemId: "1",
                itemType: .track,
                albumId: nil,
                categoryId: 1,
                category: RatingCategoryModel(
                    id: 1,
                    name: "Loved",
                    minScore: 6.8,
                    maxScore: 10.0,
                    colorHex: "#22c55e",
                    displayOrder: 1
                ),
                position: 0,
                personalScore: 9.5,
                rankWithinAlbum: nil,
                isNewRating: false
            )
        )
        
        CompactRatingItemRow(
            itemData: RatingItemData(
                id: "2",
                name: "Starboy",
                imageUrl: nil,
                artists: ["The Weeknd", "Daft Punk"],
                albumName: nil,
                itemType: .track
            ),
            rating: Rating(
                itemId: "2",
                itemType: .track,
                albumId: nil,
                categoryId: 2,
                category: nil,
                position: 5,
                personalScore: 5.2,
                rankWithinAlbum: nil,
                isNewRating: false
            ),
            showPosition: true
        )
        
        RatingItemLoadingCard()
    }
    .padding()
}