//
//  LoginView.swift
//  Main Login Screen for Prestige Authentication
//
//  SwiftUI view for the login screen with Auth0 integration.
//  Equivalent to Login.tsx from the web application.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showingError = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo placeholder
                    Image(systemName: "music.note")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                    
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
                    // Login Button
                    Button(action: {
                        viewModel.login()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.key")
                                    .font(.title3)
                            }
                            
                            Text(viewModel.isLoading ? "Signing In..." : "Sign In with Auth0")
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
                    .disabled(viewModel.isLoading)
                    
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
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
        .onChange(of: viewModel.error) { _, error in
            showingError = error != nil
        }
    }
}

#Preview {
    LoginView()
}