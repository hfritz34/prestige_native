//
//  EditProfileView.swift
//  Profile Editing View
//
//  Allows users to edit their display name and bio
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // Character limits
    private let maxDisplayNameLength = 50
    private let maxBioLength = 500
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Display Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.headline)
                        
                        TextField("Enter your display name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: displayName) { _, newValue in
                                if newValue.count > maxDisplayNameLength {
                                    displayName = String(newValue.prefix(maxDisplayNameLength))
                                }
                            }
                        
                        HStack {
                            Spacer()
                            Text("\(displayName.count)/\(maxDisplayNameLength)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Bio Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                        
                        TextField("Tell others about your music taste...", text: $bio, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(5...10)
                            .onChange(of: bio) { _, newValue in
                                if newValue.count > maxBioLength {
                                    bio = String(newValue.prefix(maxBioLength))
                                }
                            }
                        
                        HStack {
                            Spacer()
                            Text("\(bio.count)/\(maxBioLength)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Profile Information")
                } footer: {
                    Text("Your display name and bio will be visible to other users and friends.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    // Save Button
                    Button(action: {
                        Task {
                            await saveProfile()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Text("Save Changes")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(canSave ? Color.purple : Color.gray)
                        )
                    }
                    .disabled(!canSave || isLoading)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Profile Update", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        return !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               displayName.count <= maxDisplayNameLength &&
               bio.count <= maxBioLength
    }
    
    // MARK: - Methods
    
    private func loadCurrentProfile() {
        guard let user = authManager.user else { return }
        
        // Load current values from user profile
        displayName = user.displayName ?? user.name ?? ""
        bio = user.bio ?? ""
    }
    
    private func saveProfile() async {
        guard let user = authManager.user else { return }
        
        isLoading = true
        
        do {
            let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Call API to update profile
            try await APIClient.shared.updateUserProfile(
                userId: user.id,
                displayName: trimmedDisplayName,
                bio: trimmedBio.isEmpty ? nil : trimmedBio
            )
            
            // Update local user object
            await MainActor.run {
                authManager.user?.nickname = trimmedDisplayName
                authManager.user?.bio = trimmedBio.isEmpty ? nil : trimmedBio
                
                alertMessage = "Profile updated successfully!"
                showingAlert = true
                
                // Auto-dismiss after successful save
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
            
        } catch {
            await MainActor.run {
                alertMessage = "Failed to update profile: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        
        isLoading = false
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthManager.shared)
}