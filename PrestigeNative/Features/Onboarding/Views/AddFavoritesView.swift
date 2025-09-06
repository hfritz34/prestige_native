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
    
    // Adaptive grid columns with improved device compatibility and NaN protection
    private var adaptiveGridColumns: [GridItem] {
        let screenWidth = UIScreen.main.bounds.width
        
        // Safety check for invalid screen width
        guard screenWidth.isFinite && screenWidth > 0 else {
            // Fallback to safe static grid with adjusted spacing for artists
            let spacing: CGFloat = (selectedTab == "artists") ? 12 : 8
            return [
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: spacing),
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: spacing),
                GridItem(.flexible(minimum: 100, maximum: 140), spacing: spacing)
            ]
        }
        
        let padding: CGFloat = 32 // Total horizontal padding (16 on each side)
        
        // Adjust spacing based on item type - circular artist images need more space
        let spacing: CGFloat = (selectedTab == "artists") ? 12 : 8
        let totalSpacing: CGFloat = spacing * 2 // Space between 3 columns
        let availableWidth = screenWidth - padding - totalSpacing
        let itemWidth = availableWidth / 3
        
        // For artists, use slightly smaller max width to prevent circular overlap
        let maxWidthMultiplier: CGFloat = (selectedTab == "artists") ? 1.1 : 1.2
        
        // Ensure minimum and maximum constraints work across all devices with NaN protection
        let minWidth = max(itemWidth * 0.8, 90).isFinite ? max(itemWidth * 0.8, 90) : 90
        let maxWidth = min(itemWidth * maxWidthMultiplier, 160).isFinite ? min(itemWidth * maxWidthMultiplier, 160) : 160
        
        // Final safety check
        let safeMinWidth = minWidth.isFinite ? minWidth : 90
        let safeMaxWidth = maxWidth.isFinite ? maxWidth : 160
        let safeSpacing = spacing.isFinite ? spacing : 8
        
        return [
            GridItem(.flexible(minimum: safeMinWidth, maximum: safeMaxWidth), spacing: safeSpacing),
            GridItem(.flexible(minimum: safeMinWidth, maximum: safeMaxWidth), spacing: safeSpacing),
            GridItem(.flexible(minimum: safeMinWidth, maximum: safeMaxWidth), spacing: safeSpacing)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "Albums", icon: "square.stack", isSelected: selectedTab == "albums") {
                    selectedTab = "albums"
                    viewModel.selectedType = .albums
                    searchText = "" // Clear search text when switching tabs
                    viewModel.searchResults = [] // Clear search results when switching tabs
                    viewModel.loadCurrentFavorites()
                }
                
                TabButton(title: "Songs", icon: "music.note", isSelected: selectedTab == "tracks") {
                    selectedTab = "tracks"
                    viewModel.selectedType = .tracks
                    searchText = "" // Clear search text when switching tabs
                    viewModel.searchResults = [] // Clear search results when switching tabs
                    viewModel.loadCurrentFavorites()
                }
                
                TabButton(title: "Artists", icon: "music.mic", isSelected: selectedTab == "artists") {
                    selectedTab = "artists"
                    viewModel.selectedType = .artists
                    searchText = "" // Clear search text when switching tabs
                    viewModel.searchResults = [] // Clear search results when switching tabs
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
                
                // Search results - Grid Layout
                ScrollView {
                    if viewModel.isSearching {
                        ProgressView("Searching...")
                            .padding(.vertical, 50)
                    } else if viewModel.isLoadingCategory {
                        ProgressView("Loading \(getSearchPlaceholder())...")
                            .padding(.vertical, 50)
                    } else {
                        LazyVGrid(columns: adaptiveGridColumns, spacing: selectedTab == "artists" ? 16 : 12) {
                            ForEach(viewModel.searchResults, id: \.id) { item in
                                FavoritesGridCard(
                                    item: item,
                                    isSelected: viewModel.isFavorite(item)
                                ) {
                                    viewModel.toggleFavorite(item)
                                }
                            }
                        }
                        .padding(.horizontal, selectedTab == "artists" ? 20 : 16)
                    }
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
            // Always save favorites during onboarding to ensure they are persisted
            print("🔄 Onboarding completion - Current favorites: \(viewModel.currentFavorites.count), Has unsaved changes: \(viewModel.hasUnsavedChanges)")
            
            if !viewModel.currentFavorites.isEmpty || viewModel.hasUnsavedChanges {
                print("🔄 Saving favorites during onboarding completion...")
                await viewModel.saveFavorites()
                
                // Check if saving failed
                if viewModel.showingError {
                    print("❌ Favorite saving failed during onboarding: \(viewModel.errorMessage)")
                    await MainActor.run {
                        isCompleting = false
                    }
                    return
                }
                print("✅ Favorites saved successfully during onboarding")
            } else {
                print("ℹ️ No favorites to save during onboarding")
            }
            
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


#Preview {
    NavigationView {
        AddFavoritesView()
            .environmentObject(AuthManager.shared)
    }
}