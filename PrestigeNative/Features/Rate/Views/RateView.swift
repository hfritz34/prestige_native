//
//  RateView.swift
//  Song Rating View
//
//  Scaffold for future rating functionality where users can
//  discover and rate songs, albums, and artists.
//

import SwiftUI

struct RateView: View {
    @State private var searchText = ""
    @State private var selectedCategory: RatingCategory = .discover
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Category selector
                categorySelector
                
                // Content based on selected category
                contentSection
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemBackground))
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
                
                TextField("Search songs, albums, or artists...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(RatingCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedCategory {
                case .discover:
                    discoverContent
                case .topRated:
                    topRatedContent
                case .yourRatings:
                    yourRatingsContent
                case .newReleases:
                    newReleasesContent
                }
            }
            .padding(.vertical)
        }
    }
    
    private var discoverContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Discover New Music")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Placeholder content
            ForEach(0..<5) { _ in
                RatingPlaceholderCard()
                    .padding(.horizontal)
            }
        }
    }
    
    private var topRatedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Rated by Community")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Placeholder content
            ForEach(0..<5) { _ in
                RatingPlaceholderCard()
                    .padding(.horizontal)
            }
        }
    }
    
    private var yourRatingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Ratings")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Empty state
            EmptyStateView(
                icon: "star",
                title: "No Ratings Yet",
                subtitle: "Start rating songs to see them here"
            )
            .padding(.top, 40)
        }
    }
    
    private var newReleasesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Releases")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Placeholder content
            ForEach(0..<5) { _ in
                RatingPlaceholderCard()
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
                )
        }
    }
}

struct RatingPlaceholderCard: View {
    var body: some View {
        HStack(spacing: 12) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 16)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 12)
                
                // Rating stars placeholder
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

enum RatingCategory: CaseIterable {
    case discover
    case topRated
    case yourRatings
    case newReleases
    
    var displayName: String {
        switch self {
        case .discover: return "Discover"
        case .topRated: return "Top Rated"
        case .yourRatings: return "Your Ratings"
        case .newReleases: return "New Releases"
        }
    }
}

#Preview {
    RateView()
        .environmentObject(AuthManager())
}