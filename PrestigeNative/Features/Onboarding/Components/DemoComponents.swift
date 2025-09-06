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
    var albumData: DemoAlbumData? = nil // New: optional personalized data
    var albumImageUrl: String = "https://i.scdn.co/image/ab67616d0000b273e09e5aed7d747f5692b183ea"
    var albumName: String = "London's Saviour"
    var artistName: String = "fakemink"
    var imageSize: CGFloat = 110  // Default grid size
    
    // Computed properties to use personalized data when available
    private var finalImageUrl: String {
        return albumData?.imageUrl ?? albumImageUrl
    }
    
    private var finalAlbumName: String {
        return albumData?.name ?? albumName
    }
    
    private var finalArtistName: String {
        return albumData?.artistName ?? artistName
    }
    
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
                AsyncImage(url: URL(string: finalImageUrl)) { image in
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
                Text(finalAlbumName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(finalArtistName)
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
    var leftAlbumData: DemoAlbumData? = nil
    var rightAlbumData: DemoAlbumData? = nil
    @State private var selectedWinner: String? = "left"
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Head-to-Head Comparison")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // VS Display  
            HStack(alignment: .top, spacing: 20) {
                // Left album - personalized or default
                VStack(spacing: 12) {
                    ZStack {
                        AsyncImage(url: URL(string: leftAlbumData?.imageUrl ?? "https://i.scdn.co/image/ab67616d0000b273a3fed508a9b88a492b589873")) { image in
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
                        Text(leftAlbumData?.name ?? "BOY ANONYMOUS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(leftAlbumData?.artistName ?? "Paris Texas")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(selectedWinner == "left" && showResult ? "Winner! 🏆" : "")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .frame(height: 16) // Fixed height to prevent layout shift
                        .transition(.scale)
                }
                .frame(width: 120, height: 180) // Fixed frame to prevent movement
                .scaleEffect(selectedWinner == "left" ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedWinner)
                
                // VS Indicator centered on album artwork
                VStack {
                    VersusIndicator()
                        .padding(.top, 35) // Adjust to center on the 120px album art
                    Spacer()
                }
                .frame(height: 180) // Match album card height
                
                // Right album - personalized or default
                VStack(spacing: 12) {
                    ZStack {
                        AsyncImage(url: URL(string: rightAlbumData?.imageUrl ?? "https://i.scdn.co/image/ab67616d0000b27368968350c2550e36d96344ee")) { image in
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
                        Text(rightAlbumData?.name ?? "Gemini Rights")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(rightAlbumData?.artistName ?? "Steve Lacy")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(selectedWinner == "right" && showResult ? "Winner! 🏆" : "")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .frame(height: 16) // Fixed height to prevent layout shift
                        .transition(.scale)
                }
                .frame(width: 120, height: 180) // Fixed frame to prevent movement
                .scaleEffect(selectedWinner == "right" ? 1.05 : 1.0)
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
    var albumData: DemoAlbumData? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Friend Comparison")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Comparison cards
            HStack(spacing: 12) {
                // User card
                VStack(spacing: 8) {
                    Text("You")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    DemoAlbumCard(
                        prestigeLevel: .diamond,
                        listeningTime: "50h 0m",
                        showAnimation: false,
                        albumData: albumData,
                        albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273072e9faef2ef7b6db63834a3",
                        albumName: "ASTROWORLD",
                        artistName: "Travis Scott",
                        imageSize: 140
                    )
                    
                    Text("💎 Diamond")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                VersusIndicator()
                
                // Friend card
                VStack(spacing: 8) {
                    Text("Friend")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    DemoAlbumCard(
                        prestigeLevel: .gold,
                        listeningTime: "32h 15m",
                        showAnimation: false,
                        albumData: albumData,
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
        .padding(.horizontal, 24) // Increase horizontal padding 
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 24) // Increase margin from screen edges
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
                            .foregroundColor(.primary)
                    )
                
                Text("Your Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
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
            
            // Collect prestiges encouragement
            VStack(spacing: 12) {
                Text("Collect Prestiges!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                Image("purple_crown")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding()
                    .background(
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                
                Text("Build your musical legacy")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
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
                .foregroundColor(.primary)
            
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

