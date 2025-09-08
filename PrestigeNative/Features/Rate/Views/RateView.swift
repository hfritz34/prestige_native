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
    
    // Fixed 3-column grid for all devices
    private var adaptiveGridColumns: [GridItem] {
        let screenWidth = UIScreen.main.bounds.width
        
        // Safety check for invalid screen width
        guard screenWidth.isFinite && screenWidth > 0 else {
            return Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        }
        
        let isArtist = (viewModel.selectedItemType == .artist)
        let spacing = adaptiveItemSpacing(screenWidth: screenWidth, isArtist: isArtist)
        
        // Always use 3 columns for Rate page
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3)
    }
    
    // Calculate ideal item width for 3-column grid
    private func idealItemWidth(screenWidth: CGFloat) -> CGFloat {
        let targetColumns: CGFloat = 3  // Always 3 columns for Rate page
        let totalHorizontalPadding: CGFloat = 32 // 16 on each side
        let isArtist = (viewModel.selectedItemType == .artist)
        let spacing = adaptiveItemSpacing(screenWidth: screenWidth, isArtist: isArtist)
        let totalSpacing = (targetColumns - 1) * spacing
        let availableWidth = screenWidth - totalHorizontalPadding - totalSpacing
        let computed = availableWidth / targetColumns
        
        // Keep a sensible minimum so content isn't cramped
        return max(100, floor(computed))
    }
    
    // Dynamic spacing based on screen size - moderate spacing to maximize grid space
    private func adaptiveItemSpacing(screenWidth: CGFloat, isArtist: Bool) -> CGFloat {
        switch screenWidth {
        case ..<380:    // iPhone SE (375)
            return 4
        case 380..<400: // iPhone 12/13/14/15 mini (375), iPhone 12/13 Pro, iPhone 14/15 (390-393)
            return 5  // Moderate spacing for iPhone 12
        case 400..<420: // iPhone 16 Pro (402), iPhone 11/XR (414)
            return 6
        case 420..<435: // iPhone 12/13/14/15 Pro Max/Plus (428-430)
            return 7
        default:        // iPhone 16 Pro Max (440+)
            return 8  // Less spacing to maximize grid space
        }
    }
    
    // Dynamic row spacing for LazyVGrid - much more aggressive vertical spacing
    private var gridRowSpacing: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        switch screenWidth {
        case ..<380:    // iPhone SE, iPhone 8
            return 12
        case 380..<400: // iPhone 12 mini and iPhone 12
            return 16  // Much more vertical spacing for iPhone 12
        case 400..<430: // iPhone 13, iPhone 14, iPhone 15
            return 18
        default:        // iPhone 16 Pro Max, etc.
            return 20
        }
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
        .onChange(of: viewModel.isLoading) { oldValue, newValue in
            // When loading completes, update cache and mark ready
            if oldValue && !newValue {
                // Add a delay to ensure all data is properly loaded and avoid empty state flash
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    await MainActor.run {
                        updateCachedRatingsWithoutMarkingReady()
                        preloadRatingImages()
                        isCacheReady = true
                    }
                }
            }
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
                        
                        // Clear cache immediately to prevent showing stale data
                        cachedTopRatedItems = []
                        cachedAllRatedItems = []
                        isCacheReady = false
                        
                        // Use the new debounced switchItemType method
                        viewModel.switchItemType(to: itemType)
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
                TabSelectorButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }
                )
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
            
            // Loading overlay - show full screen loading for initial load or category switches  
            if viewModel.isLoading || !isCacheReady {
                BeatVisualizerLoadingView(message: viewModel.loadingMessage.isEmpty ? "Loading..." : viewModel.loadingMessage)
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onAppear {
                        print("🔄 Loading overlay appeared: isLoading=\(viewModel.isLoading), isCacheReady=\(isCacheReady), message='\(viewModel.loadingMessage)'")
                    }
                    .onDisappear {
                        print("✅ Loading overlay disappeared")
                    }
            }
            
            // Subtle loading overlay for category switches when we have content
            else if viewModel.isLoading && hasInitialLoad {
                Color.black.opacity(0.3)
                    .overlay(
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text(viewModel.loadingMessage.isEmpty ? "Loading..." : viewModel.loadingMessage)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    )
                    .transition(.opacity)
                    .onAppear {
                        print("🔄 Subtle loading overlay appeared: message='\(viewModel.loadingMessage)'")
                    }
            }
        }
    }
    
    private var unratedContent: some View {
        Group {
            // Always show loading instead of empty state for better UX
            if filteredUnratedItems.isEmpty {
                // Show loading animation instead of "All Caught Up"
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("Loading unrated \(viewModel.selectedItemType.displayName.lowercased())...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if !filteredUnratedItems.isEmpty {
                let items = Array(filteredUnratedItems.prefix(unratedLimit))
                
                if isGridView {
                    // Grid layout - responsive columns
                    LazyVGrid(columns: adaptiveGridColumns, spacing: gridRowSpacing) {
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
                    .padding(.horizontal, 8)  // Less horizontal padding to maximize grid space
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
            // Always show loading instead of empty state for better UX
            if topRatedItems.isEmpty {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("Loading top \(viewModel.selectedItemType.displayName.lowercased())...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if !topRatedItems.isEmpty {
                let items = Array(topRatedItems.prefix(topRatedLimit))
                
                if isGridView {
                    // Grid layout - responsive columns
                    LazyVGrid(columns: adaptiveGridColumns, spacing: gridRowSpacing) {
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
                    .padding(.horizontal, 8)  // Less horizontal padding to maximize grid space
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
            // Always show loading instead of empty state for better UX  
            if allRatedItems.isEmpty {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("Loading your \(viewModel.selectedItemType.displayName.lowercased())...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if !allRatedItems.isEmpty {
                let items = Array(allRatedItems.prefix(yourRatingsLimit))
                
                if isGridView {
                    // Grid layout - responsive columns
                    LazyVGrid(columns: adaptiveGridColumns, spacing: gridRowSpacing) {
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
                    .padding(.horizontal, 8)  // Less horizontal padding to maximize grid space
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
                isSelected ? Theme.primary.opacity(0.8) : Color.clear
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.2), lineWidth: 0.5)
            )
        }
        .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.05 : 1.0))
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: isPressed)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct TabSelectorButton: View {
    let tab: RatingTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(tab.title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? .primary : .clear)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
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

