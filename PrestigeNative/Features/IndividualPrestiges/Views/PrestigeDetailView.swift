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
                Text(item.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
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
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Time",
                    value: TimeFormatter.formatListeningTime(item.totalTimeMilliseconds),
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Prestige Tier",
                    value: item.prestigeLevel.displayName,
                    icon: "star.fill",
                    color: Color(hex: item.prestigeLevel.color) ?? .blue
                )
                
                if item.contentType == .tracks {
                    StatCard(
                        title: "Play Count",
                        value: "\(Int(item.totalTimeMilliseconds / 1000 / 60 / 3))", // Rough estimate (3 min per play)
                        icon: "play.fill",
                        color: .green
                    )
                }
                
                StatCard(
                    title: "First Played",
                    value: "2 months ago", // Placeholder
                    icon: "calendar",
                    color: .orange
                )
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                SpotifyPlaybackService.shared.playContent(
                    spotifyId: item.spotifyId,
                    type: item.contentType
                )
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
            contentType: .tracks
        ),
        rank: 1
    )
}