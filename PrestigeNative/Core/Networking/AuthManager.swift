//
//  AuthManager.swift
//  Auth0 Authentication Manager for Prestige iOS
//
//  This file handles all authentication logic including Auth0 integration,
//  token management, and user session handling. Equivalent to Auth0 hooks
//  from the web application.
//

import Foundation
import Combine
import Auth0
import JWTDecode

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var user: AuthUser?
    @Published var error: AuthError?
    @Published var userIsSetup = false
    
    private var credentials: Credentials?
    private let credentialsManager: CredentialsManager
    
    // Auth0 Configuration
    private let auth0Domain: String
    private let auth0ClientId: String
    private let auth0Audience: String?
    
    private init() {
        print("🔵 Auth: Initializing AuthManager...")
        
        // Load Auth0 configuration from Auth0.plist
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist") else {
            print("❌ Auth: Auth0.plist file not found at path")
            fatalError("Auth0.plist not found")
        }
        
        print("🔵 Auth: Found Auth0.plist at path: \(path)")
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            print("❌ Auth: Could not load Auth0.plist contents")
            fatalError("Could not load Auth0.plist contents")
        }
        
        print("🔵 Auth: Loaded Auth0.plist with keys: \(plist.allKeys)")
        
        guard let domain = plist["Domain"] as? String,
              let clientId = plist["ClientId"] as? String else {
            print("❌ Auth: Missing required keys in Auth0.plist")
            print("🔵 Auth: Domain: \(plist["Domain"] ?? "nil")")
            print("🔵 Auth: ClientId: \(plist["ClientId"] ?? "nil")")
            fatalError("Auth0.plist missing required keys")
        }
        
        self.auth0Domain = domain
        self.auth0ClientId = clientId
        self.auth0Audience = plist["Audience"] as? String
        
        print("🔵 Auth: Configuration loaded:")
        print("🔵 Auth: - Domain: \(auth0Domain)")
        print("🔵 Auth: - ClientId: \(auth0ClientId)")
        print("🔵 Auth: - Audience: \(auth0Audience ?? "nil")")
        print("🔵 Auth: - Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        
        // Initialize Auth0 CredentialsManager
        self.credentialsManager = CredentialsManager(authentication: Auth0.authentication(clientId: auth0ClientId, domain: auth0Domain))
        
        print("🔵 Auth: CredentialsManager initialized")
        
        // Run debug configuration check
        debugConfiguration()
        
        // Check for existing credentials on app launch
        checkExistingSession()
    }
    
    private var auth0CallbackURL: URL? {
        guard let bundleId = Bundle.main.bundleIdentifier else { 
            print("❌ Auth: Could not get bundle identifier for callback URL")
            return nil
        }
        
        // Try simpler callback format first: {BUNDLE_ID}://callback
        let urlString = "\(bundleId)://callback"
        print("🔵 Auth: Constructing callback URL:")
        print("🔵 Auth: - Bundle ID: \(bundleId)")
        print("🔵 Auth: - Simplified URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Auth: Could not create valid URL from string: \(urlString)")
            return nil
        }
        
        print("🔵 Auth: Successfully created callback URL: \(url)")
        return url
    }
    
    // MARK: - Authentication Methods
    
    /// Initiate login flow with Auth0
    func login() async {
        print("🔵 Auth: Login method called")
        await MainActor.run { 
            isLoading = true
            error = nil
        }
        
        do {
            print("🔵 Auth: Starting Auth0 login flow")
            print("🔵 Auth: Building WebAuth with:")
            print("🔵 Auth: - ClientId: \(auth0ClientId)")
            print("🔵 Auth: - Domain: \(auth0Domain)")
            
            var webAuth = Auth0
                .webAuth(clientId: auth0ClientId, domain: auth0Domain)
                .scope("openid profile email offline_access")
            
            print("🔵 Auth: Base WebAuth created with scope")
            
            if let audience = auth0Audience, !audience.isEmpty {
                print("🔵 Auth: Adding audience: \(audience)")
                webAuth = webAuth.audience(audience)
            } else {
                print("🔵 Auth: No audience configured")
            }
            
            if let redirect = auth0CallbackURL {
                print("🔵 Auth: Setting redirect URL: \(redirect)")
                webAuth = webAuth.redirectURL(redirect)
            } else {
                print("❌ Auth: No redirect URL available!")
            }
            
            print("🔵 Auth: About to start WebAuth flow...")
            print("🔵 Auth: This should open Safari with Auth0 login page...")
            
            // Add timeout handling
            let credentials = try await withTimeout(seconds: 30) {
                let result = try await webAuth.start()
                print("🔵 Auth: WebAuth.start() returned successfully")
                return result
            }
            
            print("✅ Auth: Login successful, got credentials")
            await handleSuccessfulAuth(credentials: credentials)
            
        } catch {
            print("❌ Auth: Login failed with error: \(error)")
            print("❌ Auth: Error type: \(type(of: error))")
            print("❌ Auth: Error description: \(error.localizedDescription)")
            
            if let auth0Error = error as? Auth0.WebAuthError {
                print("❌ Auth: Auth0 specific error: \(auth0Error)")
            }
            
            await MainActor.run {
                self.isLoading = false
                self.error = .loginFailed(error.localizedDescription)
            }
        }
    }
    
    /// Logout user and clear session
    func logout() async {
        await MainActor.run { isLoading = true }
        
        do {
            print("🔵 Auth: Starting logout")
            
            // Clear local credentials first
            _ = credentialsManager.clear()
            
            // Logout from Auth0
            var webAuth = Auth0
                .webAuth(clientId: auth0ClientId, domain: auth0Domain)
            if let redirect = auth0CallbackURL {
                webAuth = webAuth.redirectURL(redirect)
            }
            try await webAuth.clearSession()
            
            print("✅ Auth: Logout successful")
            await MainActor.run {
                user = nil
                credentials = nil
                isAuthenticated = false
                isLoading = false
                error = nil
            }
            
        } catch {
            print("❌ Auth: Logout failed - \(error)")
            // Even if logout fails, clear local state
            await MainActor.run {
                user = nil
                credentials = nil
                isAuthenticated = false
                isLoading = false
                self.error = .logoutFailed(error.localizedDescription)
            }
        }
    }
    
    /// Get current access token, refreshing if necessary
    func getAccessToken() async throws -> String {
        // If we have current credentials, return them
        if let credentials = credentials, !credentials.accessToken.isEmpty {
            return credentials.accessToken
        }
        
        // Try to get fresh credentials
        do {
            let freshCredentials = try await credentialsManager.credentials()
            self.credentials = freshCredentials
            return freshCredentials.accessToken
        } catch {
            print("❌ Auth: Failed to get access token - \(error)")
            throw AuthError.tokenRefreshFailed
        }
    }
    
    /// Refresh the access token
    func refreshToken() async -> Bool {
        do {
            let freshCredentials = try await credentialsManager.credentials()
            await MainActor.run {
                self.credentials = freshCredentials
            }
            return true
        } catch {
            print("❌ Auth: Token refresh failed - \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func checkExistingSession() {
        Task {
            await MainActor.run { isLoading = true }
            
            // Check if we have valid stored credentials
            guard credentialsManager.canRenew() else {
                await MainActor.run {
                    isAuthenticated = false
                    isLoading = false
                }
                return
            }
            
            do {
                // Try to get fresh credentials
                let credentials = try await credentialsManager.credentials()
                await handleSuccessfulAuth(credentials: credentials)
            } catch {
                print("❌ Auth: Failed to restore session - \(error)")
                await MainActor.run {
                    isAuthenticated = false
                    isLoading = false
                    self.error = .sessionExpired
                }
            }
        }
    }
    
    private func handleSuccessfulAuth(credentials: Credentials) async {
        print("🔵 Auth: Processing successful authentication")
        
        // Store credentials securely
        let stored = credentialsManager.store(credentials: credentials)
        if !stored {
            print("⚠️ Auth: Failed to store credentials securely")
        }
        
        // Extract user ID from the ID token (which contains user info)
        print("🔵 Auth: Attempting to extract user ID from ID token...")
        let extractedUserId = extractUserIdFromIdToken(credentials.idToken)
        print("🔵 Auth: Final extracted user ID: \(extractedUserId ?? "nil")")
        
        // Only proceed if we have a valid user ID
        guard let validUserId = extractedUserId, !validUserId.isEmpty else {
            print("❌ Auth: Failed to extract valid user ID, cannot proceed")
            await MainActor.run {
                self.isLoading = false
                self.error = .sessionRestoreFailed
            }
            return
        }
        
        let authUser = AuthUser(
            id: validUserId,
            email: "",
            nickname: "User", 
            profilePictureUrl: nil,
            name: "User",
            bio: nil
        )
        
        await MainActor.run {
            self.credentials = credentials
            self.user = authUser
            self.isAuthenticated = true
            self.isLoading = false
            self.error = nil
        }
        
        // Inject this AuthManager into APIClient for authenticated requests
        APIClient.shared.setAuthManager(self)
        print("✅ Auth: Injected AuthManager into APIClient")
        print("✅ Auth: User authenticated successfully - \(authUser.nickname)")
    }
    
    // MARK: - Timeout Helper
    
    /// Add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AuthError.loginFailed("Authentication timeout after \(seconds) seconds")
            }
            
            // Return the first completed task and cancel others
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Debug Methods
    
    /// Debug method to verify Auth0 and URL scheme configuration
    func debugConfiguration() {
        print("🔧 Auth Debug: Configuration Check")
        print("🔧 Auth Debug: ======================")
        print("🔧 Auth Debug: Domain: \(auth0Domain)")
        print("🔧 Auth Debug: ClientId: \(auth0ClientId)")
        print("🔧 Auth Debug: Audience: \(auth0Audience ?? "nil")")
        print("🔧 Auth Debug: Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        print("🔧 Auth Debug: Callback URL: \(auth0CallbackURL?.absoluteString ?? "nil")")
        
        // Check URL schemes in Info.plist
        if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
            print("🔧 Auth Debug: Registered URL Schemes:")
            for urlType in urlTypes {
                if let schemes = urlType["CFBundleURLSchemes"] as? [String],
                   let name = urlType["CFBundleURLName"] as? String {
                    print("🔧 Auth Debug: - \(name): \(schemes)")
                }
            }
        } else {
            print("🔧 Auth Debug: No URL schemes found in Info.plist")
        }
        
        // Verify Auth0.plist exists and is readable
        if let path = Bundle.main.path(forResource: "Auth0", ofType: "plist") {
            print("🔧 Auth Debug: Auth0.plist found at: \(path)")
        } else {
            print("🔧 Auth Debug: Auth0.plist NOT found")
        }
        
        print("🔧 Auth Debug: ======================")
    }
    
    // MARK: - Helper Methods
    
    /// Extract user ID from Auth0 ID token using JWTDecode library
    private func extractUserIdFromIdToken(_ idToken: String?) -> String? {
        guard let idToken = idToken else {
            print("❌ Auth: No ID token available")
            return nil
        }
        
        print("🔵 Auth: ID token available, length: \(idToken.count)")
        
        do {
            let jwt = try decode(jwt: idToken)
            print("🔵 Auth: JWT decoded successfully")
            print("🔵 Auth: JWT claims: \(jwt.body.keys.sorted())")
            
            // The 'sub' claim contains the user ID
            if let sub = jwt.subject {
                print("✅ Auth: Successfully extracted full sub: \(sub)")
                
                // Process like web app: user.sub.split("|").pop()
                let userIdComponents = sub.split(separator: "|")
                let processedUserId = String(userIdComponents.last ?? "")
                
                print("✅ Auth: Processed user ID (like web app): \(processedUserId)")
                return processedUserId.isEmpty ? nil : processedUserId
            } else {
                print("❌ Auth: No 'sub' claim found in ID token")
                return nil
            }
        } catch {
            print("❌ Auth: Failed to decode ID token: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

struct AuthUser: Codable {
    let id: String
    let email: String
    var nickname: String
    let profilePictureUrl: String?
    let name: String
    var bio: String?
    
    // Computed property for display name (uses nickname or falls back to name)
    var displayName: String {
        return nickname.isEmpty ? name : nickname
    }
}

enum AuthError: Error, LocalizedError, Equatable {
    case notAuthenticated
    case loginFailed(String)
    case logoutFailed(String)
    case tokenRefreshFailed
    case sessionExpired
    case sessionRestoreFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .loginFailed(let message):
            return "Login failed: \(message)"
        case .logoutFailed(let message):
            return "Logout failed: \(message)"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .sessionExpired:
            return "Session has expired. Please log in again."
        case .sessionRestoreFailed:
            return "Failed to restore previous session"
        case .networkError:
            return "Network error occurred during authentication"
        }
    }
    
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.tokenRefreshFailed, .tokenRefreshFailed),
             (.sessionExpired, .sessionExpired),
             (.sessionRestoreFailed, .sessionRestoreFailed),
             (.networkError, .networkError):
            return true
        case let (.loginFailed(lhsMessage), .loginFailed(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.logoutFailed(lhsMessage), .logoutFailed(rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}