//
//  RatingCategoryButton.swift
//  Rating Category Selection Button
//
//  Visual button component for selecting rating categories
//  with colors, emojis, and descriptions
//

import SwiftUI

struct RatingCategoryButton: View {
    let category: RatingCategory
    let isSelected: Bool
    let action: () -> Void
    
    private var backgroundColor: Color {
        Color(hex: category.colorHex) ?? .gray
    }
    
    private var borderColor: Color {
        isSelected ? backgroundColor : Color.clear
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Emoji
                Text(category.emoji)
                    .font(.system(size: 48))
                
                // Category Name
                Text(category.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                // Score Range
                Text("\(String(format: "%.1f", category.minScore)) - \(String(format: "%.1f", category.maxScore))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor.opacity(isSelected ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: isSelected ? 3 : 0)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Compact Version

struct CompactRatingCategoryButton: View {
    let category: RatingCategory
    let isSelected: Bool
    let action: () -> Void
    
    private var backgroundColor: Color {
        Color(hex: category.colorHex) ?? .gray
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.title3)
                
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? backgroundColor : Color(UIColor.secondarySystemBackground))
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Category Grid

struct RatingCategoryGrid: View {
    let categories: [RatingCategory]
    @Binding var selectedCategory: RatingCategory?
    let onSelect: (RatingCategory) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("How did you feel about it?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 8)
            
            ForEach(categories) { category in
                RatingCategoryButton(
                    category: category,
                    isSelected: selectedCategory?.id == category.id,
                    action: {
                        withAnimation(.spring()) {
                            selectedCategory = category
                            onSelect(category)
                        }
                    }
                )
            }
        }
        .padding()
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        
        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if length == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }
}

// MARK: - Preview

#Preview("Category Button") {
    VStack(spacing: 20) {
        RatingCategoryButton(
            category: RatingCategory(
                id: "1",
                name: "Loved",
                minScore: 6.8,
                maxScore: 10.0,
                colorHex: "#22c55e",
                displayOrder: 1
            ),
            isSelected: false,
            action: {}
        )
        
        CompactRatingCategoryButton(
            category: RatingCategory(
                id: "2",
                name: "Liked",
                minScore: 3.4,
                maxScore: 6.7,
                colorHex: "#eab308",
                displayOrder: 2
            ),
            isSelected: true,
            action: {}
        )
    }
    .padding()
}

#Preview("Category Grid") {
    RatingCategoryGrid(
        categories: [
            RatingCategory(id: "1", name: "Loved", minScore: 6.8, maxScore: 10.0, colorHex: "#22c55e", displayOrder: 1),
            RatingCategory(id: "2", name: "Liked", minScore: 3.4, maxScore: 6.7, colorHex: "#eab308", displayOrder: 2),
            RatingCategory(id: "3", name: "Disliked", minScore: 0.0, maxScore: 3.3, colorHex: "#ef4444", displayOrder: 3)
        ],
        selectedCategory: .constant(nil),
        onSelect: { _ in }
    )
}