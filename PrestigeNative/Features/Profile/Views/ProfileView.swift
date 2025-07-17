//
//  ProfileView.swift
//  User Profile Screen
//
//  Displays user stats, prestige badges, and top music content.
//  Equivalent to Profile.tsx from the web application.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingError = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Stats Overview
                    statsSection
                    
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Content Tabs
                    contentTabs
                    
                    // Tab Content
                    tabContent
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refreshData()
            }
        }
        .onAppear {
            viewModel.loadProfileData()
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
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Profile Picture
            AsyncImage(url: URL(string: viewModel.userProfile?.profilePictureUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            // User Info
            VStack(spacing: 4) {
                Text(viewModel.userProfile?.nickname ?? "Loading...")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let email = viewModel.userProfile?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Listening Time",
                value: viewModel.totalListeningTime.listeningTimeString,
                icon: "clock.fill",
                color: .blue
            )
            
            StatCard(
                title: "Top Prestige",
                value: viewModel.topPrestigeLevel.displayName,
                icon: "star.fill",
                color: .purple
            )
            
            StatCard(
                title: "Artists",
                value: "\(viewModel.totalUniqueArtists)",
                icon: "music.mic",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
    
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        viewModel.changeTimeRange(range)
                    }) {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(viewModel.selectedTimeRange == range ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedTimeRange == range ? Color.purple : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(viewModel.selectedTimeRange == range ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var contentTabs: some View {
        HStack(spacing: 0) {
            TabButton(title: "Tracks", icon: "music.note", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Albums", icon: "square.stack", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: "Artists", icon: "music.mic", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var tabContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .padding(.vertical, 50)
        } else {
            switch selectedTab {
            case 0:
                topTracksContent
            case 1:
                topAlbumsContent
            case 2:
                topArtistsContent
            default:
                EmptyView()
            }
        }
    }
    
    private var topTracksContent: some View {
        VStack(spacing: 8) {
            if viewModel.topTracks.isEmpty {
                EmptyStateView(
                    icon: "music.note",
                    title: "No Top Tracks",
                    subtitle: "Start listening to build your top tracks"
                )
            } else {
                ForEach(Array(viewModel.topTracks.prefix(10).enumerated()), id: \.element.totalTime) { index, track in
                    TopTrackRow(track: track, rank: index + 1)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var topAlbumsContent: some View {
        VStack(spacing: 16) {
            if viewModel.topAlbums.isEmpty {
                EmptyStateView(
                    icon: "square.stack",
                    title: "No Top Albums",
                    subtitle: "Listen to complete albums to see them here"
                )
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.topAlbums.prefix(10), id: \.album.id) { albumData in
                        AlbumCard(albumData: albumData)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var topArtistsContent: some View {
        VStack(spacing: 8) {
            if viewModel.topArtists.isEmpty {
                EmptyStateView(
                    icon: "music.mic",
                    title: "No Top Artists",
                    subtitle: "Explore more artists to see them here"
                )
            } else {
                ForEach(Array(viewModel.topArtists.prefix(10).enumerated()), id: \.element.artist.id) { index, artistData in
                    ArtistRow(artistData: artistData, rank: index + 1)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ProfileView()
}