//
//  Container.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation

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

    var selectedIcon: ContainerIcon? {
        ContainerIcon(rawValue: iconKey ?? "")
    }

    var resolvedIcon: ContainerIcon {
        selectedIcon ?? .shippingBox
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
