//
//  AppearanceManager.swift
//  Appearance Settings Manager
//
//  Manages dark/light mode preferences with dark mode as default
//

import SwiftUI
import UIKit

class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    @Published var colorScheme: ColorScheme = .dark
    
    private let userDefaults = UserDefaults.standard
    private let colorSchemeKey = "selectedColorScheme"
    
    private init() {
        loadColorScheme()
        applyColorScheme()
    }
    
    private func loadColorScheme() {
        let savedScheme = userDefaults.string(forKey: colorSchemeKey) ?? "dark"
        colorScheme = savedScheme == "light" ? .light : .dark
    }
    
    func setColorScheme(_ scheme: ColorScheme) {
        colorScheme = scheme
        let schemeString = scheme == .light ? "light" : "dark"
        userDefaults.set(schemeString, forKey: colorSchemeKey)
        applyColorScheme()
    }
    
    private func applyColorScheme() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = self.colorScheme == .dark ? .dark : .light
                }
            }
        }
    }
}