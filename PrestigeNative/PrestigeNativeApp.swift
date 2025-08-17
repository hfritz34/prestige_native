//
//  PrestigeNativeApp.swift
//  PrestigeNative
//
//  Created by Henry Fritz on 4/7/25.
//

import SwiftUI

@main
struct PrestigeNativeApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(authManager)
        }
    }
}
