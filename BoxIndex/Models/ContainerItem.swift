//
//  ContainerItem.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation
import SwiftData

@Model
final class ContainerItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int?
    var notes: String?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var container: Container?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int? = nil,
        notes: String? = nil,
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        container: Container? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.notes = notes
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.container = container
    }
}

extension ContainerItem {
    var quantityText: String? {
        guard let quantity else {
            return nil
        }

        return "\(quantity)"
    }

    var tagSummary: String? {
        let cleanedTags = tags
            .map(\.trimmed)
            .filter { !$0.isEmpty }

        return cleanedTags.isEmpty ? nil : cleanedTags.joined(separator: ", ")
    }

    func touch() {
        updatedAt = .now
    }
}
