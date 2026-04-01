//
//  AppSettings.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation

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

extension AppSettings {
    var preferredExportFormat: ExportFormatPreference {
        get { ExportFormatPreference(rawValue: preferredExportFormatRawValue) ?? .folderBundle }
        set {
            preferredExportFormatRawValue = newValue.rawValue
            updatedAt = .now
        }
    }
}
