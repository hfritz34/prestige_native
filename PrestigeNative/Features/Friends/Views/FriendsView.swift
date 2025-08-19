//
//  FriendsView.swift
//  Friends management and social features
//

import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @StateObject private var friendsService = FriendsService()
    @State private var searchText = ""
    @State private var showingSearchResults = false
    @State private var selectedFriend: FriendResponse?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(
                    text: $searchText,
                    placeholder: "Search users by username...",
                    onSearchTextChanged: { query in
                        if !query.isEmpty {
                            Task {
                                await viewModel.searchUsers(query: query)
                                showingSearchResults = true
                            }
                        } else {
                            showingSearchResults = false
                            viewModel.clearSearchResults()
                        }
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content
                if showingSearchResults {
                    searchResultsView
                } else {
                    friendsListView
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .task {
                await viewModel.loadFriends()
            }
            .refreshable {
                await friendsService.refreshFriendsData()
                await viewModel.loadFriends()
            }
        }
    }
    
    // MARK: - Friends List
    
    private var friendsListView: some View {
        ScrollView {
            if viewModel.friends.isEmpty {
                emptyStateView
                    .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.friends) { friend in
                        FriendRowView(friend: friend)
                            .onTapGesture {
                                selectedFriend = friend
                            }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedFriend) { friend in
            FriendProfileView(friendId: friend.friendId)
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.searchResults) { user in
                    UserSearchRowView(
                        user: user,
                        isAlreadyFriend: viewModel.isFriend(userId: user.id),
                        onAddFriend: {
                            Task {
                                await viewModel.addFriend(friendId: user.id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Text("Search for users by username to add them as friends")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("Friends you add will show up here with their music taste and listening stats")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Friend Row View

struct FriendRowView: View {
    let friend: FriendResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            if let profilePicUrl = friend.profilePicUrl {
                CachedAsyncImage(
                    url: profilePicUrl,
                    placeholder: Image(systemName: "person.crop.circle.fill")
                )
                .artistImage(size: 50)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.nickname ?? friend.name)
                    .font(.headline)
                
                if let nickname = friend.nickname, nickname != friend.name {
                    Text("@\(friend.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - User Search Row View

struct UserSearchRowView: View {
    let user: UserResponse
    let isAlreadyFriend: Bool
    let onAddFriend: () -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            if let profilePicUrl = user.profilePictureUrl {
                CachedAsyncImage(
                    url: profilePicUrl,
                    placeholder: Image(systemName: "person.crop.circle.fill")
                )
                .artistImage(size: 50)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.nickname ?? user.name)
                    .font(.headline)
                
                Text("@\(user.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Add Button
            if isAlreadyFriend {
                Label("Friend", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Button(action: {
                    isLoading = true
                    onAddFriend()
                }) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Label("Add", systemImage: "person.badge.plus")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var text: String
    let placeholder: String
    let onSearchTextChanged: (String) -> Void
    
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .onChange(of: text) { newValue in
                        onSearchTextChanged(newValue)
                    }
                    .onTapGesture {
                        isEditing = true
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onSearchTextChanged("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isEditing {
                Button("Cancel") {
                    text = ""
                    isEditing = false
                    onSearchTextChanged("")
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.default, value: isEditing)
    }
}

// MARK: - Preview

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}