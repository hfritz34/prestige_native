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
    @StateObject private var appearanceManager = AppearanceManager.shared
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(authManager)
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.colorScheme)
                .onOpenURL { url in
                    print("🔵 App: ==========================================")
                    print("🔵 App: RECEIVED URL CALLBACK!")
                    print("🔵 App: ==========================================")
                    print("🔵 App: Full URL: \(url)")
                    print("🔵 App: URL scheme: \(url.scheme ?? "nil")")
                    print("🔵 App: URL host: \(url.host ?? "nil")")
                    print("🔵 App: URL path: \(url.path)")
                    print("🔵 App: URL query: \(url.query ?? "nil")")
                    print("🔵 App: URL fragment: \(url.fragment ?? "nil")")
                    
                    // Let Auth0 handle the callback
                    print("🔵 App: About to let Auth0 SDK handle this URL...")
                    print("🔵 App: ==========================================")
                }
        }
    }
}
