//
//  NetworkSimulator.swift
//  Network Speed Simulation for Testing (Debug builds only)
//
//  Simulates different network conditions to test loading performance
//  and ensure uniform loading behavior across various speeds
//

import Foundation
import SwiftUI

#if DEBUG
class NetworkSimulator {
    static let shared = NetworkSimulator()
    
    enum NetworkSpeed: CaseIterable {
        case fast, medium, slow, verySlow, offline
        
        var delay: TimeInterval {
            switch self {
            case .fast: return 0
            case .medium: return 0.5
            case .slow: return 2.0
            case .verySlow: return 5.0
            case .offline: return 0
            }
        }
        
        var displayName: String {
            switch self {
            case .fast: return "Fast (WiFi/5G)"
            case .medium: return "Medium (4G)"
            case .slow: return "Slow (3G)"
            case .verySlow: return "Very Slow (2G)"
            case .offline: return "Offline"
            }
        }
        
        var emoji: String {
            switch self {
            case .fast: return "🚀"
            case .medium: return "🚗"
            case .slow: return "🚶‍♂️"
            case .verySlow: return "🐌"
            case .offline: return "❌"
            }
        }
    }
    
    private(set) var currentSpeed: NetworkSpeed = .fast
    private(set) var isEnabled: Bool = false
    
    private init() {}
    
    func enableSimulation(speed: NetworkSpeed) {
        currentSpeed = speed
        isEnabled = true
        print("🌐 Network simulation enabled: \(speed.emoji) \(speed.displayName)")
    }
    
    func disableSimulation() {
        isEnabled = false
        currentSpeed = .fast
        print("🌐 Network simulation disabled")
    }
    
    func simulateDelay() async throws {
        guard isEnabled else { return }
        
        if currentSpeed == .offline {
            throw NetworkError.noConnection
        }
        
        let delay = currentSpeed.delay
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
}

enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .noConnection: return "No internet connection"
        case .timeout: return "Request timed out"
        }
    }
}

extension View {
    @ViewBuilder
    func networkSpeedControls() -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    ForEach(NetworkSimulator.NetworkSpeed.allCases, id: \.self) { speed in
                        Button(action: {
                            if speed == NetworkSimulator.shared.currentSpeed && NetworkSimulator.shared.isEnabled {
                                NetworkSimulator.shared.disableSimulation()
                            } else {
                                NetworkSimulator.shared.enableSimulation(speed: speed)
                            }
                        }) {
                            HStack {
                                Text("\(speed.emoji) \(speed.displayName)")
                                if NetworkSimulator.shared.currentSpeed == speed && NetworkSimulator.shared.isEnabled {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(NetworkSimulator.shared.isEnabled ? .red : .primary)
                }
            }
        }
    }
}

#else
// Release builds - NetworkSimulator is disabled
class NetworkSimulator {
    static let shared = NetworkSimulator()
    private init() {}
    
    func simulateDelay() async throws {
        // No-op in release builds
    }
}

enum NetworkError: Error {
    case noConnection
    case timeout
}

extension View {
    func networkSpeedControls() -> some View {
        self // No-op in release builds
    }
}
#endif