//
//  BackupView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext

    private let exportService = ExportImportService()

    @State private var containers: [Container] = []
    @State private var settings: AppSettings?
    @State private var exportDirectoryURL: URL?
    @State private var isShowingExporter = false
    @State private var isShowingImporter = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Export & Import") {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export BoxIndex Data", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("backup.export")
                    .disabled(containers.isEmpty)

                    Button {
                        isShowingImporter = true
                    } label: {
                        Label("Import Prior Export", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityIdentifier("backup.import")

                    Text("Exports are local, versioned, and open. BoxIndex writes `containers.json`, `items.json`, CSV copies, and an optional `attachments` folder into a shareable export bundle. On import conflicts, BoxIndex compares `updatedAt` and keeps the newer record.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let statusMessage {
                    Section("Latest Result") {
                        Text(statusMessage)
                            .font(.footnote)
                    }
                }

                Section("Preferences") {
                    if let settings {
                        BackupPreferencesSection(settings: settings) {
                            persistSettings()
                        }
                    } else {
                        Text("Preparing local settings…")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Local-First") {
                    Text("All data stays on-device. Export and import are the current backup path, and BoxIndex does not require an account or cloud service.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Backup")
            .sheet(isPresented: $isShowingExporter) {
                if let exportDirectoryURL {
                    DocumentExportPicker(urls: [exportDirectoryURL]) {
                        isShowingExporter = false
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingImporter,
                allowedContentTypes: [.folder, .json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert(
                "Backup Error",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                reloadData()
            }
        }
    }

    private func prepareExport() {
        do {
            let package = try exportService.buildExportPackage(from: containers)
            exportDirectoryURL = package.directoryURL
            statusMessage = "Prepared \(package.displayName). Choose a destination in Files to save the export."

            if LaunchConfiguration.disableDocumentPickers {
                isShowingExporter = false
            } else {
                isShowingExporter = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleImport(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                return
            }
            do {
                let summary = try exportService.importArchive(from: url, into: modelContext)
                statusMessage = summary.statusMessage
                reloadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func reloadData() {
        let containerDescriptor = FetchDescriptor<Container>(
            sortBy: [SortDescriptor(\Container.name, order: .forward)]
        )
        containers = (try? modelContext.fetch(containerDescriptor)) ?? []

        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let fetchedSettings = (try? modelContext.fetch(settingsDescriptor)) ?? []
        if let existingSettings = fetchedSettings.first {
            settings = existingSettings
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            settings = newSettings
        }
    }

    private func persistSettings() {
        settings?.updatedAt = .now
        try? modelContext.save()
    }
}

private struct BackupPreferencesSection: View {
    let settings: AppSettings
    let saveChanges: () -> Void

    var body: some View {
        TextField(
            "Default Location",
            text: Binding(
                get: { settings.defaultLocation },
                set: { newValue in
                    settings.defaultLocation = newValue
                    saveChanges()
                }
            )
        )
            .textInputAutocapitalization(.words)

        Picker("Preferred Export", selection: Binding(
            get: { settings.preferredExportFormat },
            set: { newValue in
                settings.preferredExportFormat = newValue
                saveChanges()
            }
        )) {
            ForEach(ExportFormatPreference.allCases) { format in
                Text(format.title).tag(format)
            }
        }
    }
}
