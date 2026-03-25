//
//  QRLabelOutputView.swift
//  BoxIndex
//
//  Created by Codex on 3/22/26.
//

import SwiftUI
import UIKit

struct QRLabelOutputView: View {
    @Environment(\.dismiss) private var dismiss

    let availableContainers: [Container]
    let initialSelectionIDs: Set<UUID>
    let navigationTitle: String
    var initialOptions = QRLabelOutputOptions()

    private let outputService = QRLabelOutputService()

    @State private var options = QRLabelOutputOptions()
    @State private var selectedContainerIDs: Set<UUID> = []
    @State private var exportDirectoryURL: URL?
    @State private var isShowingExporter = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var didInitialize = false

    init(
        availableContainers: [Container],
        initialSelectionIDs: Set<UUID> = [],
        navigationTitle: String = "QR Output",
        initialOptions: QRLabelOutputOptions = QRLabelOutputOptions()
    ) {
        self.availableContainers = availableContainers
        self.initialSelectionIDs = initialSelectionIDs
        self.navigationTitle = navigationTitle
        self.initialOptions = initialOptions
    }

    private var sortedContainers: [Container] {
        availableContainers.sorted {
            if $0.labelCode.localizedCaseInsensitiveCompare($1.labelCode) == .orderedSame {
                return $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
            }

            return $0.labelCode.localizedCaseInsensitiveCompare($1.labelCode) == .orderedAscending
        }
    }

    private var resolvedInitialSelectionIDs: Set<UUID> {
        let availableIDs = Set(sortedContainers.map(\.id))
        let proposedSelection = initialSelectionIDs.intersection(availableIDs)
        return proposedSelection.isEmpty ? availableIDs : proposedSelection
    }

    private var selectedContainers: [Container] {
        sortedContainers.filter { selectedContainerIDs.contains($0.id) }
    }

    private var previewContainer: Container? {
        selectedContainers.first
    }

    private var pageCount: Int {
        outputService.pageCount(for: selectedContainers, options: options)
    }

    private var printingAvailable: Bool {
        UIPrintInteractionController.isPrintingAvailable
    }

    var body: some View {
        List {
            if sortedContainers.isEmpty {
                ContentUnavailableView(
                    "No Containers Available",
                    systemImage: "shippingbox",
                    description: Text("Add a container before preparing QR output.")
                )
            } else {
                Section("Scope") {
                    LabeledContent("Selected", value: "\(selectedContainers.count)")
                    LabeledContent(
                        "Grid",
                        value: "\(options.template.rows) × \(options.template.columns)"
                    )
                    LabeledContent(
                        "Estimated Pages",
                        value: "\(pageCount)"
                    )

                    if resolvedInitialSelectionIDs != Set(sortedContainers.map(\.id)) {
                        Text("The selection starts with the current container search results, and you can adjust it here before printing or exporting.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Layout") {
                    Picker("Rows", selection: $options.template.rows) {
                        ForEach(1...10, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }

                    Picker("Columns", selection: $options.template.columns) {
                        ForEach(1...10, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }

                    Picker("Export Paper Size", selection: $options.exportPaperSize) {
                        ForEach(QRLabelPageSize.allCases) { pageSize in
                            Text(pageSize.title).tag(pageSize)
                        }
                    }

                    Text("Printing uses the selected printer's paper size and printable area. Exported PDF sheets use the paper size chosen here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Label Content") {
                    Toggle("Include Name", isOn: $options.includeName)
                    Toggle("Include Label Code", isOn: $options.includeLabelCode)
                    Toggle("Use Color Accent", isOn: $options.useColorAccent)
                }

                Section("Export") {
                    Toggle("Include PDF Sheet", isOn: $options.exportsPDFSheet)
                    Toggle("Include Individual PNGs", isOn: $options.exportsIndividualPNGs)

                    Picker("Save As", selection: $options.packaging) {
                        ForEach(QRLabelExportPackaging.allCases) { packaging in
                            Text(packaging.title).tag(packaging)
                        }
                    }

                    LabeledContent("Image Format", value: options.individualAssetFormat.title)

                    Text("Exports can include a sheet PDF, individual PNG label images, and a manifest for future label-template workflows.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Containers") {
                    HStack {
                        Button("Select All") {
                            selectedContainerIDs = Set(sortedContainers.map(\.id))
                        }

                        Spacer()

                        Button("Clear") {
                            selectedContainerIDs.removeAll()
                        }
                    }
                    .buttonStyle(.borderless)

                    ForEach(sortedContainers, id: \.id) { container in
                        Button {
                            toggleSelection(for: container.id)
                        } label: {
                            SelectableContainerRow(
                                container: container,
                                isSelected: selectedContainerIDs.contains(container.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(container.displayTitle)
                        .accessibilityValue(
                            selectedContainerIDs.contains(container.id)
                                ? "Selected"
                                : "Not selected"
                        )
                    }
                }

                if let previewContainer {
                    Section("Preview") {
                        QRLabelPreviewCard(
                            container: previewContainer,
                            options: options,
                            outputService: outputService
                        )

                        if selectedContainers.count > 1 {
                            Text("Preview shows the first selected container in the current sort order.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Actions") {
                    Button {
                        printLabels()
                    } label: {
                        Label("Print Selected QR Codes", systemImage: "printer")
                    }
                    .disabled(!printingAvailable || selectedContainers.isEmpty)

                    Button {
                        exportLabels()
                    } label: {
                        Label("Export Selected QR Files", systemImage: "square.and.arrow.up")
                    }
                    .disabled(selectedContainers.isEmpty || !options.hasExportSelection)

                    if !options.hasExportSelection {
                        Text("Turn on PDF sheets, individual PNGs, or both before exporting.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let statusMessage {
                    Section("Latest Result") {
                        Text(statusMessage)
                            .font(.footnote)
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
        }
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
            guard !didInitialize else {
                return
            }

            options = initialOptions
            selectedContainerIDs = resolvedInitialSelectionIDs
            didInitialize = true
        }
    }

    private func toggleSelection(for containerID: UUID) {
        if selectedContainerIDs.contains(containerID) {
            selectedContainerIDs.remove(containerID)
        } else {
            selectedContainerIDs.insert(containerID)
        }
    }

    private func printLabels() {
        outputService.presentPrintSheet(for: selectedContainers, options: options) { result in
            switch result {
            case .success:
                statusMessage = "Opened the native print sheet for \(selectedContainers.count) selected container\(selectedContainers.count == 1 ? "" : "s")."
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportLabels() {
        do {
            let package = try outputService.buildExportPackage(from: selectedContainers, options: options)
            exportDirectoryURL = package.directoryURL
            statusMessage = "Prepared \(package.displayName). Choose a destination in Files to save the QR export."

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

private struct SelectableContainerRow: View {
    let container: Container
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ContainerRowView(container: container)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.45))
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
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
