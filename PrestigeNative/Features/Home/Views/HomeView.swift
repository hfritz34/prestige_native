//
//  HomeView.swift
//  Home Screen - Prestige Display
//
//  Shows user's top prestiges with type switching (tracks/albums/artists).
//  Matches HomePage.tsx from the web application.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var pinService = PinService.shared
    @StateObject private var imagePreloader = ImagePreloader.shared
    @StateObject private var detailCache = DetailViewCache.shared
    @State private var showingError = false
    @State private var selectedPrestige: PrestigeSelection?
    @State private var showContentButtons = false
    @State private var forceTargetColumns: Int = 3 // Default to 3 columns
    @StateObject private var tutorialManager = TutorialManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with crown logo and title
                HStack(alignment: .center, spacing: 8) {
                    Image(colorScheme == .dark ? "white_crown" : "purple_crown")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text("Your Prestiges")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .offset(y: 2)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Content Type Buttons
                if showContentButtons {
                    contentTypeButtons
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Time Filter Tabs
                    timeFilterTabs
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity).animation(.easeInOut(duration: 0.3).delay(0.1)))
                }
                
                // Content
                ZStack {
                    ScrollView {
                        VStack(spacing: 24) {
                            if viewModel.loadingState == .loaded && hasContent {
                                prestigeGridSection
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            } else if viewModel.loadingState == .loaded && !hasContent {
                                emptyStateView
                            } else if viewModel.isLoading {
                                SkeletonGridView()
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Beat visualizer loading overlay for initial loads
                    if viewModel.isLoading && !viewModel.hasInitiallyLoaded {
                        BeatVisualizerLoadingView(message: viewModel.loadingMessage)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Subtle loading overlay for content switches when we already have content
                    if viewModel.isLoading && viewModel.hasInitiallyLoaded && hasContent {
                        Color.black.opacity(0.3)
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(.white)
                                    Text("Loading...")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.top, 8)
                                }
                            )
                            .transition(.opacity)
                    }
                }
                .refreshable {
                    viewModel.refreshData()
                }
                .preloadAlbumImages(viewModel.topAlbums)
                .preloadTrackImages(viewModel.topTracks)
                .preloadArtistImages(viewModel.topArtists)
            }
            .navigationBarHidden(true)
        }
        .dynamicTypeSize(.medium)
        .networkSpeedControls()
        .onAppear {
            if let userId = authManager.user?.id, !userId.isEmpty {
                Task {
                    // Coordinate parallel loading of home data, pinned items, and tutorial check
                    async let homeDataTask = viewModel.loadHomeDataAsync(for: userId)
                    async let pinnedItemsTask = pinService.loadPinnedItems()
                    let tutorialCheck = tutorialManager.checkIfShouldShowTutorial()
                    
                    // Wait for all tasks to complete
                    await homeDataTask
                    await pinnedItemsTask
                    
                    // Show content buttons after data is loaded
                    await MainActor.run {
                        withAnimation {
                            showContentButtons = true
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
        .onChange(of: viewModel.error) { _, error in
            showingError = error != nil
        }
        .onChange(of: viewModel.selectedContentType) { _, _ in
            // Preload images when content type changes
            Task {
                await MainActor.run {
                    imagePreloader.preloadAlbumImages(viewModel.topAlbums)
                    imagePreloader.preloadTrackImages(viewModel.topTracks)
                    imagePreloader.preloadArtistImages(viewModel.topArtists)
                }
            }
        }
        .sheet(item: $selectedPrestige) { selection in
            PrestigeDetailView(
                item: selection.item,
                rank: selection.rank
            )
        }
        .sheet(isPresented: $tutorialManager.shouldShowTutorial) {
            OnboardingTutorialView()
                .onDisappear {
                    tutorialManager.markTutorialAsCompleted()
                }
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasContent: Bool {
        switch viewModel.selectedContentType {
        case .tracks: return !viewModel.topTracks.isEmpty
        case .albums: return !viewModel.topAlbums.isEmpty
        case .artists: return !viewModel.topArtists.isEmpty
        }
    }
    
    
    // MARK: - View Components
    
    private var contentTypeButtons: some View {
        HStack(spacing: contentButtonSpacing) {
            ForEach(ContentType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.selectedContentType = type
                    }
                }) {
                    Text(type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.selectedContentType == type ? .white : .gray)
                        .padding(.horizontal, contentButtonHorizontalPadding)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedContentType == type
                                ? Color.purple
                                : Color.gray.opacity(0.2)
                        )
                        .cornerRadius(20)
                        .minimumScaleFactor(0.85) // Allow text to scale down if needed
                }
            }
            
            Spacer()
            
            // Grid toggle button (now controls target columns for adaptive grid)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    toggleGridSize()
                }
            }) {
                Image(systemName: gridIconName)
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 24, height: 24) // Fixed size to prevent layout shifts
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .frame(width: 40, height: 40) // Fixed button frame
        }
    }
    
    // Dynamic content button spacing and padding based on screen size
    private var contentButtonSpacing: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        switch screenWidth {
        case ..<380:    // iPhone SE, iPhone 8
            return 8
        case 380..<400: // iPhone 12 mini
            return 10
        default:        // iPhone 12 and larger
            return 12
        }
    }
    
    private var contentButtonHorizontalPadding: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        switch screenWidth {
        case ..<380:    // iPhone SE, iPhone 8
            return 12
        case 380..<400: // iPhone 12 mini
            return 16
        default:        // iPhone 12 and larger
            return 20
        }
    }
    
    private var timeFilterTabs: some View {
        HStack(spacing: 0) {
            ForEach(PrestigeTimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTimeRange = range
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(range.displayName)
                            .font(.subheadline)
                            .fontWeight(viewModel.selectedTimeRange == range ? .semibold : .medium)
                            .foregroundColor(viewModel.selectedTimeRange == range ? .primary : .secondary)
                            .lineLimit(1)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(viewModel.selectedTimeRange == range ? .primary : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var contentList: some View {
        switch viewModel.selectedContentType {
        case .albums:
            if viewModel.topAlbums.isEmpty {
                EmptyStateView(
                    icon: "square.stack",
                    title: "No Top Albums",
                    subtitle: "Listen to complete albums to build prestige"
                )
            } else {
                ForEach(Array(viewModel.topAlbums.prefix(25).enumerated()), id: \.element.album.id) { index, album in
                    PrestigeAlbumRow(album: album, rank: index + 1)
                }
            }
            
        case .tracks:
            if viewModel.topTracks.isEmpty {
                EmptyStateView(
                    icon: "music.note",
                    title: "No Top Tracks",
                    subtitle: "Start listening to build your prestige"
                )
            } else {
                ForEach(Array(viewModel.topTracks.prefix(25).enumerated()), id: \.element.track.id) { index, track in
                    PrestigeTrackRow(track: track, rank: index + 1)
                }
            }
            
        case .artists:
            if viewModel.topArtists.isEmpty {
                EmptyStateView(
                    icon: "music.mic",
                    title: "No Top Artists",
                    subtitle: "Explore artists to build prestige"
                )
            } else {
                ForEach(Array(viewModel.topArtists.prefix(25).enumerated()), id: \.element.artist.id) { index, artist in
                    PrestigeArtistRow(artist: artist, rank: index + 1)
                }
            }
        }
    }
    
    private var prestigeGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            GeometryReader { geometry in
                LazyVGrid(
                    columns: adaptiveGridColumns(screenWidth: geometry.size.width),
                    spacing: adaptiveRowSpacing(screenWidth: geometry.size.width)
                ) {
                    prestigeGridContent
                }
                .padding(.horizontal, 8)
            }
            .frame(minHeight: calculateGridHeight())
        }
    }
    
    // Fixed grid columns based on forced column count
    private func adaptiveGridColumns(screenWidth: CGFloat) -> [GridItem] {
        let spacing = adaptiveItemSpacing(screenWidth: screenWidth)
        let columns = forceTargetColumns
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    // Calculate ideal item width based on forced column count
    private func idealItemWidth(screenWidth: CGFloat) -> CGFloat {
        let targetColumns: CGFloat = CGFloat(forceTargetColumns)
        let totalHorizontalPadding: CGFloat = 16 // 8 on each side
        let spacing = adaptiveItemSpacing(screenWidth: screenWidth)
        let totalSpacing = (targetColumns - 1) * spacing
        let availableWidth = screenWidth - totalHorizontalPadding - totalSpacing
        let computed = availableWidth / targetColumns
        
        // Keep a sensible minimum so content isn't cramped
        return max(80, floor(computed))
    }
    
    // Dynamic spacing based on logical width breakpoints and column count
    private func adaptiveItemSpacing(screenWidth: CGFloat) -> CGFloat {
        // **TRIED AND FAILED VALUES:**
        // iPhone 12 (390pt): baseSpacing 12pt caused blank space above grid
        // iPhone 16 Pro Max (440pt): baseSpacing 16pt caused overlaps and cutoffs
        // Multipliers (1.5x, 1.2x, 0.9x) caused sizing issues
        
        let baseSpacing: CGFloat
        switch screenWidth {
        case ..<375:    // iPhone SE 1st gen (320pt)
            baseSpacing = 4
        case ..<390:    // iPhone SE 2nd/3rd, iPhone 8-13 mini (375pt)
            baseSpacing = 5
        case ..<400:    // iPhone 12/13/14/15 standard (390-393pt) - REDUCED from 12
            baseSpacing = 7
        case ..<420:    // iPhone 16 Pro (402pt), iPhone 11/XR (414pt)
            baseSpacing = 8
        case ..<440:    // iPhone 12/13/14/15 Pro Max/Plus (428-430pt)
            baseSpacing = 9
        default:        // iPhone 16 Pro Max (440pt+) - REDUCED from 16
            baseSpacing = 6  // MUCH smaller for Pro Max to prevent cutoff
        }
        
        // More conservative multipliers
        let columnMultiplier: CGFloat = {
            switch forceTargetColumns {
            case 2: return 1.3  // Less aggressive than 1.5x
            case 3: return 1.0  // Base spacing for 3 columns
            case 4: return 0.6  // Tighter for 4 columns, less than 0.9x
            default: return 1.0
            }
        }()
        
        // iPhone 12 (390pt) special handling - less aggressive
        if screenWidth >= 390 && screenWidth < 394 && forceTargetColumns == 3 {
            return baseSpacing * 1.5  // Less than 2.0x to prevent blank space
        }
        
        return baseSpacing * columnMultiplier
    }
    
    // Dynamic row spacing based on logical width breakpoints and column count
    private func adaptiveRowSpacing(screenWidth: CGFloat) -> CGFloat {
        // **TRIED AND FAILED VALUES:**
        // baseRowSpacing 16-20pt caused blank space above grid
        // Multipliers (1.3x, 1.1x, 0.9x) with 1.8x special case caused spacing issues
        
        let baseRowSpacing: CGFloat
        switch screenWidth {
        case ..<375:    // iPhone SE 1st gen (320pt)
            baseRowSpacing = 6
        case ..<390:    // iPhone SE 2nd/3rd, iPhone 8-13 mini (375pt)
            baseRowSpacing = 7
        case ..<400:    // iPhone 12/13/14/15 standard (390-393pt) - REDUCED from 16
            baseRowSpacing = 8
        case ..<420:    // iPhone 16 Pro (402pt), iPhone 11/XR (414pt)
            baseRowSpacing = 9
        case ..<440:    // iPhone 12/13/14/15 Pro Max/Plus (428-430pt)
            baseRowSpacing = 10
        default:        // iPhone 16 Pro Max (440pt+) - REDUCED from 20
            baseRowSpacing = 8  // MUCH smaller for Pro Max
        }
        
        // Simpler, more conservative multipliers
        let columnMultiplier: CGFloat = {
            switch forceTargetColumns {
            case 2: return 1.2  // Less than 1.3x
            case 3: return 1.0  // Base spacing
            case 4: return 0.8  // Less than 0.9x
            default: return 1.0
            }
        }()
        
        // iPhone 12 (390pt) special handling - much less aggressive
        if screenWidth >= 390 && screenWidth < 394 && forceTargetColumns == 3 {
            return baseRowSpacing * 1.2  // Much less than 1.8x to prevent blank space
        }
        
        return baseRowSpacing * columnMultiplier
    }
    
    // Estimate grid height to avoid GeometryReader layout issues
    private func calculateGridHeight() -> CGFloat {
        let itemCount = CGFloat(max(viewModel.topTracks.count, max(viewModel.topAlbums.count, viewModel.topArtists.count)))
        let targetColumns: CGFloat = CGFloat(forceTargetColumns)
        let rows = ceil(itemCount / targetColumns)
        
        // Use fixed, reasonable item heights to prevent blank space
        let itemHeight: CGFloat = {
            switch forceTargetColumns {
            case 2: return 220  // Reduced from 240
            case 3: return 180  // Reduced from 200
            case 4: return 160  // Reduced from 180
            default: return 180
            }
        }()
        
        // Use fixed row spacing instead of dynamic to prevent blank space issues
        let rowSpacing: CGFloat = {
            switch forceTargetColumns {
            case 2: return 12
            case 3: return 10
            case 4: return 8
            default: return 10
            }
        }()
        
        // Only add extra padding for 2-column display
        let bottomPadding: CGFloat = forceTargetColumns == 2 ? 50 : 20  // Reduced padding
        return (rows * itemHeight) + ((rows - 1) * rowSpacing) + bottomPadding
    }
    
    @ViewBuilder
    private var prestigeGridContent: some View {
        switch viewModel.selectedContentType {
        case .albums:
            ForEach(Array(viewModel.topAlbums.enumerated()), id: \.element.album.id) { index, album in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromAlbum(album),
                    rank: index + 1,
                    gridColumnCount: forceTargetColumns
                )
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    // Preload album detail data immediately when tapped
                    Task {
                        await preloadAlbumDetailData(album)
                    }
                    
                    selectedPrestige = PrestigeSelection(
                        item: PrestigeDisplayItem.fromAlbum(album),
                        rank: index + 1
                    )
                }
            }
        case .tracks:
            ForEach(Array(viewModel.topTracks.enumerated()), id: \.element.track.id) { index, track in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromTrack(track),
                    rank: index + 1,
                    gridColumnCount: forceTargetColumns
                )
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    // Preload track detail data immediately when tapped
                    Task {
                        await preloadTrackDetailData(track)
                    }
                    
                    selectedPrestige = PrestigeSelection(
                        item: PrestigeDisplayItem.fromTrack(track),
                        rank: index + 1
                    )
                }
            }
        case .artists:
            ForEach(Array(viewModel.topArtists.enumerated()), id: \.element.artist.id) { index, artist in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromArtist(artist),
                    rank: index + 1,
                    gridColumnCount: forceTargetColumns
                )
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    // Preload artist detail data immediately when tapped
                    Task {
                        await preloadArtistDetailData(artist)
                    }
                    
                    selectedPrestige = PrestigeSelection(
                        item: PrestigeDisplayItem.fromArtist(artist),
                        rank: index + 1
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        switch viewModel.selectedTimeRange {
        case .recentlyUpdated:
            switch viewModel.selectedContentType {
            case .albums:
                EmptyStateView(
                    icon: "square.stack",
                    title: "No Recently Updated Albums",
                    subtitle: "Albums will appear here after your next listening session"
                )
            case .tracks:
                EmptyStateView(
                    icon: "music.note",
                    title: "No Recently Updated Tracks",
                    subtitle: "Recently played tracks will appear here hourly"
                )
            case .artists:
                EmptyStateView(
                    icon: "music.mic",
                    title: "No Recently Updated Artists",
                    subtitle: "Artists from recent listening will appear here"
                )
            }
        default:
            switch viewModel.selectedContentType {
            case .albums:
                EmptyStateView(
                    icon: "square.stack",
                    title: "No Albums Found",
                    subtitle: "Listen to albums to build your prestige"
                )
            case .tracks:
                EmptyStateView(
                    icon: "music.note",
                    title: "No Top Tracks",
                    subtitle: "Start listening to build your prestige"
                )
            case .artists:
                EmptyStateView(
                    icon: "music.mic",
                    title: "No Top Artists",
                    subtitle: "Explore artists to build prestige"
                )
            }
        }
    }
    
    // MARK: - Adaptive Grid Toggle Functionality
    
    private func toggleGridSize() {
        switch forceTargetColumns {
        case 2:
            forceTargetColumns = 3
        case 3:
            forceTargetColumns = 4
        case 4:
            forceTargetColumns = 2
        default:
            forceTargetColumns = 3  // Always fallback to 3
        }
    }
    
    private var gridIconName: String {
        switch forceTargetColumns {
        case 2:
            return "square.grid.2x2"
        case 3:
            return "square.grid.3x2"
        case 4:
            return "square.grid.4x3.fill"
        default:
            return "square.grid.3x2"
        }
    }
    
    
    // MARK: - Preloading Methods
    
    /// Preload album detail data when user taps on album
    private func preloadAlbumDetailData(_ album: UserAlbumResponse) async {
        guard let userId = authManager.user?.id else { return }
        await detailCache.preloadAlbumDetail(album: album, userId: userId)
    }
    
    /// Preload track detail data when user taps on track
    private func preloadTrackDetailData(_ track: UserTrackResponse) async {
        guard let userId = authManager.user?.id else { return }
        await detailCache.preloadTrackDetail(track: track, userId: userId)
    }
    
    /// Preload artist detail data when user taps on artist
    private func preloadArtistDetailData(_ artist: UserArtistResponse) async {
        guard let userId = authManager.user?.id else { return }
        await detailCache.preloadArtistDetail(artist: artist, userId: userId)
    }
}

#Preview {
    HomeView()
}