//
//  AlbumDetailView.swift
//  Album Detail View with Track List
//
//  Shows album information with expandable track list showing
//  album rankings, rated vs unrated tracks, and progress indicator
//

import SwiftUI

struct AlbumDetailView: View {
    let album: UserAlbumResponse
    let rank: Int
    
    @State private var showAllTracks = false
    @State private var albumTracks: [AlbumTrackItem] = []
    @State private var isLoadingTracks = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with album art and info
                    albumHeaderSection
                    
                    // Progress indicator
                    albumProgressSection
                    
                    // Show All Tracks toggle
                    trackListSection
                    
                    // Action buttons
                    actionButtonsSection
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
        .onAppear {
            loadAlbumTracks()
        }
    }
    
    // MARK: - View Sections
    
    private var albumHeaderSection: some View {
        VStack(spacing: 16) {
            // Album artwork
            CachedAsyncImage(
                url: album.album.images.first?.url ?? "",
                placeholder: Image(systemName: "square.stack"),
                contentMode: .fit,
                maxWidth: 200,
                maxHeight: 200
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 12)
            
            // Album info
            VStack(spacing: 8) {
                HStack {
                    Text(album.album.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Pin indicator
                    if album.isPinned == true {
                        Text("📌")
                            .font(.title3)
                    }
                }
                
                Text(album.album.artists.first?.name ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Album rank
                Text("Album Rank #\(rank)")
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
    
    private var albumProgressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Album Progress")
                    .font(.headline)
                Spacer()
                
                if isCompleteAlbum {
                    HStack(spacing: 4) {
                        Text("⭐")
                        Text("Complete!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Progress indicator
            let ratedCount = albumTracks.filter { $0.isRated }.count
            let totalCount = albumTracks.count
            
            if totalCount > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("\(ratedCount) of \(totalCount) tracks rated")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(Double(ratedCount) / Double(totalCount) * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: Double(ratedCount), total: Double(totalCount))
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        .scaleEffect(y: 2)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var trackListSection: some View {
        VStack(spacing: 16) {
            // Toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showAllTracks.toggle()
                }
            }) {
                HStack {
                    Text(showAllTracks ? "Hide Tracks" : "Show All Tracks")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: showAllTracks ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .rotationEffect(.degrees(showAllTracks ? 180 : 0))
                }
                .foregroundColor(.primary)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Expanded track list
            if showAllTracks {
                trackListContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var trackListContent: some View {
        VStack(spacing: 8) {
            if isLoadingTracks {
                CompactBeatVisualizer(isPlaying: true)
                    .padding(.vertical, 20)
            } else if albumTracks.isEmpty {
                Text("No track data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(albumTracks.indices, id: \.self) { index in
                        AlbumTrackRow(
                            track: albumTracks[index],
                            trackNumber: index + 1
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Play/Open on Spotify
            Button(action: {
                // TODO: Open album on Spotify
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play Album on Spotify")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Share button
            Button(action: {
                // TODO: Share album
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Album")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isCompleteAlbum: Bool {
        let ratedCount = albumTracks.filter { $0.isRated }.count
        return ratedCount == albumTracks.count && albumTracks.count > 0
    }
    
    // MARK: - Data Loading
    
    private func loadAlbumTracks() {
        isLoadingTracks = true
        
        Task {
            do {
                // Get album tracks from Spotify API
                let tracks: [AlbumTrackItem] = try await APIClient.shared.request(
                    endpoint: "spotify/album/\(album.album.id)/tracks",
                    method: .GET
                )
                
                await MainActor.run {
                    albumTracks = tracks
                    isLoadingTracks = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading album tracks: \(error)")
                    albumTracks = []
                    isLoadingTracks = false
                }
            }
        }
    }
}

// MARK: - Album Track Item Model

struct AlbumTrackItem: Identifiable {
    let id: String
    let name: String
    let artists: [String]
    let albumRanking: Int? // 1 = best track in album
    let isRated: Bool
    let isPinned: Bool
    let isFavorite: Bool
}

// MARK: - Album Track Row

struct AlbumTrackRow: View {
    let track: AlbumTrackItem
    let trackNumber: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Album ranking (bold)
            Group {
                if let ranking = track.albumRanking {
                    Text("\(ranking)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .frame(width: 24, alignment: .center)
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 24, alignment: .center)
                }
            }
            
            // Track number
            Text("\(trackNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .center)
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(track.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Status indicators
                    HStack(spacing: 4) {
                        if track.isPinned {
                            Text("📌")
                                .font(.caption)
                        }
                        if track.isFavorite {
                            Text("❤️")
                                .font(.caption)
                        }
                    }
                }
                
                Text(track.artists.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            track.isRated 
                ? Color(UIColor.secondarySystemBackground)
                : Color(UIColor.systemBackground).opacity(0.5)
        )
        .cornerRadius(8)
        .opacity(track.isRated ? 1.0 : 0.6)
    }
}

// MARK: - Preview

#Preview {
    AlbumDetailView(
        album: UserAlbumResponse(
            totalTime: 3600,
            album: AlbumResponse(
                id: "album1",
                name: "Sample Album",
                images: [],
                artists: [TrackResponse.ArtistInfo(id: "artist1", name: "Sample Artist")]
            ),
            userId: "user1",
            isPinned: false,
            rating: 8.5
        ),
        rank: 5
    )
}