//
//  HomeView.swift
//  Home Screen - Main landing page after authentication
//
//  Shows recently played tracks and top tracks with prestige badges.
//  Equivalent to Dashboard.tsx from the web application.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    headerSection
                    recentlyPlayedSection
                    topTracksSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refreshData()
            }
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
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Welcome back!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Text("Track your musical journey")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Recently Played")
            
            if viewModel.recentlyPlayed.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "music.note",
                    title: "No Recent Tracks",
                    subtitle: "Start listening to see your recently played tracks"
                )
            } else {
                recentTracksScrollView
            }
        }
    }
    
    private var topTracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Your Top Tracks")
            
            if viewModel.topTracks.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "star",
                    title: "No Top Tracks Yet",
                    subtitle: "Keep listening to build your top tracks list"
                )
            } else {
                topTracksList
            }
        }
    }
    
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("See All") {
                // TODO: Navigate to full view
            }
            .font(.caption)
            .foregroundColor(.purple)
        }
        .padding(.horizontal)
    }
    
    private var recentTracksScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(viewModel.recentlyPlayed, id: \.id) { track in
                    RecentTrackCard(track: track)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var topTracksList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(viewModel.topTracks.prefix(5).enumerated()), id: \.element.totalTime) { index, track in
                TopTrackRow(track: track, rank: index + 1)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
}