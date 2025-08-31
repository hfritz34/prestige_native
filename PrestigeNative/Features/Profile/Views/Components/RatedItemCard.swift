//
//  RatedItemCard.swift
//  Rating item card for profile ratings display
//
//  Shows a rated item with image, name, score, and category indication.
//

import SwiftUI

struct RatedItemCard: View {
    let ratedItem: RatedItem
    
    var body: some View {
        VStack(spacing: 8) {
            // Item image
            CachedAsyncImage(
                url: ratedItem.imageUrl,
                placeholder: Image(systemName: getIconForType()),
                contentMode: .fill,
                maxWidth: 120,
                maxHeight: 120
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                // Rating score overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(ratedItem.rating.displayScore)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
                .padding(4)
            )
            
            // Item details
            VStack(spacing: 2) {
                Text(ratedItem.displayTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if !ratedItem.displaySubtitle.isEmpty {
                    Text(ratedItem.displaySubtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
            }
        }
        .frame(width: 120)
    }
    
    private func getIconForType() -> String {
        switch ratedItem.itemData.itemType {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "music.mic"
        }
    }
    
}

#Preview {
    let sampleRating = Rating(
        itemId: "1",
        itemType: .track,
        albumId: nil,
        categoryId: 1,
        category: nil,
        position: 1,
        personalScore: 8.5,
        rankWithinAlbum: nil,
        isNewRating: false
    )
    
    let sampleItemData = RatingItemData(
        id: "1",
        name: "Sample Track",
        imageUrl: "https://via.placeholder.com/100",
        artists: ["Sample Artist"],
        albumName: "Sample Album",
        albumId: nil,
        itemType: .track
    )
    
    let sampleRatedItem = RatedItem(
        id: "1",
        rating: sampleRating,
        itemData: sampleItemData
    )
    
    RatedItemCard(ratedItem: sampleRatedItem)
        .padding()
}