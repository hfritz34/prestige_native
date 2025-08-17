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
    private let auth0Domain = "dev-tfgyd3i2jqk0igxv.us.auth0.com"
    private let auth0ClientId = "NZ5N1xnHOdgdVuXNPoBuNydMhg83Oe0p"
    private let auth0Audience = "https://prestige-auth0-resource"
    
    private init() {
        // Initialize Auth0 CredentialsManager
        self.credentialsManager = CredentialsManager(authentication: Auth0.authentication(clientId: auth0ClientId, domain: auth0Domain))
        
        // Check for existing credentials on app launch
        checkExistingSession()
    }
    
    // MARK: - Authentication Methods
    
    /// Initiate login flow with Auth0
    func login() async {
        await MainActor.run { 
            isLoading = true
            error = nil
        }
        
        do {
            print("🔵 Auth: Starting Auth0 login flow")
            
            let credentials = try await Auth0
                .webAuth(clientId: auth0ClientId, domain: auth0Domain)
                .scope("openid profile email")
                .audience(auth0Audience)
                .start()
            
            print("✅ Auth: Login successful")
            await handleSuccessfulAuth(credentials: credentials)
            
        } catch {
            print("❌ Auth: Login failed - \(error)")
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
            try await Auth0
                .webAuth(clientId: auth0ClientId, domain: auth0Domain)
                .clearSession()
            
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
            profilePictureUrl: nil
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
    let nickname: String
    let profilePictureUrl: String?
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