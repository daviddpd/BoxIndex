//
//  Container.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation
import SwiftData

@Model
final class Container {
    @Attribute(.unique) var id: UUID
    var name: String
    var labelCode: String
    var location: String
    var subLocation: String?
    var notes: String?
    var colorTag: String?
    var photoPath: String?
    var aliases: [String]
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \ContainerItem.container)
    var items: [ContainerItem]

    init(
        id: UUID = UUID(),
        name: String,
        labelCode: String,
        location: String,
        subLocation: String? = nil,
        notes: String? = nil,
        colorTag: String? = nil,
        photoPath: String? = nil,
        aliases: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.labelCode = labelCode
        self.location = location
        self.subLocation = subLocation
        self.notes = notes
        self.colorTag = colorTag
        self.photoPath = photoPath
        self.aliases = aliases
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.items = []
    }
}

extension Container {
    var displayTitle: String {
        let trimmedName = name.trimmed
        return trimmedName.isEmpty ? "Untitled Container" : trimmedName
    }

    var locationDisplay: String {
        let trimmedLocation = location.trimmed
        let trimmedSubLocation = subLocation?.trimmed

        guard let trimmedSubLocation, !trimmedSubLocation.isEmpty else {
            return trimmedLocation
        }

        if trimmedLocation.isEmpty {
            return trimmedSubLocation
        }

        return "\(trimmedLocation) • \(trimmedSubLocation)"
    }

    var aliasSummary: String? {
        let cleanedAliases = aliases
            .map(\.trimmed)
            .filter { !$0.isEmpty }

        return cleanedAliases.isEmpty ? nil : cleanedAliases.joined(separator: ", ")
    }

    var qrPayload: String {
        QRCodeService.prefix + id.uuidString.uppercased()
    }

    var searchableValues: [String] {
        let itemNames = items.map(\.name)
        let itemNotes = items.compactMap(\.notes)

        return [
            name,
            labelCode,
            location,
            subLocation,
            notes,
            aliasSummary,
        ]
        .compactMap { $0 }
        + itemNames
        + itemNotes
    }

    func touch() {
        updatedAt = .now
    }
}
