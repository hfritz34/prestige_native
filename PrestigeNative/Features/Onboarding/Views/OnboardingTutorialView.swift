//
//  OnboardingTutorialView.swift
//  Interactive Tutorial - App Features & Prestige System
//
//  Comprehensive tutorial showing prestige progression, ratings, and friends features
//  using static designs that mirror the actual app interface.
//

import SwiftUI

struct OnboardingTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showCompletionAnimation = false
    
    private let totalSteps = 6
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color.purple.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Progress indicator
                        progressIndicator
                        
                        // Tutorial content based on current step
                        tutorialContent
                        
                        // Navigation buttons
                        navigationButtons
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Preload any animations or content
        }
    }
    
    // MARK: - Tutorial Steps
    
    @ViewBuilder
    private var tutorialContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            prestigeIntroStep
        case 2:
            prestigeProgressionStep
        case 3:
            ratingsSystemStep
        case 4:
            friendsFeatureStep
        case 5:
            profileDisplayStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 0: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            // App logo and title
            VStack(spacing: 16) {
                Image("white_logo_clear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                Text("Welcome to Prestige")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Track your music journey like never before")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Feature highlights
            VStack(spacing: 16) {
                FeatureHighlight(
                    icon: "crown.fill",
                    title: "Prestige System",
                    description: "Earn prestige levels as you listen to your favorite music"
                )
                
                FeatureHighlight(
                    icon: "star.fill",
                    title: "Rate & Track",
                    description: "Rate your music and see your taste evolve over time"
                )
                
                FeatureHighlight(
                    icon: "person.2.fill",
                    title: "Connect with Friends",
                    description: "Compare your music taste and discover new favorites"
                )
            }
        }
    }
    
    // MARK: - Step 1: Prestige Introduction
    private var prestigeIntroStep: some View {
        VStack(spacing: 24) {
            Text("What is Prestige?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Prestige levels represent your dedication to artists, albums, and tracks. The more you listen, the higher your prestige grows!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Demo album at diamond tier with mk.gee
            VStack(spacing: 16) {
                // Static album card at diamond level - larger for single display
                DemoAlbumCard(
                    prestigeLevel: .diamond,
                    listeningTime: "50h 0m",
                    showAnimation: true,
                    albumImageUrl: "https://i.scdn.co/image/ab67616d0000b273038b1c2017f14c805cf5b7e9",
                    albumName: "Two Star & The Dream Police",
                    artistName: "Mk.gee",
                    imageSize: 180  // Much larger for single display
                )
                
                Text("Albums, tracks, and artists earn prestige tiers based on your listening time")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Step 2: Prestige Progression
    private var prestigeProgressionStep: some View {
        VStack(spacing: 24) {
            Text("Watch Your Prestige Grow")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("As you listen more, your prestige evolves through beautiful tiers")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // 3x2 Grid showing progression with fakemink album
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Row 1
                DemoAlbumCard(prestigeLevel: .bronze, listeningTime: "3h 20m", showAnimation: true, delay: 0.0)
                DemoAlbumCard(prestigeLevel: .silver, listeningTime: "5h 50m", showAnimation: true, delay: 0.3)
                DemoAlbumCard(prestigeLevel: .gold, listeningTime: "16h 40m", showAnimation: true, delay: 0.6)
                
                // Row 2
                DemoAlbumCard(prestigeLevel: .sapphire, listeningTime: "33h 20m", showAnimation: true, delay: 0.9)
                DemoAlbumCard(prestigeLevel: .emerald, listeningTime: "66h 40m", showAnimation: true, delay: 1.2)
                DemoAlbumCard(prestigeLevel: .darkMatter, listeningTime: "138h 53m", showAnimation: true, delay: 1.5)
            }
            
            Text("Each tier unlocks new visual themes and shows your dedication!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Step 3: Ratings System
    private var ratingsSystemStep: some View {
        VStack(spacing: 24) {
            Text("Head-to-Head Ratings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Compare albums side-by-side to build your personalized ranking system")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Demo rating interface
            VStack(spacing: 16) {
                DemoRatingCard()
                
                Text("Our unique comparison system creates accurate rankings based on your preferences - no arbitrary scores needed!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Step 4: Friends Feature
    private var friendsFeatureStep: some View {
        VStack(spacing: 24) {
            Text("Connect with Friends")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("See what your friends are listening to and compare your music taste")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Demo friends comparison
            DemoFriendsComparison()
            
            Text("Discover new music through your friends' prestiges and ratings")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Step 5: Profile Display
    private var profileDisplayStep: some View {
        VStack(spacing: 24) {
            Text("Your Musical Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("All your prestiges, ratings, and listening stats in one beautiful profile")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Demo profile view
            DemoProfileView()
            
            if showCompletionAnimation {
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 60))
                    
                    Text("You're all set!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Start building your musical prestige")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCompletionAnimation)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showCompletionAnimation = true
            }
        }
    }
    
    // MARK: - UI Components
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 4)
                    .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                    .frame(width: step == currentStep ? 20 : 12, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.top)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Previous") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
            }
            
            Spacer()
            
            if currentStep < totalSteps - 1 {
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
                .foregroundColor(.black)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
            } else {
                Button("Get Started") {
                    dismiss()
                }
                .foregroundColor(.black)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
            }
        }
        .padding(.bottom)
    }
}

// MARK: - Supporting Components

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingTutorialView()
}