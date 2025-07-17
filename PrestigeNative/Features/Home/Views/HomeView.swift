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
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // App Title
                Text("Prestige")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                // Type Selector
                typeSelector
                
                // Content List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 50)
                        } else {
                            contentList
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
                .refreshable {
                    viewModel.refreshData()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadHomeData()
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
    }
    
    // MARK: - View Components
    
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
        .padding(.bottom, 10)
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
}

#Preview {
    HomeView()
}