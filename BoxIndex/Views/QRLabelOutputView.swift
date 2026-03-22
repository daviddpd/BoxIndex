//
//  QRLabelOutputView.swift
//  BoxIndex
//
//  Created by Codex on 3/22/26.
//

import SwiftUI
import UIKit

struct QRLabelOutputView: View {
    let containers: [Container]
    let navigationTitle: String
    var initialOptions = QRLabelOutputOptions()

    private let outputService = QRLabelOutputService()

    @State private var options = QRLabelOutputOptions()
    @State private var exportDirectoryURL: URL?
    @State private var isShowingExporter = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private var sortedContainers: [Container] {
        containers.sorted {
            if $0.labelCode.localizedCaseInsensitiveCompare($1.labelCode) == .orderedSame {
                return $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
            }

            return $0.labelCode.localizedCaseInsensitiveCompare($1.labelCode) == .orderedAscending
        }
    }

    private var previewContainer: Container? {
        sortedContainers.first
    }

    private var pageCount: Int {
        outputService.pageCount(for: sortedContainers, options: options)
    }

    private var printingAvailable: Bool {
        UIPrintInteractionController.isPrintingAvailable
    }

    var body: some View {
        List {
            Section("Scope") {
                Text("\(sortedContainers.count) container\(sortedContainers.count == 1 ? "" : "s")")
                Text("\(pageCount) page\(pageCount == 1 ? "" : "s") at \(options.template.grid.title) on \(options.template.pageSize.title)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Layout") {
                Picker("Paper Size", selection: $options.template.pageSize) {
                    ForEach(QRLabelPageSize.allCases) { pageSize in
                        Text(pageSize.title).tag(pageSize)
                    }
                }

                Picker("Grid", selection: $options.template.grid) {
                    ForEach(QRLabelGridPreset.allCases) { grid in
                        Text(grid.title).tag(grid)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Content") {
                Toggle("Include Name", isOn: $options.includeName)
                Toggle("Include Label Code", isOn: $options.includeLabelCode)
                Toggle("Use Color Accent", isOn: $options.useColorAccent)
            }

            Section("Export Format") {
                Picker("Package", selection: $options.packaging) {
                    ForEach(QRLabelExportPackaging.allCases) { packaging in
                        Text(packaging.title).tag(packaging)
                    }
                }

                LabeledContent("Individual Files", value: options.individualAssetFormat.title)
                LabeledContent("Sheet Output", value: "PDF")

                Text("This export includes individual PNG files, a full-sheet PDF in the selected grid, and a JSON manifest for future template workflows. SVG is not included in this pass.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let previewContainer {
                Section("Preview") {
                    QRLabelPreviewCard(
                        container: previewContainer,
                        options: options,
                        outputService: outputService
                    )

                    if sortedContainers.count > 1 {
                        Text("Preview uses the first container in the current sort order.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Actions") {
                Button {
                    printLabels()
                } label: {
                    Label("Print from iPhone", systemImage: "printer")
                }
                .disabled(!printingAvailable || sortedContainers.isEmpty)

                Button {
                    exportLabels()
                } label: {
                    Label("Export QR Files", systemImage: "square.and.arrow.up")
                }
                .disabled(sortedContainers.isEmpty)
            }

            if let statusMessage {
                Section("Latest Result") {
                    Text(statusMessage)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingExporter) {
            if let exportDirectoryURL {
                DocumentExportPicker(urls: [exportDirectoryURL]) {
                    isShowingExporter = false
                }
            }
        }
        .alert(
            "QR Output Error",
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
        .onAppear {
            options = initialOptions
        }
    }

    private func printLabels() {
        outputService.presentPrintSheet(for: sortedContainers, options: options) { result in
            switch result {
            case .success:
                statusMessage = "Opened the native print sheet for the current QR layout."
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportLabels() {
        do {
            let package = try outputService.buildExportPackage(from: sortedContainers, options: options)
            exportDirectoryURL = package.directoryURL
            statusMessage = "Prepared \(package.displayName). Choose a destination in Files to save the QR assets."

            if LaunchConfiguration.disableDocumentPickers {
                isShowingExporter = false
            } else {
                isShowingExporter = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct QRLabelPreviewCard: View {
    let container: Container
    let options: QRLabelOutputOptions
    let outputService: QRLabelOutputService

    var body: some View {
        Group {
            if let preview = try? outputService.preview(for: container, options: options) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(uiImage: preview.image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 320)

                    Text(preview.title)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ContentUnavailableView(
                    "Preview Unavailable",
                    systemImage: "qrcode",
                    description: Text("BoxIndex could not generate a QR preview for this configuration.")
                )
            }
        }
    }
}
