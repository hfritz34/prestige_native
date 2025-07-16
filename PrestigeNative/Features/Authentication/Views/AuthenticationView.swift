//
//  AuthenticationView.swift
//  Root Authentication View that manages login/authenticated states
//
//  This view handles the authentication flow and navigation to main app.
//  Equivalent to AuthenticationWrapper.tsx from the web application.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Main app content will go here
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

// Placeholder for main app content
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            Text("Profile")
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
            
            Text("Friends")
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Friends")
                }
            
            VStack {
                Text("Settings")
                
                Button("Logout") {
                    authManager.logout()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
    }
}

#Preview {
    AuthenticationView()
}