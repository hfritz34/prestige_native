//
//  RatingModal.swift
//  Rating Modal Flow
//
//  Native iOS modal for rating items with smooth animations,
//  category selection, and comparison flow
//

import SwiftUI
import UIKit

struct RatingModal: View {
    @EnvironmentObject var viewModel: RatingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCelebration = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content based on rating state
                contentSection
                
                Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Drag indicator and close button
            HStack {
                Button("Cancel") {
                    dismiss()
                    viewModel.resetRatingFlow()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                
                Spacer()
                
                Text(headerTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if viewModel.ratingState == .saving {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button("Cancel") {
                        dismiss()
                        viewModel.resetRatingFlow()
                    }
                    .opacity(0) // Hidden but maintains layout
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Item being rated
            if let item = viewModel.currentRatingItem {
                itemPreview(item)
                    .onAppear { viewModel.upsertItemData(item) }
            }
            
            Divider()
        }
    }
    
    private var headerTitle: String {
        switch viewModel.ratingState {
        case .selectingCategory:
            return viewModel.existingRating != nil ? "Update Rating" : "Rate Item"
        case .comparing:
            return "Compare Items"
        case .saving:
            return "Saving..."
        case .completed:
            return "Rating Saved!"
        default:
            return "Rate Item"
        }
    }
    
    private func itemPreview(_ item: RatingItemData) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: item.itemType.iconName)
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.6))
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let artists = item.artists, !artists.isEmpty {
                    Text(artists.joined(separator: ", "))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: item.itemType.iconName)
                        .font(.caption2)
                    Text(item.itemType.singularName)
                        .font(.caption)
                }
                .foregroundColor(.blue.opacity(0.8))
            }
            
            Spacer()
            
            // Show existing rating if updating
            if let existing = viewModel.existingRating {
                RatingBadge(score: existing.personalScore, size: .medium)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.ratingState {
        case .selectingCategory:
            categorySelectionView
        case .comparing:
            comparisonView
        case .saving:
            savingView
        case .completed:
            completedView
        default:
            categorySelectionView
        }
    }
    
    private var categorySelectionView: some View {
        VStack(spacing: 20) {
            Text("How did you feel about it?")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 24)
                .padding(.horizontal, 20)
            
            if viewModel.categories.isEmpty {
                ProgressView("Loading categories...")
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        RatingCategoryButton(
                            category: category,
                            isSelected: viewModel.selectedCategory?.id == category.id,
                            action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.selectCategory(category)
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 16)
            }
            
            Spacer()
        }
    }
    
    private var comparisonView: some View {
        VStack(spacing: 20) {
            if viewModel.currentComparisonIndex < viewModel.comparisonItems.count {
                let currentItem = viewModel.comparisonItems[viewModel.currentComparisonIndex]
                
                ComparisonView(
                    newItem: viewModel.currentRatingItem!,
                    comparisonItem: currentItem,
                    progress: viewModel.currentComparisonProgress,
                    onSelection: { winnerId in
                        Task {
                            await viewModel.handleComparison(winnerId: winnerId)
                        }
                    },
                    onSkip: {
                        viewModel.skipComparison()
                    }
                )
                .padding(.horizontal, 20)
            } else {
                Text("Processing comparisons...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ProgressView()
                    .padding()
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private var savingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Saving your rating...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 60)
    }
    
    private var completedView: some View {
        ZStack {
            // Celebration effects for new top item
            if showCelebration {
                CelebrationView()
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 24) {
                Image(systemName: showCelebration ? "star.fill" : "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(showCelebration ? .yellow : .green)
                    .scaleEffect(showCelebration ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCelebration)
                
                Text(showCelebration ? "New Top Item!" : "Rating Saved!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(showCelebration ? "You've found a new favorite!" : "Your rating has been added successfully.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            
            Button("Done") {
                dismiss()
                viewModel.resetRatingFlow()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(Capsule())
            
                Spacer()
            }
            .padding(.top, 40)
        }
        .onAppear {
            checkForTopRating()
        }
    }
    
    private func checkForTopRating() {
        // Only celebrate for true 10s - position 0 in the "I really liked it" category
        if let searchState = viewModel.binarySearchState,
           let category = viewModel.selectedCategory,
           searchState.finalPosition == 0,
           category.maxScore >= 10.0 {  // Only for the highest category (loved/really liked)
            
            showCelebration = true
            
            // Strong haptic feedback for new top item
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            // Stop celebration after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showCelebration = false
            }
        }
    }
    
    // MARK: - Helper Methods
}

#Preview {
    RatingModal()
        .environmentObject({
            let vm = RatingViewModel()
            vm.currentRatingItem = RatingItemData(
                id: "1",
                name: "Sample Song",
                imageUrl: nil,
                artists: ["Sample Artist"],
                albumName: "Sample Album",
                albumId: nil,
                itemType: .track
            )
            vm.ratingState = .selectingCategory
            return vm
        }())
}