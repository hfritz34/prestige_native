//
//  HomeView.swift
//  Home Screen - Prestige Display
//
//  Shows user's top prestiges with type switching (tracks/albums/artists).
//  Matches HomePage.tsx from the web application.
//

import SwiftUI

struct PrestigeSelection: Identifiable {
    let id = UUID()
    let item: PrestigeDisplayItem
    let rank: Int
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var pinService = PinService.shared
    @StateObject private var imagePreloader = ImagePreloader.shared
    @State private var showingError = false
    @State private var selectedPrestige: PrestigeSelection?
    @State private var showContentButtons = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // App Logo
                Image("prestige_purple")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                // Content Type Buttons
                contentTypeButtons
                    .padding(.horizontal)
                    .opacity(showContentButtons ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showContentButtons)
                
                // Time Filter
                timeFilterSelector
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .opacity(showContentButtons ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.1), value: showContentButtons)
                
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
                    
                    // Beat visualizer loading overlay
                    if viewModel.isLoading && !viewModel.hasInitiallyLoaded {
                        BeatVisualizerLoadingView(message: viewModel.loadingMessage)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                viewModel.loadHomeData(for: userId)
                
                // Load pinned items
                Task {
                    await pinService.loadPinnedItems()
                }
                
                // Show content buttons after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showContentButtons = true
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
                    withAnimation(.easeInOut(duration: 0.2)) {
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
        }
    }
    
    private var timeFilterSelector: some View {
        Menu {
            ForEach(PrestigeTimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation {
                        viewModel.selectedTimeRange = range
                    }
                }) {
                    HStack {
                        Text(range.displayName)
                        if viewModel.selectedTimeRange == range {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.subheadline)
                Text(viewModel.selectedTimeRange.displayName)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
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
                ForEach(Array(viewModel.topTracks.prefix(25).enumerated()), id: \.element.totalTime) { index, track in
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
            Text("Your Top Prestiges")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 16
            ) {
                prestigeGridContent
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var prestigeGridContent: some View {
        switch viewModel.selectedContentType {
        case .albums:
            ForEach(Array(viewModel.topAlbums.enumerated()), id: \.element.album.id) { index, album in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromAlbum(album).withPinState(
                        pinService.isItemPinned(itemId: album.album.id, itemType: .albums)
                    ),
                    rank: index + 1,
                    onPinToggle: {
                        Task {
                            await pinService.togglePin(itemId: album.album.id, itemType: .albums)
                        }
                    }
                )
                .onTapGesture {
                    selectedPrestige = PrestigeSelection(
                        item: PrestigeDisplayItem.fromAlbum(album),
                        rank: index + 1
                    )
                }
            }
        case .tracks:
            ForEach(Array(viewModel.topTracks.enumerated()), id: \.element.totalTime) { index, track in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromTrack(track).withPinState(
                        pinService.isItemPinned(itemId: track.track.id, itemType: .tracks)
                    ),
                    rank: index + 1,
                    onPinToggle: {
                        Task {
                            await pinService.togglePin(itemId: track.track.id, itemType: .tracks)
                        }
                    }
                )
                .onTapGesture {
                    selectedPrestige = PrestigeSelection(
                        item: PrestigeDisplayItem.fromTrack(track),
                        rank: index + 1
                    )
                }
            }
        case .artists:
            ForEach(Array(viewModel.topArtists.enumerated()), id: \.element.artist.id) { index, artist in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromArtist(artist).withPinState(
                        pinService.isItemPinned(itemId: artist.artist.id, itemType: .artists)
                    ),
                    rank: index + 1,
                    onPinToggle: {
                        Task {
                            await pinService.togglePin(itemId: artist.artist.id, itemType: .artists)
                        }
                    }
                )
                .onTapGesture {
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

#Preview {
    HomeView()
}