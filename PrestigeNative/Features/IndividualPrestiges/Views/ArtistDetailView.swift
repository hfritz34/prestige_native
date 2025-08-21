//
//  ArtistDetailView.swift
//  Individual Artist Detail View with Album List
//
//  Shows artist information with expandable album list, pin functionality,
//  and prestige level similar to Prestige.web artist pages.
//

import SwiftUI

struct ArtistDetailView: View {
    let item: PrestigeDisplayItem
    let rank: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var isPinned: Bool = false
    @State private var showComparisonView = false
    @State private var isPlaying = false
    @StateObject private var ratingViewModel = RatingViewModel()
    @StateObject private var pinService = PinService.shared
    @State private var ratedAlbums: [RatedAlbumItem] = []
    @State private var isLoadingAlbums = false
    @State private var showAllAlbums = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with artwork
                    headerSection
                    
                    // Prestige info and progress
                    prestigeInfoSection
                    
                    // Statistics
                    statisticsSection
                    
                    // Rated Albums Section
                    ratedAlbumsSection
                    
                    // Rating Section
                    ratingSection
                    
                    // Actions
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .sheet(isPresented: $ratingViewModel.showRatingModal) {
                RatingModal()
                    .environmentObject(ratingViewModel)
            }
        }
        .onAppear {
            Task {
                await loadItemRating()
                await loadRatedAlbums()
                await pinService.loadPinnedItems()
            }
            isPinned = pinService.isItemPinned(itemId: item.spotifyId, itemType: item.contentType)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Artist artwork (circular for artists)
            AsyncImage(url: URL(string: item.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.mic")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            .shadow(radius: 8)
            
            // Artist name and subtitle
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Pin indicator
                    if isPinned {
                        Text("📌")
                            .font(.title3)
                    }
                }
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Artist rank
                Text("Artist Rank #\(rank)")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var prestigeInfoSection: some View {
        VStack(spacing: 20) {
            // Current prestige badge
            PrestigeBadge(
                tier: item.prestigeLevel
            )
            
            // Progress to next tier
            if let progress = progressToNextTier {
                VStack(spacing: 12) {
                    HStack {
                        Text("Progress to \(progress.nextTier.displayName)")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(progress.percentage))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    PrestigeProgressBar(
                        progress: progress.percentage / 100,
                        currentTier: item.prestigeLevel,
                        nextTier: progress.nextTier
                    )
                    
                    Text("\(progress.remainingTime) more to reach \(progress.nextTier.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Minutes",
                    value: TimeFormatter.formatListeningTime(item.totalTimeMilliseconds),
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Prestige Level",
                    value: item.prestigeLevel.displayName,
                    icon: "star.fill",
                    color: Color(hex: item.prestigeLevel.color) ?? .blue
                )
                
                StatCard(
                    title: "Rated Albums",
                    value: "\(ratedAlbums.count)",
                    icon: "square.stack.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var ratedAlbumsSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Rated Albums")
                    .font(.headline)
                
                Spacer()
                
                if !ratedAlbums.isEmpty {
                    Button(showAllAlbums ? "Show Less" : "Show All") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllAlbums.toggle()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            // Albums content
            if isLoadingAlbums {
                CompactBeatVisualizer(isPlaying: true)
                    .padding(.vertical, 20)
            } else if ratedAlbums.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No Rated Albums")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Rate albums by this artist to see them here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    let displayedAlbums = showAllAlbums ? ratedAlbums : Array(ratedAlbums.prefix(3))
                    
                    ForEach(Array(displayedAlbums.enumerated()), id: \.element.id) { index, album in
                        RatedAlbumRow(
                            album: album,
                            rank: index + 1
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var ratingSection: some View {
        VStack(spacing: 16) {
            Text("Rating")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let rating = currentRating {
                // Show existing rating
                ratedItemView(rating)
            } else {
                // Show rate button
                unratedItemView
            }
        }
    }
    
    private func ratedItemView(_ rating: Rating) -> some View {
        VStack(spacing: 16) {
            // Rating display
            HStack {
                RatingBadge(score: rating.personalScore, size: .large)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let category = rating.category {
                        Text(category.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Score: \(rating.displayScore)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Rate Again") {
                    Task {
                        await startRatingFlow()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Button("Remove Rating") {
                    Task {
                        await removeCurrentRating()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var unratedItemView: some View {
        Button(action: {
            Task {
                await startRatingFlow()
            }
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Rate this Artist")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Artist-specific action buttons
            HStack(spacing: 12) {
                // Pin button
                Button(action: {
                    togglePin()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.title3)
                        Text(isPinned ? "Pinned" : "Pin")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isPinned ? Color.yellow : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(isPinned ? .black : .primary)
                    .cornerRadius(10)
                }
                
                // Compare with friends
                Button(action: {
                    showComparisonView = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                        Text("Compare")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // View discography
                Button(action: {
                    // Navigate to discography
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "music.note.list")
                            .font(.title3)
                        Text("Albums")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            // Open on Spotify
            Button(action: {
                SpotifyPlaybackService.shared.playContent(
                    spotifyId: item.spotifyId,
                    type: item.contentType
                )
            }) {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("Open Artist on Spotify")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Share button
            Button(action: {
                showingShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Artist")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadRatedAlbums() async {
        isLoadingAlbums = true
        
        // TODO: Replace with actual API call
        // For now, simulate loading with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ratedAlbums = createMockRatedAlbums()
            isLoadingAlbums = false
        }
    }
    
    private func createMockRatedAlbums() -> [RatedAlbumItem] {
        // Mock data - replace with actual API call
        return (1...5).map { index in
            RatedAlbumItem(
                id: "album_\(index)",
                albumName: "Album \(index)",
                imageUrl: "https://example.com/album\(index).jpg",
                rating: Double.random(in: 6.0...10.0),
                listeningTimeMinutes: Int.random(in: 200...2000),
                trackCount: Int.random(in: 8...16),
                releaseYear: 2020 - index
            )
        }
    }
    
    // MARK: - Rating Properties and Methods
    
    private var currentRating: Rating? {
        let itemType = getRatingItemType()
        return ratingViewModel.userRatings[itemType.rawValue]?.first { $0.itemId == item.spotifyId }
    }
    
    private func getRatingItemType() -> RatingItemType {
        return .artist
    }
    
    private func loadItemRating() async {
        let itemType = getRatingItemType()
        await ratingViewModel.loadUserRatings()
        ratingViewModel.selectedItemType = itemType
    }
    
    private func startRatingFlow() async {
        let ratingItemData = RatingItemData(
            id: item.spotifyId,
            name: item.name,
            imageUrl: item.imageUrl,
            artists: nil,
            albumName: nil,
            itemType: getRatingItemType()
        )
        
        await ratingViewModel.startRating(for: ratingItemData)
    }
    
    private func removeCurrentRating() async {
        if let rating = currentRating {
            await ratingViewModel.deleteRating(rating)
        }
    }
    
    // MARK: - Action Methods
    
    private func togglePin() {
        Task {
            let newPinState = await pinService.togglePin(
                itemId: item.spotifyId,
                itemType: item.contentType
            )
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPinned = newPinState
            }
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var progressToNextTier: (percentage: Double, nextTier: PrestigeLevel, remainingTime: String)? {
        let totalMinutes = item.totalTimeMilliseconds / 1000 / 60
        let itemType: PrestigeCalculator.ItemType = .artist
        
        guard let nextTierInfo = PrestigeCalculator.getNextTierInfo(
            currentLevel: item.prestigeLevel,
            totalTimeMinutes: totalMinutes,
            itemType: itemType
        ) else { return nil }
        
        // Calculate progress within current tier
        let thresholds = getThresholds(for: itemType)
        let currentTierIndex = item.prestigeLevel.order
        
        // Get the threshold for the current tier (what was needed to reach it)
        let currentTierThreshold = currentTierIndex > 0 ? thresholds[currentTierIndex - 1] : 0
        
        // Get the threshold for the next tier
        let nextTierThreshold = currentTierIndex < thresholds.count ? thresholds[currentTierIndex] : thresholds.last ?? 0
        
        // Calculate progress from current tier to next tier
        let progressInCurrentTier = Double(totalMinutes - currentTierThreshold)
        let tierRange = Double(nextTierThreshold - currentTierThreshold)
        
        let percentage = tierRange > 0 ? (progressInCurrentTier / tierRange) * 100 : 0
        
        return (
            percentage: min(max(percentage, 0), 100),
            nextTier: nextTierInfo.nextLevel,
            remainingTime: formatTime(Double(nextTierInfo.minutesNeeded))
        )
    }
    
    private func getThresholds(for itemType: PrestigeCalculator.ItemType) -> [Int] {
        switch itemType {
        case .track:
            return [60, 150, 300, 500, 800, 1200, 1600, 2200, 3000, 6000, 15000]
        case .album:
            return [200, 350, 500, 1000, 2000, 4000, 6000, 10000, 15000, 30000, 50000]
        case .artist:
            return [400, 750, 1200, 2000, 3000, 6000, 10000, 15000, 25000, 50000, 100000]
        }
    }
    
    private func formatTime(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Supporting Models

struct RatedAlbumItem: Identifiable {
    let id: String
    let albumName: String
    let imageUrl: String?
    let rating: Double
    let listeningTimeMinutes: Int
    let trackCount: Int
    let releaseYear: Int
}

// MARK: - Supporting Views

struct RatedAlbumRow: View {
    let album: RatedAlbumItem
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Album rank
            Text("\(rank)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .frame(width: 24, alignment: .center)
            
            // Album artwork
            AsyncImage(url: URL(string: album.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "square.stack")
                            .foregroundColor(.gray)
                            .font(.caption)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Album info
            VStack(alignment: .leading, spacing: 2) {
                Text(album.albumName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(album.releaseYear)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(album.trackCount) tracks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Rating and stats
            VStack(alignment: .trailing, spacing: 2) {
                RatingBadge(score: album.rating, size: .small)
                
                Text(TimeFormatter.formatListeningTime(album.listeningTimeMinutes * 60 * 1000))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ArtistDetailView(
        item: PrestigeDisplayItem(
            name: "The Beatles",
            subtitle: "Rock • Liverpool",
            imageUrl: "https://example.com/beatles.jpg",
            totalTimeMilliseconds: 3600000,
            prestigeLevel: .gold,
            spotifyId: "3WrFJ7ztbogyGnTHbHJFl2",
            contentType: .artists,
            albumPosition: nil,
            rating: 9.2,
            isPinned: false
        ),
        rank: 1
    )
}