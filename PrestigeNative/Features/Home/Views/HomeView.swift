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
    @State private var gridColumnCount: Int = 3 // Default: 3 columns
    @StateObject private var tutorialManager = TutorialManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with crown logo and title
                HStack(alignment: .center, spacing: 8) {
                    Image("white_logo_clear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text("Your Prestiges")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
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
        HStack(spacing: 12) {
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedContentType == type
                                ? Color.purple
                                : Color.gray.opacity(0.2)
                        )
                        .cornerRadius(20)
                }
            }
            
            Spacer()
            
            // Grid toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    toggleGridSize()
                }
            }) {
                Image(systemName: gridIconName)
                    .font(.title2)
                    .foregroundColor(.purple)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
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
                            .foregroundColor(viewModel.selectedTimeRange == range ? .white : .secondary)
                            .lineLimit(1)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(viewModel.selectedTimeRange == range ? .white : .clear)
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
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: gridItemSpacing), count: gridColumnCount),
                spacing: gridRowSpacing
            ) {
                prestigeGridContent
            }
            .padding(.horizontal, 8)
        }
    }
    
    @ViewBuilder
    private var prestigeGridContent: some View {
        switch viewModel.selectedContentType {
        case .albums:
            ForEach(Array(viewModel.topAlbums.enumerated()), id: \.element.album.id) { index, album in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromAlbum(album),
                    rank: index + 1,
                    gridColumnCount: gridColumnCount
                )
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
                    gridColumnCount: gridColumnCount
                )
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
                    gridColumnCount: gridColumnCount
                )
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
    
    // MARK: - Grid Toggle Functionality
    
    private func toggleGridSize() {
        switch gridColumnCount {
        case 3:
            gridColumnCount = 4
        case 4:
            gridColumnCount = 2
        case 2:
            gridColumnCount = 3
        default:
            gridColumnCount = 3
        }
    }
    
    private var gridIconName: String {
        switch gridColumnCount {
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
    
    // Dynamic spacing based on grid size
    private var gridItemSpacing: CGFloat {
        switch gridColumnCount {
        case 2:
            return 4   // Very tight spacing for 2 columns
        case 3:
            return 8   // Perfect spacing (reference)
        case 4:
            return 4   // Less spacing for 4 columns to prevent overlap
        default:
            return 8
        }
    }
    
    private var gridRowSpacing: CGFloat {
        switch gridColumnCount {
        case 2:
            return 6   // Very tight spacing for 2 columns
        case 3:
            return 10  // Perfect spacing (reference)
        case 4:
            return 6   // Less spacing for 4 columns to prevent overlap
        default:
            return 10
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