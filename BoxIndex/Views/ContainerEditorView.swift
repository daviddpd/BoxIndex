//
//  ContainerEditorView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import PhotosUI
import SwiftData
import SwiftUI

struct ContainerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let container: Container?

    @State private var name: String
    @State private var labelCode: String
    @State private var location: String
    @State private var subLocation: String
    @State private var notes: String
    @State private var colorTag: String
    @State private var aliasesText: String
    @State private var isArchived: Bool
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var photoDidChange = false
    @State private var errorMessage: String?
    @State private var appliedDefaultLocation = false

    init(container: Container? = nil) {
        self.container = container
        _name = State(initialValue: container?.name ?? "")
        _labelCode = State(initialValue: container?.labelCode ?? "")
        _location = State(initialValue: container?.location ?? "")
        _subLocation = State(initialValue: container?.subLocation ?? "")
        _notes = State(initialValue: container?.notes ?? "")
        _colorTag = State(initialValue: container?.colorTag ?? "")
        _aliasesText = State(initialValue: SearchService.joinedList(container?.aliases ?? []))
        _isArchived = State(initialValue: container?.isArchived ?? false)
        _photoImage = State(initialValue: container.flatMap { PhotoStorageService.image(for: $0.photoPath) })
    }

    private var canSave: Bool {
        !name.trimmed.isEmpty && !labelCode.trimmed.isEmpty && !location.trimmed.isEmpty
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Container Name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Label Code", text: $labelCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                TextField("Location", text: $location)
                    .textInputAutocapitalization(.words)
                TextField("Sub-location", text: $subLocation)
                    .textInputAutocapitalization(.words)
            }

            Section("Organization") {
                Picker("Color Tag", selection: $colorTag) {
                    Text("None").tag("")
                    ForEach(ContainerColorTag.allCases) { tag in
                        Text(tag.title).tag(tag.rawValue)
                    }
                }

                Toggle("Archived", isOn: $isArchived)
            }

            Section("Aliases") {
                TextField("Bin 4, Garage 4", text: $aliasesText, axis: .vertical)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.words)

                Text("Separate alternate names with commas.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Notes") {
                TextField("Anything useful to remember", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Photo") {
                if let photoImage {
                    Image(uiImage: photoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Label("No photo selected", systemImage: "photo")
                        .foregroundStyle(.secondary)
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(photoImage == nil ? "Choose Photo" : "Replace Photo", systemImage: "photo.on.rectangle")
                }

                if photoImage != nil {
                    Button(role: .destructive) {
                        photoImage = nil
                        photoDidChange = true
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(container == nil ? "New Container" : "Edit Container")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
        .onAppear {
            applyDefaultLocationIfNeeded()
        }
        .alert(
            "Unable to Save",
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
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem else {
            return
        }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                photoImage = image
                photoDidChange = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            let photoPath = try persistedPhotoPath()

            if let container {
                container.name = name.trimmed
                container.labelCode = labelCode.trimmed.uppercased()
                container.location = location.trimmed
                container.subLocation = subLocation.nilIfBlank
                container.notes = notes.nilIfBlank
                container.colorTag = colorTag.nilIfBlank
                container.aliases = SearchService.parseCommaSeparated(aliasesText)
                container.isArchived = isArchived
                container.photoPath = photoPath
                container.touch()
            } else {
                let newContainer = Container(
                    name: name.trimmed,
                    labelCode: labelCode.trimmed.uppercased(),
                    location: location.trimmed,
                    subLocation: subLocation.nilIfBlank,
                    notes: notes.nilIfBlank,
                    colorTag: colorTag.nilIfBlank,
                    photoPath: photoPath,
                    aliases: SearchService.parseCommaSeparated(aliasesText),
                    isArchived: isArchived
                )
                modelContext.insert(newContainer)
            }

            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistedPhotoPath() throws -> String? {
        let existingPath = container?.photoPath

        guard photoDidChange else {
            return existingPath
        }

        guard let photoImage else {
            PhotoStorageService.deletePhoto(at: existingPath)
            return nil
        }

        return try PhotoStorageService.saveJPEGImage(photoImage, replacing: existingPath)
    }

    private func applyDefaultLocationIfNeeded() {
        guard container == nil, !appliedDefaultLocation, location.trimmed.isEmpty else {
            return
        }

        let descriptor = FetchDescriptor<AppSettings>()
        let fetchedSettings = (try? modelContext.fetch(descriptor)) ?? []
        if let defaultLocation = fetchedSettings.first?.defaultLocation.nilIfBlank {
            location = defaultLocation
        }

        appliedDefaultLocation = true
    }
}
