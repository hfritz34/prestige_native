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
    @State private var selectedTab: FriendsTab = .myFriends
    
    enum FriendsTab: String, CaseIterable {
        case myFriends = "My Friends"
        case friendRequests = "Friend Requests"
        
        var displayName: String { self.rawValue }
        var icon: String {
            switch self {
            case .myFriends: return "person.2.fill"
            case .friendRequests: return "person.badge.plus"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar (only show on My Friends tab)
                if selectedTab == .myFriends {
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
                }
                
                // Tab Selector
                tabSelectorView
                
                // Content based on selected tab and search state
                if selectedTab == .myFriends {
                    if showingSearchResults {
                        searchResultsView
                    } else {
                        friendsListView
                    }
                } else {
                    friendRequestsView
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .task {
                await viewModel.loadFriends()
                await friendsService.fetchIncomingFriendRequests()
                await friendsService.fetchOutgoingFriendRequests()
            }
            .refreshable {
                await friendsService.refreshFriendsData()
                await viewModel.loadFriends()
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelectorView: some View {
        HStack(spacing: 0) {
            ForEach(FriendsTab.allCases, id: \.rawValue) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                        // Clear search when switching tabs
                        searchText = ""
                        showingSearchResults = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        
                        Text(tab.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .medium)
                        
                        // Badge for incoming friend requests
                        if tab == .friendRequests && !friendsService.incomingFriendRequests.isEmpty {
                            Text("\(friendsService.incomingFriendRequests.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(Circle().fill(Color.red))
                        }
                    }
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.purple.opacity(0.1) : Color.clear)
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
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
                        hasSentRequest: friendsService.hasSentRequestTo(friendId: user.id),
                        onAddFriend: {
                            Task {
                                await friendsService.sendFriendRequest(friendId: user.id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Friend Requests
    
    private var friendRequestsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Incoming Requests Section
                if !friendsService.incomingFriendRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Incoming Requests")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(friendsService.incomingFriendRequests) { request in
                                FriendRequestRowView(
                                    request: request,
                                    isIncoming: true,
                                    onAccept: {
                                        Task {
                                            await friendsService.acceptFriendRequest(request: request)
                                        }
                                    },
                                    onDecline: {
                                        Task {
                                            await friendsService.declineFriendRequest(request: request)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Outgoing Requests Section
                if !friendsService.outgoingFriendRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sent Requests")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(friendsService.outgoingFriendRequests) { request in
                                FriendRequestRowView(
                                    request: request,
                                    isIncoming: false,
                                    onAccept: nil,
                                    onDecline: nil
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Empty state for no friend requests
                if friendsService.incomingFriendRequests.isEmpty && friendsService.outgoingFriendRequests.isEmpty {
                    friendRequestsEmptyStateView
                        .padding(.top, 60)
                }
            }
            .padding(.top, 16)
        }
    }
    
    private var friendRequestsEmptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No Friend Requests")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Text("You don't have any pending friend requests")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("Send friend requests by searching for users in the 'My Friends' tab")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
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
    let hasSentRequest: Bool
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
            
            // Add Button / Status
            if isAlreadyFriend {
                Label("Friend", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if hasSentRequest {
                Label("Requested", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.orange)
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

// MARK: - Friend Request Row View

struct FriendRequestRowView: View {
    let request: FriendRequestResponse
    let isIncoming: Bool
    let onAccept: (() -> Void)?
    let onDecline: (() -> Void)?
    
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            let profilePicUrl = isIncoming ? request.fromUserProfilePicUrl : request.toUserProfilePicUrl
            let displayName = isIncoming ? (request.fromUserNickname ?? request.fromUserName) : (request.toUserNickname ?? request.toUserName)
            let username = isIncoming ? request.fromUserName : request.toUserName
            
            if let profilePicUrl = profilePicUrl {
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
            
            // Request Info
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                
                if displayName != username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(request.createdAt.timeAgoString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons for incoming requests
            if isIncoming {
                HStack(spacing: 8) {
                    // Decline button
                    Button(action: {
                        isLoading = true
                        onDecline?()
                    }) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.red)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.red.opacity(0.1)))
                    
                    // Accept button
                    Button(action: {
                        isLoading = true
                        onAccept?()
                    }) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.green)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.green.opacity(0.1)))
                }
            } else {
                // Status for outgoing requests
                VStack(spacing: 4) {
                    Text(request.status.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(request.status == .pending ? .orange : .secondary)
                    
                    if request.status == .pending {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}