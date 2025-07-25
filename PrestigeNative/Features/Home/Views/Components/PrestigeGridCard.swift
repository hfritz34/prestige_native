//
//  PrestigeGridCard.swift
//  Grid-style prestige card for 3-column layout
//
//  Square design with prestige tier framing the artwork and small rank indicator.
//

import SwiftUI

struct PrestigeGridCard: View {
    let item: PrestigeDisplayItem
    let rank: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Main card with artwork and prestige frame
            ZStack {
                // Background container with proper clipping
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .overlay(
                        Group {
                            // Prestige tier background image
                            if item.prestigeLevel != .none && !item.prestigeLevel.imageName.isEmpty {
                                Image(item.prestigeLevel.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(0.15)
                            }
                            
                            // Color overlay for better contrast
                            LinearGradient(
                                colors: [
                                    Color(hex: item.prestigeLevel.color)?.opacity(0.2) ?? Color.gray.opacity(0.2),
                                    Color(hex: item.prestigeLevel.color)?.opacity(0.05) ?? Color.gray.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color(hex: item.prestigeLevel.color) ?? Color.gray,
                                lineWidth: 2
                            )
                    )
                
                VStack(spacing: 8) {
                    // Rank badge
                    HStack {
                        Text("\(rank)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.black.opacity(0.7)))
                        Spacer()
                    }
                    
                    // Album artwork
                    AsyncImage(url: URL(string: item.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: getIconForType())
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    // Prestige badge
                    PrestigeBadge(tier: item.prestigeLevel)
                        .scaleEffect(0.8)
                }
                .padding(8)
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Title and subtitle
            VStack(spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(item.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(TimeFormatter.formatListeningTime(item.totalTimeMilliseconds))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: item.prestigeLevel.color) ?? .blue)
            }
        }
    }
    
    private func getIconForType() -> String {
        if item.subtitle == "Artist" {
            return "music.mic"
        } else if item.subtitle.contains("tracks") || item.name.contains("Album") {
            return "square.stack"
        } else {
            return "music.note"
        }
    }
}

// MARK: - Color Extension (if not already defined)

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
        ForEach(0..<9) { index in
            PrestigeGridCard(
                item: PrestigeDisplayItem(
                    name: "Sample Track \(index + 1)",
                    subtitle: "Sample Artist",
                    imageUrl: "",
                    totalTimeMilliseconds: (index + 1) * 120000,
                    prestigeLevel: [.bronze, .silver, .gold, .diamond][index % 4],
                    spotifyId: "sample-track-\(index + 1)",
                    contentType: .tracks
                ),
                rank: index + 1
            )
        }
    }
    .padding()
}