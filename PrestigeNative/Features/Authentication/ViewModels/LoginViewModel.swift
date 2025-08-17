//
//  LoginViewModel.swift
//  Authentication ViewModel for Login Flow
//
//  Handles login logic and integrates with AuthManager.
//  Equivalent to useAuth hook from the web application.
//

import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: AuthError?
    @Published var isAuthenticated = false
    
    private let authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authManager: AuthManager = AuthManager.shared) {
        self.authManager = authManager
        setupBindings()
    }
    
    private func setupBindings() {
        authManager.$isAuthenticated
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        authManager.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        authManager.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    func login() {
        Task {
            await authManager.login()
        }
    }
    
    func logout() {
        Task {
            await authManager.logout()
        }
    }
    
    func clearError() {
        error = nil
    }
}