//
//  BoxIndexMigrationPlan.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

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
}

enum BoxIndexMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            BoxIndexSchemaV1.self,
        ]
    }

    static var stages: [MigrationStage] {
        []
    }
}
