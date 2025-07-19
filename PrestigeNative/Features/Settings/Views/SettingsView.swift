//
//  SettingsView.swift
//  Settings Screen
//
//  Displays account settings, import data, how we track prestige, 
//  privacy policy, terms of service, about us, and logout.
//  Matches SettingsPage.tsx from the web application.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section {
                    NavigationLink(destination: AccountSettingsView()) {
                        Label("Account", systemImage: "person.circle")
                    }
                }
                
                // Data Section
                Section {
                    NavigationLink(destination: ImportDataView()) {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }
                
                // Information Section
                Section {
                    NavigationLink(destination: HowWeTrackPrestigeView()) {
                        Label("How We Track Prestige", systemImage: "info.circle")
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    NavigationLink(destination: AboutUsView()) {
                        Label("About Us", systemImage: "person.3")
                    }
                }
                
                // Logout Section
                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack {
                            Label("Log Out", systemImage: "arrow.left.square")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task {
                    await authManager.logout()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

// MARK: - Placeholder Views

struct AccountSettingsView: View {
    var body: some View {
        Text("Account Settings")
            .navigationTitle("Account")
    }
}

struct ImportDataView: View {
    var body: some View {
        Text("Import Data")
            .navigationTitle("Import Data")
    }
}

struct HowWeTrackPrestigeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How We Track Prestige")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Prestige is awarded based on your listening time for tracks, albums, and artists.")
                    .font(.body)
                
                // Add more content here matching the web app
            }
            .padding()
        }
        .navigationTitle("How We Track")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy")
            .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("Terms of Service")
            .navigationTitle("Terms of Service")
    }
}

struct AboutUsView: View {
    var body: some View {
        Text("About Us")
            .navigationTitle("About Us")
    }
}

#Preview {
    SettingsView()
}