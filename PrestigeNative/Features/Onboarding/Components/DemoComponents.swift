//
//  DemoComponents.swift
//  Demo UI Components for Tutorial
//
//  Static demo components that mirror the actual app interface
//  for the onboarding tutorial experience.
//

import SwiftUI

// MARK: - Demo Album Card
struct DemoAlbumCard: View {
    let prestigeLevel: PrestigeLevel
    let listeningTime: String
    let showAnimation: Bool
    var delay: Double = 0.0
    var albumImageUrl: String = "https://i.scdn.co/image/ab67616d0000b273e09e5aed7d747f5692b183ea"
    var albumName: String = "London's Saviour"
    var artistName: String = "fakemink"
    var imageSize: CGFloat = 110  // Default grid size
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Album card with prestige background
            ZStack {
                // Prestige background
                if prestigeLevel != .none && !prestigeLevel.imageName.isEmpty {
                    Image(prestigeLevel.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(0.8)
                        .scaleEffect(1.1)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Album artwork - properly centered
                AsyncImage(url: URL(string: albumImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                // Prestige badge at bottom
                VStack {
                    Spacer()
                    PrestigeBadge(tier: prestigeLevel, showText: false)
                        .scaleEffect(0.8)
                        .padding(.bottom, 8)
                }
            }
            .frame(width: imageSize + 30, height: imageSize + 30)
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: isVisible)
            
            // Album info
            VStack(spacing: 2) {
                Text(albumName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                Text(artistName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                Text(listeningTime)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: prestigeLevel.color) ?? .purple)
            }
        }
        .onAppear {
            if showAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    isVisible = true
                }
            } else {
                isVisible = true
            }
        }
    }
}

// MARK: - Demo Head-to-Head Rating Comparison
struct DemoRatingCard: View {
    @State private var selectedWinner: String? = "left"
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Head-to-Head Comparison")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // VS Display  
            HStack(alignment: .top, spacing: 20) {
                // Left album - BOY ANONYMOUS (winner)
                VStack(spacing: 12) {
                    ZStack {
                        AsyncImage(url: URL(string: "https://i.scdn.co/image/ab67616d0000b273a3fed508a9b88a492b589873")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        // Selection glow overlay
                        if selectedWinner == "left" {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green, lineWidth: 3)
                                .frame(width: 120, height: 120)
                                .shadow(color: .green, radius: 8)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("BOY ANONYMOUS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("Paris Texas")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if selectedWinner == "left" && showResult {
                        Text("Winner! 🏆")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .transition(.scale)
                    }
                }
                .scaleEffect(selectedWinner == "left" ? 1.05 : 0.95)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedWinner)
                
                // VS Badge
                Text("VS")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.purple)
                    )
                
                // Right album - Gemini Rights
                VStack(spacing: 12) {
                    ZStack {
                        AsyncImage(url: URL(string: "https://i.scdn.co/image/ab67616d0000b27368968350c2550e36d96344ee")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        // Selection glow overlay
                        if selectedWinner == "right" {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green, lineWidth: 3)
                                .frame(width: 120, height: 120)
                                .shadow(color: .green, radius: 8)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("Gemini Rights")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("Steve Lacy")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if selectedWinner == "right" && showResult {
                        Text("Winner! 🏆")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .transition(.scale)
                    }
                }
                .scaleEffect(selectedWinner == "right" ? 1.05 : 0.95)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedWinner)
            }
            
            // Info text
            Text("Choose which album you prefer")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            if showResult {
                Text("Your ratings help create a personalized ranking of all your music!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showResult = true
                }
            }
        }
    }
}

// MARK: - Demo Friends Comparison
struct DemoFriendsComparison: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Friend Comparison")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Comparison cards
            HStack(spacing: 12) {
                // User card
                VStack(spacing: 8) {
                    Text("You")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    DemoAlbumCard(
                        prestigeLevel: .diamond,
                        listeningTime: "50h 0m",
                        showAnimation: false,
                        albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273072e9faef2ef7b6db63834a3",
                        albumName: "ASTROWORLD",
                        artistName: "Travis Scott",
                        imageSize: 140
                    )
                    
                    Text("💎 Diamond")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                Text("VS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                
                // Friend card
                VStack(spacing: 8) {
                    Text("Alex")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    DemoAlbumCard(
                        prestigeLevel: .gold,
                        listeningTime: "32h 15m",
                        showAnimation: false,
                        albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273072e9faef2ef7b6db63834a3",
                        albumName: "ASTROWORLD",
                        artistName: "Travis Scott",
                        imageSize: 140
                    )
                    
                    Text("🥇 Gold")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            // Winner indicator
            Text("🏆 You're ahead!")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Demo Profile View
struct DemoProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Profile header
            VStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("YU")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Text("Your Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DemoStatCard(title: "Total Time", value: "248h", icon: "clock.fill", color: .blue)
                DemoStatCard(title: "Top Tier", value: "Dark Matter", icon: "crown.fill", color: .purple)
                DemoStatCard(title: "Albums Rated", value: "127", icon: "star.fill", color: .yellow)
            }
            
            // Top prestige preview
            VStack(spacing: 8) {
                Text("Your Top Prestige")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                DemoAlbumCard(
                    prestigeLevel: .darkMatter,
                    listeningTime: "83h 20m",
                    showAnimation: false,
                    albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273c43b3a9459cadcf6f68867cd",
                    albumName: "Pray For Haiti",
                    artistName: "Mach-Hommy",
                    imageSize: 160
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Mini Stat Card for Demo
struct DemoStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        DemoAlbumCard(prestigeLevel: .diamond, listeningTime: "50h 0m", showAnimation: true)
        DemoRatingCard()
        DemoFriendsComparison()
        DemoProfileView()
    }
    .padding()
    .background(Color.black)
}