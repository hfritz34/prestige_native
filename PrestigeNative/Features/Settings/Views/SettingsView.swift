//
//  SettingsView.swift
//  Settings Screen
//
//  Displays account settings, import data, how we track prestige, 
//  privacy policy, terms of service, about us, and logout.
//  Matches SettingsPage.tsx from the web application.
//

import SwiftUI
import UniformTypeIdentifiers

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
                    
                    NavigationLink(destination: FavoritesManagementView()) {
                        Label("Manage Favorites", systemImage: "heart.fill")
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
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedFiles: [URL] = []
    @State private var isImporting = false
    @State private var message = ""
    @State private var showingDocumentPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Import Spotify Data")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("To import your Spotify data, follow these steps:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("1.")
                                .fontWeight(.semibold)
                            VStack(alignment: .leading) {
                                Text("Visit the ")
                                + Text("Spotify Privacy Page")
                                    .foregroundColor(.blue)
                                    .underline()
                                + Text(".")
                            }
                        }
                        
                        HStack(alignment: .top) {
                            Text("2.")
                                .fontWeight(.semibold)
                            Text("Scroll down to the \"Download your data\" section.")
                        }
                        
                        HStack(alignment: .top) {
                            Text("3.")
                                .fontWeight(.semibold)
                            Text("Follow the instructions to request and download your data.")
                        }
                        
                        HStack(alignment: .top) {
                            Text("4.")
                                .fontWeight(.semibold)
                            Text("After receiving your data from Spotify, you will have a folder named \"Spotify Extended Data History\". This folder contains JSON files.")
                        }
                    }
                    
                    Text("Upload all the JSON files from the folder below to import them.")
                        .font(.body)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                VStack(spacing: 16) {
                    if selectedFiles.isEmpty {
                        Button("Select JSON Files") {
                            showingDocumentPicker = true
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Files (\(selectedFiles.count)):")
                                .font(.headline)
                            
                            ForEach(selectedFiles, id: \.self) { file in
                                Text("• \(file.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Button("Change Files") {
                                    selectedFiles = []
                                    showingDocumentPicker = true
                                }
                                .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Button(isImporting ? "Importing..." : "Import Data") {
                                    Task {
                                        await importSpotifyData()
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(isImporting ? Color.gray : Color.green)
                                .cornerRadius(8)
                                .disabled(isImporting)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                if !message.isEmpty {
                    Text(message)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(message.contains("success") || message.contains("completed") ? .green : .red)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(selectedFiles: $selectedFiles)
        }
    }
    
    private func importSpotifyData() async {
        guard !selectedFiles.isEmpty else {
            message = "Please select files to upload."
            return
        }
        
        guard let userId = authManager.user?.id else {
            message = "User not authenticated. Please log in again."
            return
        }
        
        await MainActor.run {
            isImporting = true
            message = ""
        }
        
        do {
            let result = await SpotifyImportService.shared.uploadFiles(selectedFiles, userId: userId)
            await MainActor.run {
                message = result
                isImporting = false
            }
        } catch {
            await MainActor.run {
                message = "Failed to import: \(error.localizedDescription)"
                isImporting = false
            }
        }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [URL]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedFiles = urls
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Spotify Import Service

class SpotifyImportService {
    static let shared = SpotifyImportService()
    private init() {}
    
    func uploadFiles(_ files: [URL], userId: String) async -> String {
        let functionUrl = "https://prestigefunctions.azurewebsites.net/api/spotifydataimportfunction"
        
        guard let url = URL(string: "\(functionUrl)?userId=\(userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return "Invalid URL"
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // Add function key for Azure Functions authorization
        if let functionKey = Bundle.main.object(forInfoDictionaryKey: "AZURE_FUNCTION_KEY") as? String, !functionKey.isEmpty {
            request.setValue(functionKey, forHTTPHeaderField: "x-functions-key")
        }
        
        var body = Data()
        
        for file in files {
            guard file.startAccessingSecurityScopedResource() else {
                file.stopAccessingSecurityScopedResource()
                continue
            }
            
            defer { file.stopAccessingSecurityScopedResource() }
            
            do {
                let fileData = try Data(contentsOf: file)
                
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(file.lastPathComponent)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
                body.append(fileData)
                body.append("\r\n".data(using: .utf8)!)
            } catch {
                print("Failed to read file \(file.lastPathComponent): \(error)")
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                print("📤 Upload Response: Status \(httpResponse.statusCode), Body: \(responseString)")
                
                if httpResponse.statusCode == 200 {
                    return "Import completed! \(responseString)"
                } else {
                    return "Failed to import: HTTP \(httpResponse.statusCode) - \(responseString)"
                }
            } else {
                return "Failed to import: Invalid response"
            }
        } catch {
            return "Failed to import: \(error.localizedDescription)"
        }
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

struct FavoritesManagementView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = AddFavoritesViewModel()
    @State private var selectedTab = "tracks"
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "Songs", isSelected: selectedTab == "tracks") {
                    selectedTab = "tracks"
                    viewModel.selectedType = .tracks
                }
                
                TabButton(title: "Albums", isSelected: selectedTab == "albums") {
                    selectedTab = "albums"
                    viewModel.selectedType = .albums
                }
                
                TabButton(title: "Artists", isSelected: selectedTab == "artists") {
                    selectedTab = "artists"
                    viewModel.selectedType = .artists
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            
            // Current favorites section
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Favorites")
                    .font(.headline)
                    .padding(.horizontal)
                
                // Favorites list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if viewModel.currentFavorites.isEmpty {
                            Text("No favorites selected yet")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(viewModel.currentFavorites, id: \.id) { item in
                                FavoriteChip(item: item) {
                                    viewModel.toggleFavorite(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 60)
            }
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            
            // Search section
            VStack(spacing: 16) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for \(getSearchPlaceholder())", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _, newValue in
                            viewModel.searchQuery = newValue
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Search results
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.isSearching {
                            ProgressView()
                                .padding(.vertical, 50)
                        } else {
                            ForEach(viewModel.searchResults, id: \.id) { item in
                                SearchResultRow(item: item, isSelected: viewModel.isFavorite(item)) {
                                    viewModel.toggleFavorite(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Manage Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private func getSearchPlaceholder() -> String {
        switch selectedTab {
        case "tracks": return "songs..."
        case "albums": return "albums..."
        case "artists": return "artists..."
        default: return "items..."
        }
    }
}

#Preview {
    SettingsView()
}