//
//  FriendNavigationModels.swift
//  Models for friend context navigation
//

import Foundation

/// Navigation context for friend browsing
struct FriendNavigationContext {
    let friendId: String
    let friendName: String
    let isInFriendContext: Bool
    
    /// Create navigation context for friend browsing
    init(friendId: String, friendName: String) {
        self.friendId = friendId
        self.friendName = friendName
        self.isInFriendContext = true
    }
}

/// Navigation item for friend content - used for sheet presentation
struct FriendNavigationItem: Identifiable {
    let id = UUID()
    let prestigeItem: PrestigeDisplayItem
    let friendName: String
    let friendId: String
    let rank: Int
    
    /// Create a friend navigation item with the friend's prestige data
    init(prestigeItem: PrestigeDisplayItem, friendName: String, friendId: String, rank: Int) {
        self.prestigeItem = prestigeItem
        self.friendName = friendName
        self.friendId = friendId
        self.rank = rank
    }
}

/// Item type enum for friend context navigation
enum FriendItemType: String, CaseIterable {
    case track = "track"
    case album = "album" 
    case artist = "artist"
    
    var displayName: String {
        switch self {
        case .track: return "Track"
        case .album: return "Album"
        case .artist: return "Artist"
        }
    }
    
    var iconName: String {
        switch self {
        case .track: return "music.note"
        case .album: return "square.stack"
        case .artist: return "music.mic"
        }
    }
}

/// Friend context state for tracking navigation
struct FriendContextState {
    let isInFriendContext: Bool
    let currentFriend: FriendNavigationContext?
    let navigatedFromFriend: Bool
    
    init(isInFriendContext: Bool = false, currentFriend: FriendNavigationContext? = nil, navigatedFromFriend: Bool = false) {
        self.isInFriendContext = isInFriendContext
        self.currentFriend = currentFriend
        self.navigatedFromFriend = navigatedFromFriend
    }
    
    /// Create friend context state
    static func friendContext(friendId: String, friendName: String) -> FriendContextState {
        return FriendContextState(
            isInFriendContext: true,
            currentFriend: FriendNavigationContext(friendId: friendId, friendName: friendName),
            navigatedFromFriend: true
        )
    }
    
    /// Create user context state (normal mode)
    static var userContext: FriendContextState {
        return FriendContextState()
    }
}