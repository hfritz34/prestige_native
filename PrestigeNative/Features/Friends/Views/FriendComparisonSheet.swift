//
//  FriendComparisonSheet.swift
//  Friend Comparison Modal Sheet
//
//  iOS equivalent of the compare modal from the web app, showing friend
//  comparison data for a specific album, artist, or track with stats
//

import SwiftUI

struct FriendComparisonSheet: View {
    let item: PrestigeItem
    let friends: [FriendResponse]
    
    @StateObject private var friendComparisonCache = FriendComparisonCache.shared
    @Environment(\.dismiss) private var dismiss
    @State private var friendStats: [FriendStat] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with item info
                headerSection
                
                // Friends list with comparison data
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if isLoading {
                            loadingView
                        } else if friendStats.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(friendStats.sorted(by: { $0.totalTime > $1.totalTime })) { stat in
                                FriendComparisonRow(
                                    friendStat: stat,
                                    item: item
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Compare with Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadFriendStats()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Item artwork
            CachedAsyncImage(
                url: item.imageUrl,
                placeholder: Image(systemName: getIconForItemType()),
                contentMode: .fill,
                maxWidth: 100,
                maxHeight: 100
            )
            .clipShape(itemType == .artist ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 12)))
            .shadow(radius: 8)
            
            // Item info
            VStack(spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(item.itemType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Summary
            Text("\(friends.count) friend\(friends.count == 1 ? "" : "s") listened to this \(item.itemType.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading friend data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No Data Available")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Unable to load listening data for your friends")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Data Loading
    
    private func loadFriendStats() async {
        isLoading = true
        
        // Load friend times concurrently
        var stats: [FriendStat] = []
        
        await withTaskGroup(of: FriendStat?.self) { group in
            for friend in friends {
                group.addTask {
                    let time = await friendComparisonCache.getFriendItemTime(
                        friendId: friend.friendId,
                        itemType: item.itemType.rawValue,
                        itemId: item.id
                    )
                    
                    // Convert seconds to minutes
                    let minutes = Int(time / 60)
                    
                    return FriendStat(
                        friend: friend,
                        totalTime: minutes,
                        formattedTime: TimeFormatter.formatMinutes(minutes)
                    )
                }
            }
            
            // Collect results
            for await stat in group {
                if let stat = stat {
                    stats.append(stat)
                }
            }
        }
        
        await MainActor.run {
            self.friendStats = stats
            self.isLoading = false
        }
    }
    
    // MARK: - Helper Properties
    
    private var itemType: PrestigeItem.PrestigeItemType {
        return item.itemType
    }
    
    private func getIconForItemType() -> String {
        switch item.itemType {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "music.mic"
        }
    }
}

// MARK: - Friend Comparison Row

struct FriendComparisonRow: View {
    let friendStat: FriendStat
    let item: PrestigeItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Friend profile picture
            if let profilePicUrl = friendStat.friend.profilePicUrl {
                CachedAsyncImage(
                    url: profilePicUrl,
                    placeholder: Image(systemName: "person.crop.circle.fill")
                )
                .artistImage(size: 50)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friendStat.friend.nickname ?? friendStat.friend.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("@\(friendStat.friend.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Listening stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(friendStat.formattedTime)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("listening time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Friend Stat Model

struct FriendStat: Identifiable {
    let id = UUID()
    let friend: FriendResponse
    let totalTime: Int // in minutes
    let formattedTime: String
}

// MARK: - Helper Extensions

extension TimeFormatter {
    static func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - AnyShape for dynamic shape types

struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

// MARK: - Preview

#Preview {
    FriendComparisonSheet(
        item: PrestigeItem(
            id: "album1",
            name: "Sample Album",
            imageUrl: "",
            itemType: .album
        ),
        friends: [
            FriendResponse(
                id: "friend1",
                name: "john_doe",
                nickname: "John",
                profilePicUrl: nil,
                bio: "Music enthusiast and coffee lover",
                isVerified: false,
                friendshipDate: Date(),
                mutualFriends: 0,
                status: 1,
                favoriteTracks: nil,
                favoriteAlbums: nil,
                favoriteArtists: nil,
                topTracks: nil,
                topAlbums: nil,
                topArtists: nil,
                ratedTracks: nil,
                ratedAlbums: nil,
                ratedArtists: nil,
                recentlyPlayed: nil
            ),
            FriendResponse(
                id: "friend2",
                name: "jane_smith",
                nickname: "Jane",
                profilePicUrl: nil,
                bio: "Vinyl collector and indie rock fan",
                isVerified: true,
                friendshipDate: Date(),
                mutualFriends: 0,
                status: 1,
                favoriteTracks: nil,
                favoriteAlbums: nil,
                favoriteArtists: nil,
                topTracks: nil,
                topAlbums: nil,
                topArtists: nil,
                ratedTracks: nil,
                ratedAlbums: nil,
                ratedArtists: nil,
                recentlyPlayed: nil
            )
        ]
    )
}