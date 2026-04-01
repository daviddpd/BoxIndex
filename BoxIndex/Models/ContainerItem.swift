//
//  ContainerItem.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation

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
