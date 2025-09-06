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
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var personalizedDemo = PersonalizedDemoService.shared
    @StateObject private var imagePreloader = ImagePreloader.shared
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
            // Load personalized demo data and preload images
            if let userId = authManager.user?.id, !userId.isEmpty {
                Task {
                    await personalizedDemo.loadPersonalizedDemoData(userId: userId)
                    
                    // Preload all demo images once data is ready
                    await MainActor.run {
                        let imageUrls = personalizedDemo.demoAlbums.map { $0.imageUrl }
                        imagePreloader.preloadImages(imageUrls)
                    }
                }
            }
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
            
            // Demo album at diamond tier - personalized or default
            VStack(spacing: 16) {
                // Static album card at diamond level - larger for single display
                DemoAlbumCard(
                    prestigeLevel: .diamond,
                    listeningTime: "50h 0m",
                    showAnimation: true,
                    albumData: personalizedDemo.isReady ? personalizedDemo.getFeaturedAlbum() : nil,
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
            
            // 3x2 Grid showing progression - personalized or default
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                let progressionAlbums = personalizedDemo.isReady ? personalizedDemo.getProgressionAlbums() : []
                let prestigeLevels: [PrestigeLevel] = [.bronze, .silver, .gold, .sapphire, .emerald, .darkMatter]
                let listeningTimes = ["3h 20m", "5h 50m", "16h 40m", "33h 20m", "66h 40m", "138h 53m"]
                let delays = [0.0, 0.3, 0.6, 0.9, 1.2, 1.5]
                
                ForEach(0..<6, id: \.self) { index in
                    DemoAlbumCard(
                        prestigeLevel: prestigeLevels[index],
                        listeningTime: listeningTimes[index],
                        showAnimation: true,
                        delay: delays[index],
                        albumData: progressionAlbums.indices.contains(index) ? progressionAlbums[index] : nil
                    )
                }
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
            
            // Demo rating interface - personalized
            VStack(spacing: 16) {
                let comparisonAlbums = personalizedDemo.isReady ? personalizedDemo.getComparisonAlbums() : (left: nil, right: nil)
                DemoRatingCard(
                    leftAlbumData: comparisonAlbums.left,
                    rightAlbumData: comparisonAlbums.right
                )
                
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
            
            // Demo friends comparison - personalized
            DemoFriendsComparison(
                albumData: personalizedDemo.isReady ? personalizedDemo.getFriendsComparisonAlbum() : nil
            )
            
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
        .padding(.horizontal, 40) // Increased horizontal padding to center buttons better
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