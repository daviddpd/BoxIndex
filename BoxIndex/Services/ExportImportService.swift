//
//  ExportImportService.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation
import SwiftData

struct ExportPackage {
    let directoryURL: URL
    let displayName: String
}

struct ImportSummary {
    let containersInserted: Int
    let containersUpdated: Int
    let containersKeptLocal: Int
    let itemsInserted: Int
    let itemsUpdated: Int
    let itemsKeptLocal: Int
    let orphanItemsSkipped: Int

    var containersImported: Int {
        containersInserted + containersUpdated
    }

    var itemsImported: Int {
        itemsInserted + itemsUpdated
    }

    var statusMessage: String {
        var parts: [String] = [
            "Imported \(containersInserted) new containers",
            "updated \(containersUpdated) containers",
            "imported \(itemsInserted) new items",
            "updated \(itemsUpdated) items",
        ]

        if containersKeptLocal > 0 {
            parts.append("kept \(containersKeptLocal) newer local containers")
        }

        if itemsKeptLocal > 0 {
            parts.append("kept \(itemsKeptLocal) newer local items")
        }

        if orphanItemsSkipped > 0 {
            parts.append("skipped \(orphanItemsSkipped) orphan items")
        }

        return parts.joined(separator: ", ") + "."
    }
}

enum ImportConflictResolution: String, Codable, CaseIterable, Identifiable {
    case keepNewestRecord

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepNewestRecord:
            return "Newest Record Wins"
        }
    }

    func shouldApply(importedUpdatedAt: Date, existingUpdatedAt: Date) -> Bool {
        importedUpdatedAt >= existingUpdatedAt
    }
}

enum ExportImportError: LocalizedError {
    case invalidSelection
    case missingManifest
    case invalidBundle

    var errorDescription: String? {
        switch self {
        case .invalidSelection:
            return "The selected file does not look like a BoxIndex export."
        case .missingManifest:
            return "BoxIndex could not find a valid export manifest in that folder."
        case .invalidBundle:
            return "BoxIndex could not decode the export data."
        }
    }
}

@MainActor
final class ExportImportService {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let conflictResolution: ImportConflictResolution

    init(conflictResolution: ImportConflictResolution = .keepNewestRecord) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
        self.conflictResolution = conflictResolution
    }

    func buildExportPackage(from containers: [Container]) throws -> ExportPackage {
        let timestamp = ISO8601DateFormatter().string(from: .now)
        let folderName = "BoxIndex Export \(timestamp.replacingOccurrences(of: ":", with: "-"))"
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(folderName, isDirectory: true)
        let attachmentsURL = rootURL.appendingPathComponent("attachments", isDirectory: true)

        if FileManager.default.fileExists(atPath: rootURL.path) {
            try FileManager.default.removeItem(at: rootURL)
        }

        try FileManager.default.createDirectory(at: attachmentsURL, withIntermediateDirectories: true)

        let sortedContainers = containers.sorted {
            $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
        }

        var containerRecords: [ContainerExportRecord] = []
        var itemRecords: [ContainerItemExportRecord] = []

        for container in sortedContainers {
            let attachmentFileName = try copyAttachmentIfNeeded(for: container, to: attachmentsURL)
            containerRecords.append(ContainerExportRecord(container: container, photoFileName: attachmentFileName))

            let sortedItems = container.items.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

            itemRecords.append(contentsOf: sortedItems.map { ContainerItemExportRecord(item: $0, containerID: container.id) })
        }

        let bundle = BoxIndexExportBundle(
            schemaVersion: BoxIndexSchemaVersion.current,
            exportedAt: .now,
            appName: "BoxIndex",
            containers: containerRecords,
            items: itemRecords
        )

        try writeJSON(bundle, to: rootURL.appendingPathComponent("boxindex-export.json"))
        try writeJSON(containerRecords, to: rootURL.appendingPathComponent("containers.json"))
        try writeJSON(itemRecords, to: rootURL.appendingPathComponent("items.json"))
        try writeCSV(makeContainerCSV(records: containerRecords), to: rootURL.appendingPathComponent("containers.csv"))
        try writeCSV(makeItemCSV(records: itemRecords), to: rootURL.appendingPathComponent("items.csv"))

        return ExportPackage(directoryURL: rootURL, displayName: folderName)
    }

    func importArchive(from selectedURL: URL, into context: ModelContext) throws -> ImportSummary {
        let accessed = selectedURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                selectedURL.stopAccessingSecurityScopedResource()
            }
        }

        let bundle = try loadBundle(from: selectedURL)
        let attachmentsRoot = resolvedAttachmentsRoot(for: selectedURL)

        let existingContainers = try context.fetch(FetchDescriptor<Container>())
        let existingItems = try context.fetch(FetchDescriptor<ContainerItem>())
        var containerMap = Dictionary(uniqueKeysWithValues: existingContainers.map { ($0.id, $0) })
        var itemMap = Dictionary(uniqueKeysWithValues: existingItems.map { ($0.id, $0) })
        var containersInserted = 0
        var containersUpdated = 0
        var containersKeptLocal = 0
        var itemsInserted = 0
        var itemsUpdated = 0
        var itemsKeptLocal = 0
        var orphanItemsSkipped = 0

        for record in bundle.containers {
            let existingContainer = containerMap[record.id]
            let container = existingContainer ?? {
                let newContainer = Container(
                    id: record.id,
                    name: record.name,
                    labelCode: record.labelCode,
                    location: record.location
                )
                context.insert(newContainer)
                containerMap[record.id] = newContainer
                return newContainer
            }()

            if let existingContainer {
                guard conflictResolution.shouldApply(
                    importedUpdatedAt: record.updatedAt,
                    existingUpdatedAt: existingContainer.updatedAt
                ) else {
                    containersKeptLocal += 1
                    continue
                }

                containersUpdated += 1
            } else {
                containersInserted += 1
            }

            container.name = record.name
            container.labelCode = record.labelCode
            container.location = record.location
            container.subLocation = record.subLocation
            container.notes = record.notes
            container.colorTag = record.colorTag
            container.aliases = record.aliases
            container.createdAt = record.createdAt
            container.updatedAt = record.updatedAt
            container.isArchived = record.isArchived

            if let photoFileName = record.photoFileName,
               let attachmentsRoot,
               FileManager.default.fileExists(atPath: attachmentsRoot.appendingPathComponent(photoFileName).path) {
                let sourceURL = attachmentsRoot.appendingPathComponent(photoFileName)
                container.photoPath = try PhotoStorageService.importPhoto(from: sourceURL, replacing: container.photoPath)
            } else if record.photoFileName == nil {
                PhotoStorageService.deletePhoto(at: container.photoPath)
                container.photoPath = nil
            }
        }

        for record in bundle.items {
            guard let container = containerMap[record.containerID] else {
                orphanItemsSkipped += 1
                continue
            }

            let existingItem = itemMap[record.id]
            let item = existingItem ?? {
                let newItem = ContainerItem(
                    id: record.id,
                    name: record.name
                )
                context.insert(newItem)
                itemMap[record.id] = newItem
                return newItem
            }()

            if let existingItem {
                guard conflictResolution.shouldApply(
                    importedUpdatedAt: record.updatedAt,
                    existingUpdatedAt: existingItem.updatedAt
                ) else {
                    itemsKeptLocal += 1
                    continue
                }

                itemsUpdated += 1
            } else {
                itemsInserted += 1
            }

            item.name = record.name
            item.quantity = record.quantity
            item.notes = record.notes
            item.tags = record.tags
            item.createdAt = record.createdAt
            item.updatedAt = record.updatedAt
            item.container = container
        }

        if context.hasChanges {
            try context.save()
        }

        return ImportSummary(
            containersInserted: containersInserted,
            containersUpdated: containersUpdated,
            containersKeptLocal: containersKeptLocal,
            itemsInserted: itemsInserted,
            itemsUpdated: itemsUpdated,
            itemsKeptLocal: itemsKeptLocal,
            orphanItemsSkipped: orphanItemsSkipped
        )
    }

    private func loadBundle(from selectedURL: URL) throws -> BoxIndexExportBundle {
        if isDirectory(selectedURL) {
            let manifestURL = selectedURL.appendingPathComponent("boxindex-export.json")
            if FileManager.default.fileExists(atPath: manifestURL.path) {
                return try decodeBundle(from: manifestURL)
            }

            let containersURL = selectedURL.appendingPathComponent("containers.json")
            let itemsURL = selectedURL.appendingPathComponent("items.json")

            guard FileManager.default.fileExists(atPath: containersURL.path),
                  FileManager.default.fileExists(atPath: itemsURL.path) else {
                throw ExportImportError.missingManifest
            }

            return try buildBundleFromSplitFiles(containersURL: containersURL, itemsURL: itemsURL)
        }

        if selectedURL.lastPathComponent == "boxindex-export.json" {
            return try decodeBundle(from: selectedURL)
        }

        if selectedURL.lastPathComponent == "containers.json" {
            let itemsURL = selectedURL.deletingLastPathComponent().appendingPathComponent("items.json")
            guard FileManager.default.fileExists(atPath: itemsURL.path) else {
                throw ExportImportError.invalidSelection
            }

            return try buildBundleFromSplitFiles(containersURL: selectedURL, itemsURL: itemsURL)
        }

        if selectedURL.pathExtension.lowercased() == "json",
           let decoded = try? decodeBundle(from: selectedURL) {
            return decoded
        }

        throw ExportImportError.invalidSelection
    }

    private func buildBundleFromSplitFiles(containersURL: URL, itemsURL: URL) throws -> BoxIndexExportBundle {
        let containersData = try Data(contentsOf: containersURL)
        let itemsData = try Data(contentsOf: itemsURL)

        guard let containerRecords = try? decoder.decode([ContainerExportRecord].self, from: containersData),
              let itemRecords = try? decoder.decode([ContainerItemExportRecord].self, from: itemsData) else {
            throw ExportImportError.invalidBundle
        }

        return BoxIndexExportBundle(
            schemaVersion: BoxIndexSchemaVersion.current,
            exportedAt: .now,
            appName: "BoxIndex",
            containers: containerRecords,
            items: itemRecords
        )
    }

    private func decodeBundle(from url: URL) throws -> BoxIndexExportBundle {
        let data = try Data(contentsOf: url)

        guard let bundle = try? decoder.decode(BoxIndexExportBundle.self, from: data) else {
            throw ExportImportError.invalidBundle
        }

        return bundle
    }

    private func resolvedAttachmentsRoot(for selectedURL: URL) -> URL? {
        let root = isDirectory(selectedURL) ? selectedURL : selectedURL.deletingLastPathComponent()
        let attachmentsURL = root.appendingPathComponent("attachments", isDirectory: true)

        return FileManager.default.fileExists(atPath: attachmentsURL.path) ? attachmentsURL : nil
    }

    private func copyAttachmentIfNeeded(for container: Container, to attachmentsURL: URL) throws -> String? {
        guard let photoPath = container.photoPath,
              let sourceURL = PhotoStorageService.url(for: photoPath),
              FileManager.default.fileExists(atPath: sourceURL.path) else {
            return nil
        }

        let destinationFileName = "\(container.id.uuidString)-\(sourceURL.lastPathComponent)"
        let destinationURL = attachmentsURL.appendingPathComponent(destinationFileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return destinationFileName
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        try data.write(to: url, options: [.atomic])
    }

    private func writeCSV(_ value: String, to url: URL) throws {
        try value.write(to: url, atomically: true, encoding: .utf8)
    }

    private func makeContainerCSV(records: [ContainerExportRecord]) -> String {
        let rows = records.map { record in
            [
                record.id.uuidString,
                record.name,
                record.labelCode,
                record.location,
                record.subLocation ?? "",
                record.notes ?? "",
                record.colorTag ?? "",
                record.photoFileName ?? "",
                SearchService.joinedList(record.aliases),
                iso8601(record.createdAt),
                iso8601(record.updatedAt),
                record.isArchived ? "true" : "false",
            ]
        }

        return csv(
            headers: [
                "id",
                "name",
                "labelCode",
                "location",
                "subLocation",
                "notes",
                "colorTag",
                "photoFileName",
                "aliases",
                "createdAt",
                "updatedAt",
                "isArchived",
            ],
            rows: rows
        )
    }

    private func makeItemCSV(records: [ContainerItemExportRecord]) -> String {
        let rows = records.map { record in
            [
                record.id.uuidString,
                record.containerID.uuidString,
                record.name,
                record.quantity.map(String.init) ?? "",
                record.notes ?? "",
                SearchService.joinedList(record.tags),
                iso8601(record.createdAt),
                iso8601(record.updatedAt),
            ]
        }

        return csv(
            headers: [
                "id",
                "containerID",
                "name",
                "quantity",
                "notes",
                "tags",
                "createdAt",
                "updatedAt",
            ],
            rows: rows
        )
    }

    private func csv(headers: [String], rows: [[String]]) -> String {
        ([headers] + rows)
            .map { row in row.map(csvField).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private func csvField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}
