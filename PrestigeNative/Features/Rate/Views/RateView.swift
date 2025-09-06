//
//  RateView.swift
//  Rating View - Main rating interface
//
//  Provides a clean, native iOS interface for rating and managing
//  user's music library with search, filtering, and rating actions.
//

import SwiftUI

struct RateView: View {
    @StateObject private var viewModel = RatingViewModel()
    @StateObject private var imagePreloader = ImagePreloader.shared
    @State private var searchText = ""
    @State private var selectedTab: RatingTab = .unrated
    @EnvironmentObject var authManager: AuthManager
    @State private var unratedLimit: Int = 50
    @State private var topRatedLimit: Int = 50
    @State private var yourRatingsLimit: Int = 50
    @State private var searchLimit: Int = 50
    @State private var isGridView: Bool = true
    
    // Performance optimization: Cache computed properties
    @State private var cachedTopRatedItems: [RatedItem] = []
    @State private var cachedAllRatedItems: [RatedItem] = []
    @State private var lastRatingsUpdateTime: Date = Date()
    @State private var isCacheReady = false
    @State private var hasInitialLoad = false
    
    // Adaptive grid columns based on screen width
    private var adaptiveGridColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8),
            GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8),
            GridItem(.flexible(minimum: 100, maximum: 140), spacing: 8)
        ]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                headerSection
                
                // Item type filter
                itemTypeFilter
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                contentSection
                    .id(selectedTab)
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemBackground))
            .onAppear {
                // Preload images for better performance
                Task {
                    await MainActor.run {
                        preloadRatingImages()
                    }
                }
            }
            .onChange(of: viewModel.selectedItemType) { _, _ in
                // Preload images when item type changes
                Task {
                    await MainActor.run {
                        preloadRatingImages()
                    }
                }
            }
            .sheet(
                isPresented: Binding<Bool>(
                    get: { viewModel.showRatingModal },
                    set: { viewModel.showRatingModal = $0 }
                )
            ) {
                RatingModal()
                    .environmentObject(viewModel)
            }
        }
        .onAppear {
            // Inject AuthManager and then load data (prevents missing user ID issues)
            viewModel.setAuthManager(authManager)
            Task {
                await viewModel.loadInitialData()
                await viewModel.ensureMetadataLoaded()
                // Force an update of cached ratings to ensure everything is ready
                updateCachedRatings()
            }
        }
        .dynamicTypeSize(.medium)
        .onChange(of: viewModel.filteredRatings) { oldValue, newValue in
            updateCachedRatings()
        }
        .onChange(of: viewModel.selectedItemType) { oldValue, newValue in
            updateCachedRatings()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rate")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Grid/List toggle button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isGridView.toggle()
                    }
                }) {
                    Image(systemName: isGridView ? "rectangle.grid.2x2" : "list.bullet")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color(UIColor.systemBackground).opacity(0.8))
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                        .shadow(color: Theme.shadowLight, radius: 3, x: 0, y: 2)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search your library...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                    .onChange(of: searchText) { oldValue, newValue in
                        Task { await viewModel.searchLibrary(query: newValue) }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.clearSearch()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                } else {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)
        }
    }
    
    private var itemTypeFilter: some View {
        HStack(spacing: 12) {
            ForEach(RatingItemType.allCases, id: \.self) { itemType in
                ItemTypeButton(
                    itemType: itemType,
                    isSelected: viewModel.selectedItemType == itemType,
                    action: {
                        // Don't do anything if already selected
                        guard itemType != viewModel.selectedItemType else { return }
                        
                        // Immediately update UI state for instant feedback
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.selectedItemType = itemType
                            viewModel.isLoading = true
                            viewModel.loadingMessage = "Loading \(itemType.displayName.lowercased())..."
                            print("🔄 Setting loading state: isLoading=\(viewModel.isLoading), message=\(viewModel.loadingMessage)")
                        }
                        
                        // Clear cache immediately to prevent showing stale data
                        cachedTopRatedItems = []
                        cachedAllRatedItems = []
                        isCacheReady = false
                        
                        Task {
                            print("📥 Starting data load for \(itemType.displayName)")
                            
                            // Load data for the new type (without changing selectedItemType again)
                            await viewModel.loadUserRatings()
                            print("✅ loadUserRatings complete")
                            
                            await viewModel.loadUnratedItems()
                            print("✅ loadUnratedItems complete: \(viewModel.unratedItems.count) items")
                            
                            await viewModel.ensureMetadataLoaded()
                            print("✅ ensureMetadataLoaded complete")
                            
                            // Complete loading and update UI
                            await MainActor.run {
                                print("🔄 Updating cache and finalizing...")
                                
                                // Update cached content for new item type WITHOUT setting isCacheReady yet
                                updateCachedRatingsWithoutMarkingReady()
                                
                                // Preload images for new item type
                                preloadRatingImages()
                                
                                // NOW we can mark as ready and clear loading state
                                print("✅ All done, manually setting isCacheReady = true and clearing loading state")
                                isCacheReady = true
                                viewModel.isLoading = false
                                viewModel.loadingMessage = ""
                            }
                        }
                    }
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(RatingTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab.title)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .medium)
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? .primary : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        ZStack(alignment: .top) {
            // Keep main content mounted to avoid layout bounce
            Group {
                if !searchText.isEmpty {
                    searchResultsView
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 12, pinnedViews: []) {
                            switch selectedTab {
                            case .unrated:
                                unratedContent
                            case .topRated:
                                topRatedContent
                            case .yourRatings:
                                yourRatingsContent
                            }
                            
                            // Bottom padding for safe scrolling
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                }
            }
            
            // Loading overlay - show during any loading state or when cache is not ready
            if viewModel.isLoading || !isCacheReady {
                BeatVisualizerLoadingView(message: viewModel.loadingMessage.isEmpty ? "Loading..." : viewModel.loadingMessage)
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .transition(.opacity)
                    .onAppear {
                        print("🔄 Loading overlay appeared: isLoading=\(viewModel.isLoading), isCacheReady=\(isCacheReady), message='\(viewModel.loadingMessage)'")
                    }
                    .onDisappear {
                        print("✅ Loading overlay disappeared")
                    }
            }
        }
    }
    
    private var unratedContent: some View {
        Group {
            if filteredUnratedItems.isEmpty && isCacheReady && hasInitialLoad {
                EmptyStateView(
                    icon: "music.note",
                    title: "All Caught Up!",
                    subtitle: "You've rated all your \(viewModel.selectedItemType.displayName.lowercased())"
                )
                .padding(.top, 60)
            } else if !filteredUnratedItems.isEmpty {
                let items = Array(filteredUnratedItems.prefix(unratedLimit))
                
                if isGridView {
                    // Grid layout - responsive columns
                    LazyVGrid(columns: adaptiveGridColumns, spacing: 12) {
                        ForEach(items, id: \.id) { item in
                            GridRatingCard(
                                itemData: item,
                                rating: nil,
                                onTap: {
                                    Task {
                                        await viewModel.startRating(for: item)
                                    }
                                },
                                onDelete: nil
                            )
                            .onAppear {
                                if item.id == items.last?.id, unratedLimit < filteredUnratedItems.count {
                                    unratedLimit += 50
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    // List layout
                    ForEach(items, id: \.id) { item in
                        RatingItemCard(
                            itemData: item,
                            rating: nil,
                            showRating: false
                        ) {
                            Task {
                                await viewModel.startRating(for: item)
                            }
                        } onSwipeRight: {
                            Task { await viewModel.startRating(for: item) }
                        } onSwipeLeft: {
                            // no-op for unrated list
                        }
                        .onAppear {
                            if item.id == items.last?.id, unratedLimit < filteredUnratedItems.count {
                                unratedLimit += 50
                            }
                        }
                    }
                }
                
                if unratedLimit < filteredUnratedItems.count {
                    loadMoreButton { unratedLimit += 50 }
                }
            }
        }
    }
    
    private var topRatedContent: some View {
        Group {
            if topRatedItems.isEmpty && isCacheReady && hasInitialLoad {
                EmptyStateView(
                    icon: "star.fill",
                    title: "No Top Ratings Yet",
                    subtitle: "Rate some \(viewModel.selectedItemType.displayName.lowercased()) to see your favorites here"
                )
                .padding(.top, 60)
            } else if !topRatedItems.isEmpty {
                let items = Array(topRatedItems.prefix(topRatedLimit))
                
                if isGridView {
                    // Grid layout - responsive columns
                    LazyVGrid(columns: adaptiveGridColumns, spacing: 12) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                            GridRatingCard(
                                itemData: item.itemData,
                                rating: item.rating,
                                onTap: {
                                    Task {
                                        await viewModel.startRating(for: item.itemData)
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteRating(item.rating)
                                    }
                                }
                            )
                            .onAppear {
                                if item.id == items.last?.id, topRatedLimit < topRatedItems.count {
                                    topRatedLimit += 50
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    // List layout
                    ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                        SwipeableRatingCard(
                            itemData: item.itemData,
                            rating: item.rating,
                            showRating: true,
                            onTap: {
                                Task {
                                    await viewModel.startRating(for: item.itemData)
                                }
                            },
                            onRerate: {
                                Task {
                                    await viewModel.startRating(for: item.itemData)
                                }
                            },
                            onDelete: {
                                Task {
                                    await viewModel.deleteRating(item.rating)
                                }
                            }
                        )
                        .onAppear {
                            if item.id == items.last?.id, topRatedLimit < topRatedItems.count {
                                topRatedLimit += 50
                            }
                        }
                    }
                }
                
                if topRatedLimit < topRatedItems.count {
                    loadMoreButton { topRatedLimit += 50 }
                }
            }
        }
    }
    
    private var yourRatingsContent: some View {
        Group {
            if allRatedItems.isEmpty && isCacheReady && hasInitialLoad {
                EmptyStateView(
                    icon: "heart",
                    title: "No Ratings Yet",
                    subtitle: "Start rating \(viewModel.selectedItemType.displayName.lowercased()) to build your collection"
                )
                .padding(.top, 60)
            } else if !allRatedItems.isEmpty {
                let items = Array(allRatedItems.prefix(yourRatingsLimit))
                
                if isGridView {
                    // Grid layout - responsive columns
                    LazyVGrid(columns: adaptiveGridColumns, spacing: 12) {
                        ForEach(items, id: \.id) { item in
                            GridRatingCard(
                                itemData: item.itemData,
                                rating: item.rating,
                                onTap: {
                                    Task {
                                        await viewModel.startRating(for: item.itemData)
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteRating(item.rating)
                                    }
                                }
                            )
                            .onAppear {
                                if item.id == items.last?.id, yourRatingsLimit < allRatedItems.count {
                                    yourRatingsLimit += 50
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    // List layout
                    ForEach(items, id: \.id) { item in
                        SwipeableRatingCard(
                            itemData: item.itemData,
                            rating: item.rating,
                            showRating: true,
                            onTap: {
                                Task {
                                    await viewModel.startRating(for: item.itemData)
                                }
                            },
                            onRerate: {
                                Task {
                                    await viewModel.startRating(for: item.itemData)
                                }
                            },
                            onDelete: {
                                Task {
                                    await viewModel.deleteRating(item.rating)
                                }
                            }
                        )
                        .onAppear {
                            if item.id == items.last?.id, yourRatingsLimit < allRatedItems.count {
                                yourRatingsLimit += 50
                            }
                        }
                    }
                }
                
                if yourRatingsLimit < allRatedItems.count {
                    loadMoreButton { yourRatingsLimit += 50 }
                }
            }
        }
    }
    
    private var searchResultsView: some View {
        VStack(spacing: 16) {
            if viewModel.isSearching {
                CompactBeatVisualizer(isPlaying: true)
                    .padding(.vertical, 16)
                    .padding()
            } else if viewModel.searchResults.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    subtitle: "No items found for '\(searchText)'"
                )
                .padding(.top, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("\(viewModel.searchResults.count) result\(viewModel.searchResults.count == 1 ? "" : "s") for '\(searchText)'")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        let items = Array(viewModel.searchResults.prefix(searchLimit))
                        ForEach(items, id: \.id) { item in
                            let existingRating = viewModel.userRatings[item.itemType.rawValue]?.first { $0.itemId == item.id }
                            
                            RatingItemCard(
                                itemData: item,
                                rating: existingRating,
                                showRating: existingRating != nil
                            ) {
                                Task {
                                    await viewModel.startRating(for: item)
                                }
                            } onSwipeRight: {
                                Task { await viewModel.startRating(for: item) }
                            } onSwipeLeft: {
                                if let rating = existingRating {
                                    Task { await viewModel.deleteRating(rating) }
                                }
                            }
                            .onAppear {
                                if item.id == items.last?.id, searchLimit < viewModel.searchResults.count {
                                    searchLimit += 50
                                }
                            }
                            .contextMenu {
                                if let rating = existingRating {
                                    Button("Rate Again", systemImage: "star.circle") {
                                        Task {
                                            await viewModel.startRating(for: item)
                                        }
                                    }
                                    
                                    Button("Remove Rating", systemImage: "trash", role: .destructive) {
                                        Task {
                                            await viewModel.deleteRating(rating)
                                        }
                                    }
                                } else {
                                    Button("Rate Item", systemImage: "star") {
                                        Task {
                                            await viewModel.startRating(for: item)
                                        }
                                    }
                                }
                            }
                        }
                        if searchLimit < viewModel.searchResults.count {
                            loadMoreButton { searchLimit += 50 }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredUnratedItems: [RatingItemData] {
        let items = searchText.isEmpty ? viewModel.unratedItems :
        viewModel.unratedItems.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            (item.artists?.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ?? false)
        }
        return items
    }
    
    private var topRatedItems: [RatedItem] {
        return cachedTopRatedItems
    }
    
    private var allRatedItems: [RatedItem] {
        return cachedAllRatedItems
    }
    
    // MARK: - Image Preloading
    
    private func preloadRatingImages() {
        // Preload images from all current rating data
        let unratedItems = viewModel.unratedItems
        let topRated = topRatedItems
        let allRated = allRatedItems
        
        // Extract image URLs from unrated items  
        let unratedImageUrls = unratedItems.compactMap { $0.imageUrl }
        
        // Extract image URLs from rated items
        let topRatedImageUrls = topRated.compactMap { $0.itemData.imageUrl }
        let allRatedImageUrls = allRated.compactMap { $0.itemData.imageUrl }
        
        // Combine all URLs
        let allImageUrls = unratedImageUrls + topRatedImageUrls + allRatedImageUrls
        
        // Preload images
        for imageUrl in allImageUrls.prefix(50) { // Limit to first 50 to avoid overwhelming
            imagePreloader.preloadImage(imageUrl)
        }
    }
    
    // MARK: - Cache Update Methods
    
    private func updateCachedRatingsWithoutMarkingReady() {
        // This version doesn't set isCacheReady = true to avoid race conditions
        // Update top rated items cache
        let topRatings = viewModel.filteredRatings
            .filter { $0.personalScore >= 7.0 }
            .sorted { $0.personalScore > $1.personalScore }
            .prefix(20)
        
        cachedTopRatedItems = Array(topRatings).compactMap { rating in
            let itemData = viewModel.getItemData(for: rating) ?? RatingItemData(
                id: rating.itemId,
                name: "Unknown",
                imageUrl: nil,
                artists: nil,
                albumName: nil,
                albumId: rating.albumId,
                itemType: rating.itemType
            )
            return RatedItem(id: rating.id, rating: rating, itemData: itemData)
        }
        
        // Update all rated items cache with appropriate sorting
        let allRatings: [Rating]
        if viewModel.selectedItemType == .track {
            // For tracks, sort by album first, then by position within album
            allRatings = viewModel.filteredRatings.sorted { rating1, rating2 in
                let itemData1 = viewModel.getItemData(for: rating1)
                let itemData2 = viewModel.getItemData(for: rating2)
                let album1 = itemData1?.albumName ?? ""
                let album2 = itemData2?.albumName ?? ""
                
                if album1 != album2 {
                    return album1 < album2 // Sort albums alphabetically
                } else {
                    return rating1.position < rating2.position // Then by position within album
                }
            }
        } else {
            // For albums and artists, sort by score
            allRatings = viewModel.filteredRatings.sorted { $0.personalScore > $1.personalScore }
        }
        cachedAllRatedItems = allRatings.compactMap { rating in
            let itemData = viewModel.getItemData(for: rating) ?? RatingItemData(
                id: rating.itemId,
                name: "Unknown",
                imageUrl: nil,
                artists: nil,
                albumName: nil,
                albumId: rating.albumId,
                itemType: rating.itemType
            )
            return RatedItem(id: rating.id, rating: rating, itemData: itemData)
        }
        
        lastRatingsUpdateTime = Date()
        print("🎯 Cache updated (WITHOUT marking ready) with \(cachedTopRatedItems.count) top items and \(cachedAllRatedItems.count) all items")
        
        // Mark initial load as complete after first cache update
        if !hasInitialLoad {
            hasInitialLoad = true
        }
    }
    
    private func updateCachedRatings() {
        Task {
            // Ensure metadata is loaded first
            await viewModel.ensureMetadataLoaded()
            
            await MainActor.run {
                // Update top rated items cache
                let topRatings = viewModel.filteredRatings
                    .filter { $0.personalScore >= 7.0 }
                    .sorted { $0.personalScore > $1.personalScore }
                    .prefix(20)
                
                cachedTopRatedItems = Array(topRatings).compactMap { rating in
                    let itemData = viewModel.getItemData(for: rating) ?? RatingItemData(
                        id: rating.itemId,
                        name: "Unknown",
                        imageUrl: nil,
                        artists: nil,
                        albumName: nil,
                        albumId: rating.albumId,
                        itemType: rating.itemType
                    )
                    return RatedItem(id: rating.id, rating: rating, itemData: itemData)
                }
                
                // Update all rated items cache with appropriate sorting
                let allRatings: [Rating]
                if viewModel.selectedItemType == .track {
                    // For tracks, sort by album first, then by position within album
                    allRatings = viewModel.filteredRatings.sorted { rating1, rating2 in
                        let itemData1 = viewModel.getItemData(for: rating1)
                        let itemData2 = viewModel.getItemData(for: rating2)
                        let album1 = itemData1?.albumName ?? ""
                        let album2 = itemData2?.albumName ?? ""
                        
                        if album1 != album2 {
                            return album1 < album2 // Sort albums alphabetically
                        } else {
                            return rating1.position < rating2.position // Then by position within album
                        }
                    }
                } else {
                    // For albums and artists, sort by score
                    allRatings = viewModel.filteredRatings.sorted { $0.personalScore > $1.personalScore }
                }
                cachedAllRatedItems = allRatings.compactMap { rating in
                    let itemData = viewModel.getItemData(for: rating) ?? RatingItemData(
                        id: rating.itemId,
                        name: "Unknown",
                        imageUrl: nil,
                        artists: nil,
                        albumName: nil,
                        albumId: rating.albumId,
                        itemType: rating.itemType
                    )
                    return RatedItem(id: rating.id, rating: rating, itemData: itemData)
                }
                
                lastRatingsUpdateTime = Date()
                print("🎯 Setting isCacheReady = true with \(cachedTopRatedItems.count) top items and \(cachedAllRatedItems.count) all items")
                isCacheReady = true
                
                // Mark initial load as complete after first cache update
                if !hasInitialLoad {
                    hasInitialLoad = true
                }
            }
        }
    }
    
    // MARK: - Load More Button
    
    @ViewBuilder
    private func loadMoreButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                CompactBeatVisualizer(isPlaying: true)
                    .frame(width: 40)
                    .padding(.trailing, 8)
                Text("Load more")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
} // <-- CLOSES struct RateView

// MARK: - Supporting Views

struct ItemTypeButton: View {
    let itemType: RatingItemType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: itemType.iconName)
                    .font(.system(size: 14, weight: .medium))
                
                Text(itemType.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.primary : Color(UIColor.secondarySystemBackground))
            )
        }
        .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.02 : 1.0))
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Supporting Types

enum RatingTab: CaseIterable {
    case unrated
    case topRated
    case yourRatings
    
    var title: String {
        switch self {
        case .unrated: return "Unrated"
        case .topRated: return "Top Rated"
        case .yourRatings: return "Your Ratings"
        }
    }
}

// MARK: - Extensions

extension RatingItemType {
    var iconName: String {
        switch self {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "person.fill"
        }
    }
}

#Preview {
    RateView()
        .environmentObject(AuthManager.shared)
}

