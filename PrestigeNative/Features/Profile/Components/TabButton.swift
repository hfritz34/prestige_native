//
//  TabButton.swift
//  Custom tab button for profile content sections
//
//  Used to switch between tracks, albums, and artists views.
//

import SwiftUI

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? .purple : .secondary)
            .background(
                VStack {
                    Spacer()
                    if isSelected {
                        Rectangle()
                            .fill(Color.purple)
                            .frame(height: 2)
                    }
                }
            )
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        TabButton(title: "Albums", icon: "square.stack", isSelected: true) {}
        TabButton(title: "Tracks", icon: "music.note", isSelected: false) {}
        TabButton(title: "Artists", icon: "music.mic", isSelected: false) {}
    }
}