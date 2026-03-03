//
//  ExportModels.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation

enum BoxIndexSchemaVersion {
    static let current = 1
}

struct BoxIndexExportBundle: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let appName: String
    let containers: [ContainerExportRecord]
    let items: [ContainerItemExportRecord]
}

struct ContainerExportRecord: Codable, Identifiable {
    let id: UUID
    let name: String
    let labelCode: String
    let location: String
    let subLocation: String?
    let notes: String?
    let colorTag: String?
    let photoFileName: String?
    let aliases: [String]
    let createdAt: Date
    let updatedAt: Date
    let isArchived: Bool
}

struct ContainerItemExportRecord: Codable, Identifiable {
    let id: UUID
    let containerID: UUID
    let name: String
    let quantity: Int?
    let notes: String?
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
}

extension ContainerExportRecord {
    init(container: Container, photoFileName: String?) {
        self.id = container.id
        self.name = container.name
        self.labelCode = container.labelCode
        self.location = container.location
        self.subLocation = container.subLocation
        self.notes = container.notes
        self.colorTag = container.colorTag
        self.photoFileName = photoFileName
        self.aliases = container.aliases
        self.createdAt = container.createdAt
        self.updatedAt = container.updatedAt
        self.isArchived = container.isArchived
    }
}

extension ContainerItemExportRecord {
    init(item: ContainerItem, containerID: UUID) {
        self.id = item.id
        self.containerID = containerID
        self.name = item.name
        self.quantity = item.quantity
        self.notes = item.notes
        self.tags = item.tags
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
    }
}
