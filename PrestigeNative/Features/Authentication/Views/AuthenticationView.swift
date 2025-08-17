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
                    await MainActor.run {
                        userProfileLoaded = true
                    }
                    return 
                }
                
                let userProfile = try await APIClient.shared.getUserProfile(userId: userId)
                await MainActor.run {
                    authManager.userIsSetup = userProfile.isSetup
                    userProfileLoaded = true
                }
            } catch {
                print("Failed to check user setup status: \(error)")
                // Default to showing main app on error
                await MainActor.run {
                    authManager.userIsSetup = true
                    userProfileLoaded = true
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
            
            Text("Friends")
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
    }
}

#Preview {
    AuthenticationView()
}