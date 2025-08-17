//
//  ProfileSetupView.swift
//  Profile Setup Screen for Onboarding
//
//  Initial setup screen where users set their display name.
//  Equivalent to ProfileSetupPage.tsx from the web application.
//

import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var nickname = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("Set your display name")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Display name", text: $nickname)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .disabled(isLoading)
                    
                    Text("(This can be changed later in settings)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Continue button
                NavigationLink(destination: AddFavoritesView()) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(nickname.isEmpty ? 0.5 : 1.0)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(nickname.isEmpty || isLoading)
                .simultaneousGesture(TapGesture().onEnded {
                    if !nickname.isEmpty {
                        Task {
                            await updateNickname()
                        }
                    }
                })
            }
            .padding(.horizontal, 24)
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func updateNickname() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            _ = try await APIClient.shared.updateNickname(nickname)
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthManager.shared)
}