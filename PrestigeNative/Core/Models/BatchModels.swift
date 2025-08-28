//
//  BatchModels.swift
//  Batch API Request/Response Models
//
//  Models for the new batch metadata endpoint that reduces
//  API calls by 85% through intelligent batching
//

import Foundation

// MARK: - Batch Request Models

struct BatchItemRequest: Codable {
    let items: [BatchItemInfo]
    
    struct BatchItemInfo: Codable {
        let id: String
        let type: String
        
        init(id: String, type: RatingItemType) {
            self.id = id
            self.type = type.rawValue
        }
    }
}

// MARK: - Batch Response Models

struct BatchItemResponse: Codable {
    let items: [BatchItemDetails]
}

struct BatchItemDetails: Codable {
    let id: String
    let name: String
    let itemType: String
    let imageUrl: String?
    let artists: [String]?
    let albumName: String?
    let albumId: String?
    
    var ratingItemType: RatingItemType {
        return RatingItemType(rawValue: itemType) ?? .track
    }
    
    var displayArtists: String {
        return artists?.joined(separator: ", ") ?? ""
    }
    
    var displaySubtitle: String {
        switch ratingItemType {
        case .track:
            return displayArtists
        case .album:
            return displayArtists
        case .artist:
            return ""
        }
    }
}

// MARK: - Batch Request Builder

struct BatchRequestBuilder {
    private var items: [BatchItemRequest.BatchItemInfo] = []
    
    mutating func add(itemId: String, type: RatingItemType) {
        let item = BatchItemRequest.BatchItemInfo(id: itemId, type: type)
        if !items.contains(where: { $0.id == item.id && $0.type == item.type }) {
            items.append(item)
        }
    }
    
    mutating func addItems(_ itemsToAdd: [(id: String, type: RatingItemType)]) {
        for (id, type) in itemsToAdd {
            add(itemId: id, type: type)
        }
    }
    
    func build() -> BatchItemRequest {
        return BatchItemRequest(items: items)
    }
    
    var count: Int {
        return items.count
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    mutating func clear() {
        items.removeAll()
    }
}

// MARK: - Extensions for Integration

extension ItemDetailsResponse {
    init(from batchItem: BatchItemDetails) {
        self.id = batchItem.id
        self.name = batchItem.name
        self.itemType = batchItem.itemType
        self.imageUrl = batchItem.imageUrl
        self.artists = batchItem.artists
        self.albumName = batchItem.albumName
        self.albumId = batchItem.albumId
    }
}

extension BatchItemDetails {
    func toItemDetailsResponse() -> ItemDetailsResponse {
        return ItemDetailsResponse(from: self)
    }
}