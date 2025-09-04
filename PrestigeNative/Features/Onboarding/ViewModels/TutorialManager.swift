//
//  TutorialManager.swift
//  Tutorial State Management
//
//  Manages tutorial display state and user preferences
//

import SwiftUI
import Combine

@MainActor
class TutorialManager: ObservableObject {
    @Published var shouldShowTutorial = false
    @Published var hasSeenTutorial = false
    
    static let shared = TutorialManager()
    
    private let hasSeenTutorialKey = "hasSeenOnboardingTutorial"
    
    private init() {
        loadTutorialState()
    }
    
    private func loadTutorialState() {
        hasSeenTutorial = UserDefaults.standard.bool(forKey: hasSeenTutorialKey)
    }
    
    func markTutorialAsCompleted() {
        hasSeenTutorial = true
        shouldShowTutorial = false
        UserDefaults.standard.set(true, forKey: hasSeenTutorialKey)
    }
    
    func showTutorial() {
        shouldShowTutorial = true
    }
    
    func resetTutorial() {
        hasSeenTutorial = false
        shouldShowTutorial = true
        UserDefaults.standard.removeObject(forKey: hasSeenTutorialKey)
    }
    
    func checkIfShouldShowTutorial() {
        // Show tutorial if user hasn't seen it and has completed basic onboarding
        if !hasSeenTutorial {
            // Add a small delay to ensure home view is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.shouldShowTutorial = true
            }
        }
    }
}