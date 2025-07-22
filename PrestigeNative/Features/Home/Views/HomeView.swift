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
    @State private var showingError = false
    @State private var selectedPrestige: PrestigeSelection?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // App Logo
                Image("prestige_white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                // Selectors
                HStack(spacing: 12) {
                    timeRangeSelector
                    typeSelector
                }
                .padding(.horizontal)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 50)
                        } else {
                            // Prestige Grid
                            if hasContent {
                                prestigeGridSection
                            } else {
                                emptyStateView
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .refreshable {
                    viewModel.refreshData()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if let userId = authManager.user?.id, !userId.isEmpty {
                viewModel.loadHomeData(for: userId)
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
    
    private var timeRangeSelector: some View {
        Menu {
            ForEach(PrestigeTimeRange.allCases, id: \.self) { range in
                Button(range.displayName) {
                    viewModel.selectedTimeRange = range
                }
            }
        } label: {
            HStack {
                Text(viewModel.selectedTimeRange.displayName)
                    .foregroundColor(.white)
                Image(systemName: "chevron.down")
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.8))
            .cornerRadius(8)
        }
    }
    
    private var typeSelector: some View {
        Menu {
            Button("Tracks") {
                viewModel.selectedContentType = .tracks
            }
            Button("Albums") {
                viewModel.selectedContentType = .albums
            }
            Button("Artists") {
                viewModel.selectedContentType = .artists
            }
        } label: {
            HStack {
                Text(viewModel.selectedContentType.displayName)
                    .foregroundColor(.white)
                Image(systemName: "chevron.down")
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        switch viewModel.selectedContentType {
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
        case .tracks:
            ForEach(Array(viewModel.topTracks.enumerated()), id: \.element.totalTime) { index, track in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromTrack(track),
                    rank: index + 1
                )
                .onTapGesture {
                    selectedPrestige = PrestigeSelection(
                        item: PrestigeDisplayItem.fromTrack(track),
                        rank: index + 1
                    )
                }
            }
        case .albums:
            ForEach(Array(viewModel.topAlbums.enumerated()), id: \.element.album.id) { index, album in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromAlbum(album),
                    rank: index + 1
                )
                .onTapGesture {
                    selectedPrestige = PrestigeSelection(
                        item: PrestigeDisplayItem.fromAlbum(album),
                        rank: index + 1
                    )
                }
            }
        case .artists:
            ForEach(Array(viewModel.topArtists.enumerated()), id: \.element.artist.id) { index, artist in
                PrestigeGridCard(
                    item: PrestigeDisplayItem.fromArtist(artist),
                    rank: index + 1
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
        case .tracks:
            EmptyStateView(
                icon: "music.note",
                title: "No Top Tracks",
                subtitle: "Start listening to build your prestige"
            )
        case .albums:
            EmptyStateView(
                icon: "square.stack",
                title: "No Top Albums",
                subtitle: "Listen to complete albums to build prestige"
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