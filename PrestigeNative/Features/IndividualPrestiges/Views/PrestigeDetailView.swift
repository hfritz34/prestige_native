//
//  PrestigeDetailView.swift
//  Individual Prestige Detail View
//
//  Displays detailed information about a prestige item including
//  progress to next tier, total time, and statistics.
//

import SwiftUI

struct PrestigeDetailView: View {
    let item: PrestigeDisplayItem
    let rank: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var isPinned: Bool = false
    @State private var showComparisonView = false
    @State private var isPlaying = false
    @StateObject private var ratingViewModel = RatingViewModel()
    @StateObject private var pinService = PinService.shared
    
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
                await pinService.loadPinnedItems()
            }
            isPinned = pinService.isItemPinned(itemId: item.spotifyId, itemType: item.contentType)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Artwork
            AsyncImage(url: URL(string: item.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: item.contentType.iconName)
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 200, height: 200)
            .cornerRadius(12)
            .shadow(radius: 8)
            
            // Title and subtitle
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Now playing indicator
                    if isPlaying && item.contentType == .tracks {
                        HStack(spacing: 4) {
                            Text("🎵")
                                .font(.footnote)
                            Text("Now Playing")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
                
                if item.contentType == .tracks, let position = item.albumPosition {
                    StatCard(
                        title: "Album Rank",
                        value: "🏆 #\(position)",
                        icon: "number.square.fill",
                        color: .yellow
                    )
                } else if item.contentType == .tracks {
                    StatCard(
                        title: "Album Rank",
                        value: "...",
                        icon: "number.square.fill",
                        color: .gray
                    )
                } else {
                    StatCard(
                        title: "Play Count",
                        value: "\(Int(item.totalTimeMilliseconds / 1000 / 60 / 3))",
                        icon: "play.fill",
                        color: .green
                    )
                }
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
                Text("Rate this \(getContentTypeName())")
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
            // Three action buttons for tracks
            if item.contentType == .tracks {
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
                    
                    // View album
                    Button(action: {
                        // Navigate to album
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.stack")
                                .font(.title3)
                            Text("Album")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            
            // Play/Open on Spotify
            Button(action: {
                SpotifyPlaybackService.shared.playContent(
                    spotifyId: item.spotifyId,
                    type: item.contentType
                )
                withAnimation {
                    isPlaying = true
                }
            }) {
                HStack {
                    Image(systemName: item.contentType == .tracks ? "play.fill" : "arrow.up.right.square")
                    Text(item.contentType == .tracks ? "Play on Spotify" : "Open on Spotify")
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
                    Text("Share Prestige")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Rating Properties and Methods
    
    private var currentRating: Rating? {
        let itemType = getRatingItemType()
        return ratingViewModel.userRatings[itemType.rawValue]?.first { $0.itemId == item.spotifyId }
    }
    
    private func getRatingItemType() -> RatingItemType {
        switch item.contentType {
        case .tracks: return .track
        case .albums: return .album
        case .artists: return .artist
        }
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
            artists: item.contentType == .tracks ? [item.subtitle.components(separatedBy: " • ").first ?? ""] : nil,
            albumName: item.contentType == .tracks ? item.subtitle.components(separatedBy: " • ").last : nil,
            itemType: getRatingItemType()
        )
        
        await ratingViewModel.startRating(for: ratingItemData)
    }
    
    private func removeCurrentRating() async {
        if let rating = currentRating {
            await ratingViewModel.deleteRating(rating)
        }
    }
    
    private func getContentTypeName() -> String {
        switch item.contentType {
        case .tracks: return "Track"
        case .albums: return "Album"
        case .artists: return "Artist"
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
        let itemType: PrestigeCalculator.ItemType = {
            switch item.contentType {
            case .tracks: return .track
            case .albums: return .album
            case .artists: return .artist
            }
        }()
        
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

// MARK: - Supporting Views

struct PrestigeProgressBar: View {
    let progress: Double
    let currentTier: PrestigeLevel
    let nextTier: PrestigeLevel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                
                // Progress
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: currentTier.color) ?? .blue,
                                Color(hex: nextTier.color) ?? .purple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 12)
            }
        }
        .frame(height: 12)
    }
}

// MARK: - Extensions

// Note: Type detection now handled by explicit contentType property

extension ContentType {
    var iconName: String {
        switch self {
        case .tracks: return "music.note"
        case .albums: return "square.stack"
        case .artists: return "music.mic"
        }
    }
}


#Preview {
    PrestigeDetailView(
        item: PrestigeDisplayItem(
            name: "Bohemian Rhapsody",
            subtitle: "Queen • A Night at the Opera",
            imageUrl: "https://example.com/image.jpg",
            totalTimeMilliseconds: 180000,
            prestigeLevel: .gold,
            spotifyId: "4u7EnebtmKWzUH433cf5Qv",
            contentType: .tracks,
            albumPosition: 2,
            rating: 8.5,
            isPinned: false
        ),
        rank: 1
    )
}