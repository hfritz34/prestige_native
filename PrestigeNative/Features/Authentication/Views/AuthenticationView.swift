//
//  AuthenticationView.swift
//  Root Authentication View that manages login/authenticated states
//
//  This view handles the authentication flow and navigation to main app.
//  Equivalent to AuthenticationWrapper.tsx from the web application.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var userProfileLoaded = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if !userProfileLoaded {
                    // Loading view while checking user setup status
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .padding(.top)
                    }
                    .onAppear {
                        checkUserSetupStatus()
                    }
                } else if !authManager.userIsSetup {
                    // User needs to complete onboarding
                    NavigationView {
                        ProfileSetupView()
                            .environmentObject(authManager)
                    }
                } else {
                    // Main app content
                    MainTabView()
                        .environmentObject(authManager)
                        .onAppear {
                            // Inject AuthManager into APIClient when user is authenticated
                            APIClient.shared.setAuthManager(authManager)
                            print("✅ Auth: Injected AuthManager into APIClient")
                        }
                }
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.userIsSetup)
    }
    
    private func checkUserSetupStatus() {
        Task {
            do {
                guard let userId = authManager.user?.id else { 
                    print("⚠️ No user ID available, cannot check setup status")
                    await MainActor.run {
                        userProfileLoaded = true
                    }
                    return 
                }
                
                print("🔵 Checking user setup status for userId: \(userId)")
                let userProfile = try await APIClient.shared.getUserProfile(userId: userId, quickCheck: true)
                print("✅ User profile loaded - isSetup: \(userProfile.isSetup)")
                
                await MainActor.run {
                    authManager.userIsSetup = userProfile.isSetup
                    userProfileLoaded = true
                }
            } catch {
                print("❌ Failed to check user setup status: \(error)")
                print("⚠️ Error details: \(error.localizedDescription)")
                
                // For network errors (timeout, no connection), default to main app
                // Most users are likely already setup, so this is safer than forcing onboarding
                if (error as NSError).code == NSURLErrorTimedOut {
                    print("⚠️ Request timed out - defaulting to main app (assume user is setup)")
                    await MainActor.run {
                        authManager.userIsSetup = true  // Default to main app on network issues
                        userProfileLoaded = true
                    }
                } else {
                    // For other errors, also default to main app
                    await MainActor.run {
                        authManager.userIsSetup = true
                        userProfileLoaded = true
                    }
                }
            }
        }
    }
}

// Placeholder for main app content
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            RateView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Rate")
                }
            
            FriendsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .tint(Color(hex: "#5167FC") ?? .purple)
    }
}

#Preview {
    AuthenticationView()
}