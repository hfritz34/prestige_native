//
//  SwipeableRatingCard.swift
//  Enhanced swipeable rating card with Spotify-like animations
//

import SwiftUI

struct SwipeableRatingCard: View {
    let itemData: RatingItemData
    let rating: Rating?
    let showRating: Bool
    let onTap: (() -> Void)?
    let onRerate: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var hasTriggeredAction = false
    
    private let swipeThreshold: CGFloat = 100
    private let maxSwipeDistance: CGFloat = 150
    
    var body: some View {
        ZStack {
            // Background actions layer
            HStack(spacing: 0) {
                // Right swipe action (Re-rate)
                HStack {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.leading, 20)
                    
                    if offset > swipeThreshold {
                        Text("Re-rate")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Left swipe action (Delete)
                HStack {
                    Spacer()
                    
                    if offset < -swipeThreshold {
                        Text("Delete")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.trailing, 20)
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Main card content
            Button(action: { onTap?() }) {
                HStack(spacing: 12) {
                    // Artwork
                    AsyncImage(url: URL(string: itemData.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: iconForItemType)
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(itemData.name)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        // Artists
                        if let artists = itemData.artists, !artists.isEmpty {
                            Text(artists.joined(separator: ", "))
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
                        .shadow(
                            color: Color.black.opacity(isDragging ? 0.15 : 0.05),
                            radius: isDragging ? 8 : 4,
                            x: 0,
                            y: isDragging ? 4 : 2
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: offset)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: isDragging)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.86, blendDuration: 0.25)) {
                            isDragging = true
                            
                            // Limit swipe distance
                            let translation = value.translation.width
                            if translation > 0 {
                                offset = min(translation, maxSwipeDistance)
                            } else {
                                offset = max(translation, -maxSwipeDistance)
                            }
                            
                            // Haptic feedback at threshold
                            if !hasTriggeredAction {
                                if abs(offset) > swipeThreshold {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    hasTriggeredAction = true
                                }
                            } else if abs(offset) < swipeThreshold {
                                hasTriggeredAction = false
                            }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isDragging = false
                            
                            if offset > swipeThreshold {
                                // Trigger re-rate action
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                onRerate?()
                            } else if offset < -swipeThreshold {
                                // Trigger delete action
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                onDelete?()
                            }
                            
                            // Reset position
                            offset = 0
                            hasTriggeredAction = false
                        }
                    }
            )
        }
    }
    
    private var iconForItemType: String {
        switch itemData.itemType {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "person.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SwipeableRatingCard(
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
                isNewRating: false
            ),
            showRating: true,
            onTap: { print("Tapped") },
            onRerate: { print("Re-rate") },
            onDelete: { print("Delete") }
        )
        .padding(.horizontal)
    }
}