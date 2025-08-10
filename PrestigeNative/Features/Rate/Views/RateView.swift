//
//  RateView.swift
//  Rating View - Main rating interface
//
//  Provides a clean, native iOS interface for rating and managing
//  user's music library with search, filtering, and rating actions.
//

import SwiftUI

struct RateView: View {
    @StateObject private var viewModel = RatingViewModel()
    @State private var searchText = ""
    @State private var selectedTab: RatingTab = .unrated
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search
                headerSection
                
                // Item type filter
                itemTypeFilter
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                contentSection
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemBackground))
            .sheet(isPresented: $viewModel.showRatingModal) {
                RatingModal()
                    .environmentObject(viewModel)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadInitialData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Rate")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search your library...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                    .onChange(of: searchText) { newValue in
                        Task {
                            await viewModel.searchLibrary(query: newValue)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: { 
                        searchText = ""
                        viewModel.clearSearch()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)
        }
    }
    
    private var itemTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RatingItemType.allCases, id: \.self) { itemType in
                    ItemTypeButton(
                        itemType: itemType,
                        isSelected: viewModel.selectedItemType == itemType,
                        action: {
                            viewModel.selectedItemType = itemType
                            Task {
                                await viewModel.loadUserRatings()
                                await viewModel.loadUnratedItems()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(RatingTab.allCases, id: \.self) { tab in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab 
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab.title)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .medium)
                            .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? .blue : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            loadingView
        } else if !searchText.isEmpty {
            searchResultsView
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    switch selectedTab {
                    case .unrated:
                        unratedContent
                    case .topRated:
                        topRatedContent
                    case .yourRatings:
                        yourRatingsContent
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<5, id: \.self) { _ in
                RatingItemLoadingCard()
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var unratedContent: some View {
        Group {
            if filteredUnratedItems.isEmpty {
                EmptyStateView(
                    icon: "music.note",
                    title: "All Caught Up!",
                    subtitle: "You've rated all your \(viewModel.selectedItemType.displayName.lowercased())"
                )
                .padding(.top, 60)
            } else {
                ForEach(filteredUnratedItems, id: \.id) { item in
                    RatingItemCard(
                        itemData: item,
                        rating: nil,
                        showRating: false
                    ) {
                        Task {
                            await viewModel.startRating(for: item)
                        }
                    }
                }
            }
        }
    }
    
    private var topRatedContent: some View {
        Group {
            if topRatedItems.isEmpty {
                EmptyStateView(
                    icon: "star.fill",
                    title: "No Top Ratings Yet",
                    subtitle: "Rate some \(viewModel.selectedItemType.displayName.lowercased()) to see your favorites here"
                )
                .padding(.top, 60)
            } else {
                ForEach(Array(topRatedItems.enumerated()), id: \.element.id) { index, item in
                    RatingItemCard(
                        itemData: item.itemData,
                        rating: item.rating,
                        showRating: true
                    ) {
                        Task {
                            await viewModel.startRating(for: item.itemData)
                        }
                    }
                    .contextMenu {
                        Button("Remove Rating", systemImage: "trash", role: .destructive) {
                            Task {
                                await viewModel.deleteRating(item.rating)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var yourRatingsContent: some View {
        Group {
            if allRatedItems.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No Ratings Yet",
                    subtitle: "Start rating \(viewModel.selectedItemType.displayName.lowercased()) to build your collection"
                )
                .padding(.top, 60)
            } else {
                ForEach(allRatedItems, id: \.id) { item in
                    RatingItemCard(
                        itemData: item.itemData,
                        rating: item.rating,
                        showRating: true
                    ) {
                        Task {
                            await viewModel.startRating(for: item.itemData)
                        }
                    }
                    .contextMenu {
                        Button("Rate Again", systemImage: "star.circle") {
                            Task {
                                await viewModel.startRating(for: item.itemData)
                            }
                        }
                        
                        Button("Remove Rating", systemImage: "trash", role: .destructive) {
                            Task {
                                await viewModel.deleteRating(item.rating)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var searchResultsView: some View {
        VStack(spacing: 16) {
            if viewModel.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if viewModel.searchResults.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results",
                    subtitle: "No items found for '\(searchText)'"
                )
                .padding(.top, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("\(viewModel.searchResults.count) result\(viewModel.searchResults.count == 1 ? "" : "s") for '\(searchText)'")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(viewModel.searchResults, id: \.id) { item in
                            let existingRating = viewModel.userRatings[item.itemType.rawValue]?.first { $0.itemId == item.id }
                            
                            RatingItemCard(
                                itemData: item,
                                rating: existingRating,
                                showRating: existingRating != nil
                            ) {
                                Task {
                                    await viewModel.startRating(for: item)
                                }
                            }
                            .contextMenu {
                                if let rating = existingRating {
                                    Button("Rate Again", systemImage: "star.circle") {
                                        Task {
                                            await viewModel.startRating(for: item)
                                        }
                                    }
                                    
                                    Button("Remove Rating", systemImage: "trash", role: .destructive) {
                                        Task {
                                            await viewModel.deleteRating(rating)
                                        }
                                    }
                                } else {
                                    Button("Rate Item", systemImage: "star") {
                                        Task {
                                            await viewModel.startRating(for: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredUnratedItems: [RatingItemData] {
        let items = searchText.isEmpty ? viewModel.unratedItems : 
                   viewModel.unratedItems.filter { item in
                       item.name.localizedCaseInsensitiveContains(searchText) ||
                       (item.artists?.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ?? false)
                   }
        return items
    }
    
    private var topRatedItems: [RatedItem] {
        let ratings = viewModel.filteredRatings
            .filter { $0.personalScore >= 7.0 } // Top rated threshold
            .sorted { $0.personalScore > $1.personalScore }
            .prefix(20) // Show top 20
        
        return Array(ratings).compactMap { rating in
            // Create RatingItemData from rating - this would need to be fetched from API
            // For now, using placeholder data
            let itemData = RatingItemData(
                id: rating.itemId,
                name: "Item \(rating.itemId)", // Placeholder
                imageUrl: nil,
                artists: nil,
                albumName: nil,
                itemType: rating.itemType
            )
            return RatedItem(id: rating.id, rating: rating, itemData: itemData)
        }
    }
    
    private var allRatedItems: [RatedItem] {
        let ratings = searchText.isEmpty ? viewModel.filteredRatings :
                     viewModel.filteredRatings.filter { rating in
                         // This would need item data to search properly
                         return true // Placeholder
                     }
        
        return ratings.sorted { $0.personalScore > $1.personalScore }.compactMap { rating in
            let itemData = RatingItemData(
                id: rating.itemId,
                name: "Item \(rating.itemId)", // Placeholder
                imageUrl: nil,
                artists: nil,
                albumName: nil,
                itemType: rating.itemType
            )
            return RatedItem(id: rating.id, rating: rating, itemData: itemData)
        }
    }
}

// MARK: - Supporting Views

struct ItemTypeButton: View {
    let itemType: RatingItemType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: itemType.iconName)
                    .font(.system(size: 14, weight: .medium))
                
                Text(itemType.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Supporting Types

enum RatingTab: CaseIterable {
    case unrated
    case topRated
    case yourRatings
    
    var title: String {
        switch self {
        case .unrated: return "Unrated"
        case .topRated: return "Top Rated"
        case .yourRatings: return "Your Ratings"
        }
    }
}

// MARK: - Extensions

extension RatingItemType {
    var iconName: String {
        switch self {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "person.fill"
        }
    }
}

#Preview {
    RateView()
        .environmentObject(AuthManager())
}