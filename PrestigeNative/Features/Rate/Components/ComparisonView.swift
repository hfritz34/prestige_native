//
//  ComparisonView.swift
//  Comparison View for Rating Flow
//
//  Side-by-side comparison interface for determining item position
//  through pairwise comparisons with existing rated items
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ComparisonView: View {
    let newItem: RatingItemData
    let comparisonItem: RatingItemData
    let progress: (current: Int, total: Int)
    let onSelection: (String) -> Void
    let onSkip: () -> Void
    
    @State private var selectedItemId: String?
    @State private var showVersus = true
    @State private var selectionAnimation = false
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress Indicator
            progressHeader
            
            // Comparison Content
            comparisonContent
            
            // Removed Can't Decide button per user request
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
        VStack(spacing: 12) {
            Text("Which do you prefer?")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 6) {
                Text("Step")
                    .foregroundColor(.secondary)
                Text("\(progress.current)")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                Text("of")
                    .foregroundColor(.secondary)
                Text("\(progress.total)")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .font(.footnote)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (Double(progress.current) / Double(progress.total)),
                            height: 6
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress.current)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var comparisonContent: some View {
        HStack(spacing: 20) {
            // New Item (Left)
            ComparisonCard(
                itemData: newItem,
                isSelected: selectedItemId == newItem.id,
                isNew: true,
                onTap: {
                    withHapticFeedback {
                        selectedItemId = newItem.id
                        triggerSelectionAnimation()
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
                        triggerSelectionAnimation()
                        onSelection(comparisonItem.id)
                    }
                }
            )
            .matchedGeometryEffect(id: "item-\(comparisonItem.id)", in: animation)
        }
    }
    
    // Can't Decide button removed per user request
    
    private func triggerSelectionAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            selectionAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectionAnimation = false
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
    @State private var showSelectionRing = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // NEW Badge positioned above artwork
                if isNew {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("NEW")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                } else {
                    // Spacer to maintain consistent layout
                    Spacer()
                        .frame(height: 28) // Match badge height
                }
                
                // Artwork
                CachedAsyncImage(
                    url: itemData.imageUrl,
                    placeholder: Image(systemName: iconForItemType),
                    contentMode: .fill,
                    maxWidth: 120,
                    maxHeight: 120
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: isSelected ? 8 : 4)
                
                // Metadata
                VStack(spacing: 4) {
                    Text(itemData.name)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    if let artists = itemData.artists, !artists.isEmpty {
                        Text(artists.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if itemData.itemType == .track, let albumName = itemData.albumName {
                        Text(albumName)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .frame(height: 50) // Fixed height for consistent alignment
            }
            .padding()
            .background(
                ZStack {
                    // Selection ring animation
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .scaleEffect(showSelectionRing ? 1.05 : 1.0)
                            .opacity(showSelectionRing ? 0 : 1)
                            .animation(.easeOut(duration: 0.5), value: showSelectionRing)
                    }
                    
                    // Main background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? Color.blue : Color.clear,
                                    lineWidth: isSelected ? 3 : 0
                                )
                        )
                }
            )
            .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.02 : 1.0))
            .onChange(of: isSelected) { oldValue, newValue in
                if newValue {
                    showSelectionRing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showSelectionRing = false
                    }
                }
            }
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

public struct VersusIndicator: View {
    @State private var pulseScale: CGFloat = 1.0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .blur(radius: 8)
                .scaleEffect(pulseScale)
            
            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            Text("VS")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .onAppear {
            // Subtle pulse animation
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.15
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
            albumId: nil,
            itemType: .track
        ),
        comparisonItem: RatingItemData(
            id: "existing",
            name: "Existing Song",
            imageUrl: nil,
            artists: ["Artist B"],
            albumName: "Existing Album",
            albumId: nil,
            itemType: .track
        ),
        progress: (current: 3, total: 10),
        onSelection: { _ in },
        onSkip: {}
    )
}