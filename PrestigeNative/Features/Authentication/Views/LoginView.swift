//
//  LoginView.swift
//  Main Login Screen for Prestige Authentication
//
//  SwiftUI view for the login screen with Auth0 integration.
//  Equivalent to Login.tsx from the web application.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingError = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 24) {
                    Spacer()
                    
                    // App Logo
                    Image("purple_crown")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    // App Title
                    Text("Prestige")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Subtitle
                    Text("Track your music journey")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .frame(height: geometry.size.height * 0.6)
                
                // Login Section
                VStack(spacing: 20) {
                    // Debug URL Test Button
                    Button(action: {
                        testURLScheme()
                    }) {
                        HStack {
                            Image(systemName: "link.badge.plus")
                                .font(.title3)
                            Text("Test URL Scheme")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Login Button
                    Button(action: {
                        Task {
                            await authManager.login()
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.key")
                                    .font(.title3)
                            }
                            
                            Text(authManager.isLoading ? "Signing In..." : "Sign In with Auth0")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(authManager.isLoading)
                    
                    // Privacy Text
                    Text("By signing in, you agree to connect your Spotify account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .frame(height: geometry.size.height * 0.4)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.primary.opacity(0.05), Color.gray.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") {
                authManager.error = nil
            }
        } message: {
            Text(authManager.error?.localizedDescription ?? "An error occurred")
        }
        .onChange(of: authManager.error) { _, error in
            showingError = error != nil
        }
    }
    
    private func testURLScheme() {
        print("🧪 Testing URL Scheme manually...")
        
        // Simulate what Auth0 callback might send
        let testURL = URL(string: "com.prestige.PrestigeNative://callback?code=test123&state=abc")!
        
        // This should trigger the onOpenURL handler in PrestigeNativeApp
        print("🧪 Attempting to process test URL: \(testURL)")
        
        // Note: We can't directly call the URL handler from here in a real scenario,
        // but this will help us debug the URL construction
        print("🧪 If URL scheme is working, you should see logs in the console")
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}