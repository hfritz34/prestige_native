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
    @State private var isDeleting = false
    
    private let swipeThreshold: CGFloat = 80
    private let maxSwipeDistance: CGFloat = 120
    
    var body: some View {
        ZStack {
            // Background action layers with proper rounded corners
            HStack(spacing: 0) {
                // Left swipe action (Re-rate) - Blue
                if offset > 0 {
                    HStack(spacing: 8) {
                        Spacer()
                        
                        Image(systemName: "star.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        if offset > 60 {
                            Text("Rate Again")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        Spacer()
                    }
                    .frame(width: min(offset, maxSwipeDistance))
                    .frame(maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                    .clipped()
                }
                
                Spacer()
                
                // Right swipe action (Delete) - Red
                if offset < 0 {
                    HStack(spacing: 8) {
                        Spacer()
                        
                        if -offset > 60 {
                            Text("Delete")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .frame(width: min(-offset, maxSwipeDistance))
                    .frame(maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                    )
                    .clipped()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Main content
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
            .opacity(isDeleting ? 0.0 : 1.0)
            .onTapGesture {
                if !isDragging && abs(offset) < 5 {
                    onTap?()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        let translation = value.translation
                        
                        // Ultra-strict horizontal detection - only swipe if VERY clearly horizontal
                        if !isDragging {
                            let horizontalMovement = abs(translation.width)
                            let verticalMovement = abs(translation.height)
                            
                            // Extremely strict conditions for starting horizontal swipe:
                            // 1. Must have moved at least 40 points horizontally
                            // 2. Horizontal must be at least 4x vertical movement  
                            // 3. Vertical movement must be under 10 points
                            if horizontalMovement > 40 && 
                               horizontalMovement > verticalMovement * 4 && 
                               verticalMovement < 10 {
                                isDragging = true
                            } else {
                                // Any other movement pattern = don't interfere with scrolling
                                return
                            }
                        }
                        
                        if isDragging {
                            // Apply resistance at the edges with smoother curve
                            let rawOffset = translation.width
                            let resistance: CGFloat = 0.4
                            
                            if rawOffset > 0 {
                                offset = rawOffset > maxSwipeDistance ? 
                                    maxSwipeDistance + (rawOffset - maxSwipeDistance) * resistance :
                                    rawOffset
                            } else {
                                offset = -rawOffset > maxSwipeDistance ?
                                    -(maxSwipeDistance + (-rawOffset - maxSwipeDistance) * resistance) :
                                    rawOffset
                            }
                            
                            // Haptic feedback at threshold (only once per direction)
                            if !actionTriggered && abs(offset) > swipeThreshold {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                actionTriggered = true
                            } else if actionTriggered && abs(offset) <= swipeThreshold {
                                actionTriggered = false
                            }
                        }
                    }
                    .onEnded { value in
                        guard isDragging else { return }
                        
                        let velocity = value.velocity.width
                        let translation = value.translation.width
                        
                        // More responsive action triggering
                        let shouldTriggerAction = abs(translation) > swipeThreshold || abs(velocity) > 800
                        
                        if shouldTriggerAction {
                            if translation > 0 {
                                // Re-rate action - smooth reset
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                    offset = 0
                                    isDragging = false
                                    actionTriggered = false
                                }
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onRerate?()
                                }
                            } else {
                                // Delete action - smooth slide out with fade
                                isDeleting = true
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                    offset = -UIScreen.main.bounds.width
                                }
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDelete?()
                                }
                            }
                        } else {
                            // Reset position smoothly
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                offset = 0
                                isDragging = false
                                actionTriggered = false
                            }
                        }
                    }
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDragging)
        .animation(.easeInOut(duration: 0.3), value: isDeleting)
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
                        albumId: nil,
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
                        rankWithinAlbum: nil,
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