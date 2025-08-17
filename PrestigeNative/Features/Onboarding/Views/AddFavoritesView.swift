//
//  AddFavoritesView.swift
//  Favorites Selection Screen for Onboarding
//
//  Screen where users select their favorite tracks, albums, and artists.
//  Equivalent to AddFavoritesPage.tsx from the web application.
//

import SwiftUI

struct AddFavoritesView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = AddFavoritesViewModel()
    @State private var selectedTab = "albums"
    @State private var searchText = ""
    @State private var isCompleting = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "Albums", icon: "square.stack", isSelected: selectedTab == "albums") {
                    selectedTab = "albums"
                    viewModel.selectedType = .albums
                    viewModel.loadCurrentFavorites()
                }
                
                TabButton(title: "Songs", icon: "music.note", isSelected: selectedTab == "tracks") {
                    selectedTab = "tracks"
                    viewModel.selectedType = .tracks
                    viewModel.loadCurrentFavorites()
                }
                
                TabButton(title: "Artists", icon: "music.mic", isSelected: selectedTab == "artists") {
                    selectedTab = "artists"
                    viewModel.selectedType = .artists
                    viewModel.loadCurrentFavorites()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            
            // Current favorites section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Current Favorites")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Complete Setup") {
                        Task {
                            await completeSetup()
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .disabled(isCompleting)
                }
                .padding(.horizontal)
                
                // Favorites list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if viewModel.currentFavorites.isEmpty {
                            Text("No favorites selected yet")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(viewModel.currentFavorites, id: \.id) { item in
                                FavoriteChip(item: item) {
                                    viewModel.toggleFavorite(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 60)
            }
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            
            // Add spacing between sections
            Spacer()
                .frame(height: 20)
            
            // Search section
            VStack(spacing: 16) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for \(getSearchPlaceholder())", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _, newValue in
                            viewModel.searchQuery = newValue
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Keyboard dismiss button
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Search results
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.isSearching {
                            ProgressView()
                                .padding(.vertical, 50)
                        } else {
                            ForEach(viewModel.searchResults, id: \.id) { item in
                                SearchResultRow(item: item, isSelected: viewModel.isFavorite(item)) {
                                    viewModel.toggleFavorite(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Select Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadCurrentFavorites()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private func getSearchPlaceholder() -> String {
        switch selectedTab {
        case "tracks": return "songs..."
        case "albums": return "albums..."
        case "artists": return "artists..."
        default: return "items..."
        }
    }
    
    private func completeSetup() async {
        await MainActor.run {
            isCompleting = true
        }
        
        do {
            // Update user setup status
            _ = try await APIClient.shared.updateUserSetupStatus(true)
            
            await MainActor.run {
                isCompleting = false
                // Dismiss to main app
                authManager.userIsSetup = true
            }
        } catch {
            await MainActor.run {
                isCompleting = false
                viewModel.errorMessage = "Failed to complete setup: \(error.localizedDescription)"
                viewModel.showingError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct FavoriteChip: View {
    let item: SpotifyItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(16)
    }
}

struct SearchResultRow: View {
    let item: SpotifyItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // Item image
            CachedAsyncImage(
                url: item.imageUrl,
                placeholder: Image(systemName: getIconForType()),
                contentMode: .fill,
                maxWidth: 50,
                maxHeight: 50
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(item.subtitle ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Selection indicator
            Image(systemName: isSelected ? "heart.fill" : "heart")
                .foregroundColor(isSelected ? .red : .gray)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func getIconForType() -> String {
        switch item.type {
        case "track": return "music.note"
        case "album": return "square.stack"
        case "artist": return "music.mic"
        default: return "music.note"
        }
    }
}

#Preview {
    NavigationView {
        AddFavoritesView()
            .environmentObject(AuthManager.shared)
    }
}