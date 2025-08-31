//
//  PrestigeSelection.swift
//  Shared model for prestige item selection
//

import Foundation

struct PrestigeSelection: Identifiable {
    let id = UUID()
    let item: PrestigeDisplayItem
    let rank: Int
}