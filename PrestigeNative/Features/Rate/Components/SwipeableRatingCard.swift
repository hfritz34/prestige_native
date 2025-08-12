//
//  SwipeableRatingCard.swift
//  Enhanced swipeable rating card with reliable swipe actions
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
    @State private var actionTriggered = false
    
    private let swipeThreshold: CGFloat = 80
    private let maxSwipeDistance: CGFloat = 120
    
    var body: some View {
        ZStack {
            // Background action layers
            HStack(spacing: 0) {
                // Left swipe action (Re-rate) - Blue
                if offset > 0 {
                    HStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        if offset > swipeThreshold {
                            Text("Re-rate")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .frame(width: min(offset, maxSwipeDistance))
                    .frame(maxHeight: .infinity)
                    .background(Color.blue)
                    .padding(.leading, 16)
                }
                
                Spacer()
                
                // Right swipe action (Delete) - Red
                if offset < 0 {
                    HStack(spacing: 12) {
                        Spacer()
                        
                        if -offset > swipeThreshold {
                            Text("Delete")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .frame(width: min(-offset, maxSwipeDistance))
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .padding(.trailing, 16)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Main content
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
                    Text(itemData.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    if let artists = itemData.artists, !artists.isEmpty {
                        Text(artists.joined(separator: ", "))
                            .font(.subheadline)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    
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
                        radius: isDragging ? 6 : 3,
                        x: 0,
                        y: isDragging ? 3 : 1
                    )
            )
            .offset(x: offset)
            .scaleEffect(isDragging ? 0.98 : 1.0)
            .onTapGesture {
                if !isDragging && abs(offset) < 5 {
                    onTap?()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only start dragging if the gesture is more horizontal than vertical
                        let translation = value.translation
                        if !isDragging {
                            let isHorizontal = abs(translation.width) > abs(translation.height)
                            let hasSignificantMovement = abs(translation.width) > 15
                            
                            if isHorizontal && hasSignificantMovement {
                                isDragging = true
                            } else if abs(translation.height) > 15 {
                                // Vertical movement detected, don't start dragging
                                return
                            }
                        }
                        
                        if isDragging {
                            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                                // Apply resistance at the edges
                                let rawOffset = translation.width
                                if rawOffset > 0 {
                                    offset = min(rawOffset * (rawOffset > maxSwipeDistance ? 0.3 : 1.0), maxSwipeDistance * 1.2)
                                } else {
                                    offset = max(rawOffset * (-rawOffset > maxSwipeDistance ? 0.3 : 1.0), -maxSwipeDistance * 1.2)
                                }
                                
                                // Haptic feedback at threshold
                                if !actionTriggered && abs(offset) > swipeThreshold {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    actionTriggered = true
                                } else if actionTriggered && abs(offset) <= swipeThreshold {
                                    actionTriggered = false
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        guard isDragging else { return }
                        
                        let velocity = value.velocity.width
                        let translation = value.translation.width
                        
                        // Determine if action should be triggered
                        let shouldTriggerAction = abs(translation) > swipeThreshold || abs(velocity) > 500
                        
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            if shouldTriggerAction {
                                if translation > 0 {
                                    // Re-rate action
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    onRerate?()
                                } else {
                                    // Delete action
                                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                    onDelete?()
                                }
                            }
                            
                            // Reset position
                            offset = 0
                            isDragging = false
                            actionTriggered = false
                        }
                    }
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDragging)
    }
    
    private var iconForItemType: String {
        switch itemData.itemType {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "person.fill"
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(0..<10) { index in
                SwipeableRatingCard(
                    itemData: RatingItemData(
                        id: "\(index)",
                        name: "Sample Track \(index + 1)",
                        imageUrl: nil,
                        artists: ["Artist \(index + 1)"],
                        albumName: "Album \(index + 1)",
                        itemType: .track
                    ),
                    rating: Rating(
                        itemId: "\(index)",
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
                        position: index,
                        personalScore: 8.5,
                        isNewRating: false
                    ),
                    showRating: true,
                    onTap: { print("Tapped \(index)") },
                    onRerate: { print("Re-rate \(index)") },
                    onDelete: { print("Delete \(index)") }
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}