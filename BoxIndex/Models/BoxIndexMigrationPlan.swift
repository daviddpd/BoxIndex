//
//  BoxIndexMigrationPlan.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation
import SwiftData

enum BoxIndexSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Container.self,
            ContainerItem.self,
            AppSettings.self,
        ]
    }

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

    @Model
    final class AppSettings {
        @Attribute(.unique) var id: UUID
        var isICloudSyncEnabled: Bool
        var defaultLocation: String
        var preferredExportFormatRawValue: String
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            isICloudSyncEnabled: Bool = false,
            defaultLocation: String = "",
            preferredExportFormat: ExportFormatPreference = .folderBundle,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.isICloudSyncEnabled = isICloudSyncEnabled
            self.defaultLocation = defaultLocation
            self.preferredExportFormatRawValue = preferredExportFormat.rawValue
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

enum BoxIndexSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Container.self,
            ContainerItem.self,
            AppSettings.self,
        ]
    }

    @Model
    final class Container {
        @Attribute(.unique) var id: UUID
        var name: String
        var labelCode: String
        var location: String
        var subLocation: String?
        var notes: String?
        var colorTag: String?
        var iconKey: String?
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
            iconKey: String? = nil,
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
            self.iconKey = iconKey
            self.photoPath = photoPath
            self.aliases = aliases
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isArchived = isArchived
            self.items = []
        }
    }

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

    @Model
    final class AppSettings {
        @Attribute(.unique) var id: UUID
        var isICloudSyncEnabled: Bool
        var defaultLocation: String
        var preferredExportFormatRawValue: String
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            isICloudSyncEnabled: Bool = false,
            defaultLocation: String = "",
            preferredExportFormat: ExportFormatPreference = .folderBundle,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.isICloudSyncEnabled = isICloudSyncEnabled
            self.defaultLocation = defaultLocation
            self.preferredExportFormatRawValue = preferredExportFormat.rawValue
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

typealias Container = BoxIndexSchemaV2.Container
typealias ContainerItem = BoxIndexSchemaV2.ContainerItem
typealias AppSettings = BoxIndexSchemaV2.AppSettings

enum BoxIndexMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            BoxIndexSchemaV1.self,
            BoxIndexSchemaV2.self,
        ]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: BoxIndexSchemaV1.self,
        toVersion: BoxIndexSchemaV2.self
    )

    static var stages: [MigrationStage] {
        [
            migrateV1toV2,
        ]
    }
}
