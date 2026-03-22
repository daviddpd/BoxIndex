//
//  AppSettings.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation
import SwiftData

enum ExportFormatPreference: String, CaseIterable, Codable, Identifiable {
    case folderBundle = "folder"
    case jsonBundle = "json"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .folderBundle:
            return "Folder Bundle"
        case .jsonBundle:
            return "JSON Bundle"
        }
    }
}

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    // Retained for store compatibility after removing the iCloud placeholder UI.
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

extension AppSettings {
    var preferredExportFormat: ExportFormatPreference {
        get { ExportFormatPreference(rawValue: preferredExportFormatRawValue) ?? .folderBundle }
        set {
            preferredExportFormatRawValue = newValue.rawValue
            updatedAt = .now
        }
    }
}
