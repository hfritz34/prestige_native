//
//  ComparisonView.swift
//  Comparison View for Rating Flow
//
//  Side-by-side comparison interface for determining item position
//  through pairwise comparisons with existing rated items
//

import SwiftUI
import UIKit

struct ComparisonView: View {
    let newItem: RatingItemData
    let comparisonItem: RatingItemData
    let progress: (current: Int, total: Int)
    let onSelection: (String) -> Void
    let onSkip: () -> Void
    
    @State private var selectedItemId: String?
    @State private var showVersus = true
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress Indicator
            progressHeader
            
            // Comparison Content
            comparisonContent
            
            // Action Buttons
            actionButtons
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                showVersus = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text("Which do you prefer?")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 4) {
                Text("Comparison")
                    .foregroundColor(.secondary)
                Text("\(progress.current)")
                    .fontWeight(.semibold)
                Text("of")
                    .foregroundColor(.secondary)
                Text("\(progress.total)")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(
                            width: geometry.size.width * (Double(progress.current) / Double(progress.total)),
                            height: 8
                        )
                        .animation(.spring(), value: progress.current)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var comparisonContent: some View {
        HStack(spacing: 16) {
            // New Item (Left)
            ComparisonCard(
                itemData: newItem,
                isSelected: selectedItemId == newItem.id,
                isNew: true,
                onTap: {
                    withHapticFeedback {
                        selectedItemId = newItem.id
                        onSelection(newItem.id)
                    }
                }
            )
            .matchedGeometryEffect(id: "item-\(newItem.id)", in: animation)
            
            // VS Divider
            if showVersus {
                VersusIndicator()
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Comparison Item (Right)
            ComparisonCard(
                itemData: comparisonItem,
                isSelected: selectedItemId == comparisonItem.id,
                isNew: false,
                onTap: {
                    withHapticFeedback {
                        selectedItemId = comparisonItem.id
                        onSelection(comparisonItem.id)
                    }
                }
            )
            .matchedGeometryEffect(id: "item-\(comparisonItem.id)", in: animation)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: onSkip) {
                Text("Can't Decide")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Comparison Card

struct ComparisonCard: View {
    let itemData: RatingItemData
    let isSelected: Bool
    let isNew: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // New Badge
                if isNew {
                    Text("NEW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue))
                }
                
                // Artwork
                AsyncImage(url: URL(string: itemData.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: iconForItemType)
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: isSelected ? 8 : 4)
                
                // Metadata
                VStack(spacing: 4) {
                    Text(itemData.name)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let artists = itemData.artists {
                        Text(artists.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if itemData.itemType == .track, let albumName = itemData.albumName {
                        Text(albumName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.blue : Color.clear,
                                lineWidth: isSelected ? 3 : 0
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.02 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var iconForItemType: String {
        switch itemData.itemType {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "person.fill"
        }
    }
}

// MARK: - Versus Indicator

struct VersusIndicator: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .shadow(radius: 4)
            
            Text("VS")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .rotation3DEffect(
            Angle(degrees: rotation),
            axis: (x: 0, y: 1, z: 0)
        )
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
            ) {
                rotation = 360
            }
        }
    }
}

// MARK: - Swipe Comparison View

struct SwipeComparisonView: View {
    let items: [RatingItemData]
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    let onComparison: (String, String, String) -> Void
    
    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index == currentIndex {
                    ComparisonSwipeCard(
                        itemData: item,
                        dragOffset: $dragOffset,
                        onSwipe: { direction in
                            handleSwipe(direction: direction, for: item)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        }
        .overlay(alignment: .top) {
            HStack(spacing: 40) {
                SwipeHint(text: "Worse", icon: "hand.thumbsdown.fill", color: .red)
                SwipeHint(text: "Better", icon: "hand.thumbsup.fill", color: .green)
            }
            .padding(.top, 20)
            .opacity(0.6)
        }
    }
    
    private func handleSwipe(direction: SwipeDirection, for item: RatingItemData) {
        // Implementation for handling swipe comparisons
        if currentIndex < items.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        }
    }
}

enum SwipeDirection {
    case left, right
}

struct ComparisonSwipeCard: View {
    let itemData: RatingItemData
    @Binding var dragOffset: CGSize
    let onSwipe: (SwipeDirection) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        RatingItemCard(itemData: itemData, rating: nil, showRating: false)
            .offset(dragOffset)
            .rotationEffect(Angle(degrees: Double(dragOffset.width) / 20))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        if abs(value.translation.width) > 100 {
                            withAnimation(.spring()) {
                                if value.translation.width > 0 {
                                    onSwipe(.right)
                                } else {
                                    onSwipe(.left)
                                }
                                dragOffset = .zero
                            }
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .animation(.spring(), value: dragOffset)
    }
}

struct SwipeHint: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Haptic Feedback

private func withHapticFeedback<T>(_ action: () -> T) -> T {
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
    return action()
}

// MARK: - Preview

#Preview("Comparison View") {
    ComparisonView(
        newItem: RatingItemData(
            id: "new",
            name: "New Song",
            imageUrl: nil,
            artists: ["Artist A"],
            albumName: "New Album",
            itemType: .track
        ),
        comparisonItem: RatingItemData(
            id: "existing",
            name: "Existing Song",
            imageUrl: nil,
            artists: ["Artist B"],
            albumName: "Existing Album",
            itemType: .track
        ),
        progress: (current: 3, total: 10),
        onSelection: { _ in },
        onSkip: {}
    )
}