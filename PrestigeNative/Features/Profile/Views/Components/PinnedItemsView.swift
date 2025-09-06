//
//  PinnedItemsView.swift
//  Pinned Items Grid with Drag-and-Drop Reordering
//
//  Displays pinned prestige items in a grid layout with iPhone-style 
//  drag-and-drop reordering functionality.
//

import SwiftUI

struct PinnedItemsView: View {
    @StateObject private var pinService = PinService.shared
    @State private var selectedContentType: ContentType = .tracks
    @State private var isDragging = false
    @State private var draggedItem: String? = nil
    @State private var selectedPrestige: PrestigeSelection?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Pinned Items")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Content type picker
                Picker("Content Type", selection: $selectedContentType) {
                    ForEach(ContentType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            .padding(.horizontal)
            
            // Pinned items grid
            if pinnedItems.isEmpty {
                emptyStateView
            } else {
                pinnedItemsGrid
            }
        }
        .onAppear {
            Task {
                await pinService.loadPinnedItems()
            }
        }
        .sheet(item: $selectedPrestige) { selection in
            PrestigeDetailView(
                item: selection.item,
                rank: selection.rank
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var pinnedItems: [Any] {
        switch selectedContentType {
        case .tracks:
            return pinService.orderedPinnedTracks
        case .albums:
            return pinService.orderedPinnedAlbums
        case .artists:
            return pinService.orderedPinnedArtists
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pin")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Pinned \(selectedContentType.displayName)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Pin your favorite \(selectedContentType.displayName.lowercased()) from detail views")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    private var pinnedItemsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8),
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8),
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8)
            ],
            spacing: 12
        ) {
            ForEach(Array(pinnedItems.enumerated()), id: \.offset) { index, item in
                pinnedItemCard(item: item, index: index)
                    .scaleEffect(draggedItem == getItemId(item) ? 1.05 : 1.0)
                    .opacity(draggedItem == getItemId(item) ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: draggedItem)
                    .onDrag {
                        draggedItem = getItemId(item)
                        isDragging = true
                        return NSItemProvider(object: getItemId(item) as NSString)
                    }
                    .onDrop(of: [.text], delegate: PinnedItemDropDelegate(
                        item: getItemId(item),
                        items: pinnedItems,
                        draggedItem: $draggedItem,
                        isDragging: $isDragging,
                        contentType: selectedContentType,
                        pinService: pinService,
                        onReorder: { from, to in
                            pinService.reorderPinnedItems(
                                items: pinnedItems,
                                from: IndexSet([from]),
                                to: to,
                                contentType: selectedContentType
                            )
                        }
                    ))
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func pinnedItemCard(item: Any, index: Int) -> some View {
        let displayItem = convertToDisplayItem(item: item, index: index)
        
        VStack(spacing: 8) {
            // Prestige card with draggable overlay
            ZStack {
                // Background prestige frame
                if displayItem.prestigeLevel != .none && !displayItem.prestigeLevel.imageName.isEmpty {
                    Image(displayItem.prestigeLevel.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(0.8)
                        .scaleEffect(1.1)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(spacing: 8) {
                    // Main content image
                    CachedAsyncImage(
                        url: displayItem.imageUrl,
                        placeholder: Image(systemName: getIconForType(displayItem.contentType)),
                        contentMode: .fill,
                        maxWidth: 80,
                        maxHeight: 80
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    // Prestige badge
                    PrestigeBadge(tier: displayItem.prestigeLevel, showText: false)
                        .scaleEffect(0.7)
                }
                .padding(8)
                
                // Drag indicator overlay (shows when dragging)
                if isDragging && draggedItem == displayItem.spotifyId {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Image(systemName: "hand.raised.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        )
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(radius: isDragging ? 8 : 4)
            )
            .onTapGesture {
                if !isDragging {
                    selectedPrestige = PrestigeSelection(
                        item: displayItem,
                        rank: index + 1
                    )
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                // Start drag mode with haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    draggedItem = displayItem.spotifyId
                    isDragging = true
                }
            }
            
            // Item title
            Text(displayItem.name)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getItemId(_ item: Any) -> String {
        switch selectedContentType {
        case .tracks:
            if let track = item as? UserTrackResponse {
                return track.track.id
            }
        case .albums:
            if let album = item as? UserAlbumResponse {
                return album.album.id
            }
        case .artists:
            if let artist = item as? UserArtistResponse {
                return artist.artist.id
            }
        }
        return UUID().uuidString
    }
    
    private func convertToDisplayItem(item: Any, index: Int) -> PrestigeDisplayItem {
        switch selectedContentType {
        case .tracks:
            if let track = item as? UserTrackResponse {
                return PrestigeDisplayItem.fromTrack(track)
            }
        case .albums:
            if let album = item as? UserAlbumResponse {
                return PrestigeDisplayItem.fromAlbum(album)
            }
        case .artists:
            if let artist = item as? UserArtistResponse {
                return PrestigeDisplayItem.fromArtist(artist)
            }
        }
        
        // Fallback
        return PrestigeDisplayItem(
            name: "Unknown Item",
            subtitle: "",
            imageUrl: "",
            totalTimeMilliseconds: 0,
            prestigeLevel: .none,
            spotifyId: UUID().uuidString,
            contentType: selectedContentType,
            albumPosition: nil,
            rating: nil,
            isPinned: true,
            albumId: nil,
            albumName: nil
        )
    }
    
    private func getIconForType(_ contentType: ContentType) -> String {
        switch contentType {
        case .tracks: return "music.note"
        case .albums: return "square.stack"
        case .artists: return "music.mic"
        }
    }
}

// MARK: - Drop Delegate

struct PinnedItemDropDelegate: DropDelegate {
    let item: String
    let items: [Any]
    @Binding var draggedItem: String?
    @Binding var isDragging: Bool
    let contentType: ContentType
    let pinService: PinService
    let onReorder: (Int, Int) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        defer {
            draggedItem = nil
            isDragging = false
        }
        
        guard let draggedItemId = draggedItem else { return false }
        
        // Find indices
        let fromIndex = findItemIndex(itemId: draggedItemId)
        let toIndex = findItemIndex(itemId: item)
        
        guard fromIndex != -1, toIndex != -1, fromIndex != toIndex else {
            return false
        }
        
        // Perform reorder with haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        onReorder(fromIndex, toIndex)
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItemId = draggedItem else { return }
        
        let fromIndex = findItemIndex(itemId: draggedItemId)
        let toIndex = findItemIndex(itemId: item)
        
        if fromIndex != toIndex {
            withAnimation(.easeInOut(duration: 0.3)) {
                onReorder(fromIndex, toIndex)
            }
        }
    }
    
    private func findItemIndex(itemId: String) -> Int {
        switch contentType {
        case .tracks:
            return items.compactMap { $0 as? UserTrackResponse }
                .firstIndex { $0.track.id == itemId } ?? -1
        case .albums:
            return items.compactMap { $0 as? UserAlbumResponse }
                .firstIndex { $0.album.id == itemId } ?? -1
        case .artists:
            return items.compactMap { $0 as? UserArtistResponse }
                .firstIndex { $0.artist.id == itemId } ?? -1
        }
    }
}

#Preview {
    PinnedItemsView()
}