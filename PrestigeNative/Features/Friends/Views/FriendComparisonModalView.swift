//
//  FriendComparisonModalView.swift
//  Friend Comparison Modal
//
//  A polished SwiftUI modal that displays friend comparison data for tracks, albums, and artists.
//  Based on the web app's friend-item-modal.tsx implementation.
//

import SwiftUI

struct FriendComparisonModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var friendsService = FriendsService()
    
    let item: PrestigeDisplayItem
    let itemType: String // "track", "album", "artist"
    
    @State private var comparisonData: [EnhancedItemComparisonResponse] = []
    @State private var isLoading = false
    @State private var selectedComparison: EnhancedItemComparisonResponse?
    @State private var showingFriendDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with item info
                itemHeaderSection
                
                // Friends comparison list
                if isLoading {
                    loadingSection
                } else if comparisonData.isEmpty {
                    emptyStateSection
                } else {
                    friendsListSection
                }
                
                Spacer()
            }
            .navigationTitle("Friend Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .background(Color.black)
        }
        .sheet(isPresented: $showingFriendDetail) {
            if let comparison = selectedComparison {
                FriendComparisonDetailView(comparison: comparison)
            }
        }
        .onAppear {
            loadFriendsData()
        }
    }
    
    // MARK: - View Components
    
    private var itemHeaderSection: some View {
        VStack(spacing: 16) {
            // Item artwork
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
            .frame(width: 100, height: 100)
            .cornerRadius(12)
            .shadow(radius: 4)
            
            // Item info
            VStack(spacing: 8) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                Text(itemType.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Finding friends who listened to this \(itemType)...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("No Friends Found")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("None of your friends have listened to this \(itemType) yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
    
    private var friendsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(comparisonData, id: \.friendId) { comparison in
                    FriendComparisonRowView(
                        comparison: comparison,
                        itemType: itemType
                    ) {
                        selectedComparison = comparison
                        showingFriendDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFriendsData() {
        isLoading = true
        
        Task {
            guard let userId = AuthManager.shared.user?.id else {
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            // First get friends who have listened to the item
            let friends: [FriendResponse]
            switch itemType {
            case "track":
                friends = await friendsService.findFriendsWithTrack(trackId: item.spotifyId)
            case "album":
                friends = await friendsService.findFriendsWithAlbum(albumId: item.spotifyId)
            case "artist":
                friends = await friendsService.findFriendsWithArtist(artistId: item.spotifyId)
            default:
                friends = []
            }
            
            // For each friend, get enhanced comparison data (with prestige tiers)
            var comparisonData: [EnhancedItemComparisonResponse] = []
            
            for friend in friends {
                do {
                    let comparison = try await friendsService.getEnhancedItemComparison(
                        userId: userId,
                        itemId: item.spotifyId,
                        itemType: itemType,
                        friendId: friend.id
                    )
                    comparisonData.append(comparison)
                } catch {
                    print("Failed to get comparison for friend \(friend.id): \(error)")
                }
            }
            
            await MainActor.run {
                // Sort by friend listening time descending
                self.comparisonData = comparisonData.sorted { comparison1, comparison2 in
                    let time1 = comparison1.friendStats.listeningTime ?? 0
                    let time2 = comparison2.friendStats.listeningTime ?? 0
                    return time1 > time2
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Friend Comparison Row

struct FriendComparisonRowView: View {
    let comparison: EnhancedItemComparisonResponse
    let itemType: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Friend profile picture
                AsyncImage(url: URL(string: "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(String(comparison.friendNickname.prefix(1)).uppercased())
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // Friend info
                VStack(alignment: .leading, spacing: 4) {
                    Text(comparison.friendNickname)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let listeningTime = comparison.friendStats.listeningTime {
                        Text(TimeFormatter.formatListeningTime(listeningTime * 1000))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Prestige tier badge
                if let prestigeTier = comparison.friendStats.prestigeTier,
                   let tier = PrestigeLevel(rawValue: prestigeTier) {
                    PrestigeBadge(tier: tier)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}

#Preview {
    FriendComparisonModalView(
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
            isPinned: false,
            albumId: "sample-album-id",
            albumName: "A Night at the Opera"
        ),
        itemType: "track"
    )
}