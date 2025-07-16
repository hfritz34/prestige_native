//
//  LoadingButton.swift
//  Reusable loading button component for authentication
//
//  Custom button component with loading state support.
//

import SwiftUI

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [.purple, .blue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "person.badge.key")
                        .font(.title3)
                }
                
                Text(isLoading ? "Loading..." : title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(gradient)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingButton(title: "Sign In", isLoading: false) {}
        LoadingButton(title: "Sign In", isLoading: true) {}
    }
    .padding()
}