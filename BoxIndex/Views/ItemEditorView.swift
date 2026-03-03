//
//  ItemEditorView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftData
import SwiftUI

struct ItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let container: Container
    let item: ContainerItem?

    @State private var name: String
    @State private var quantityText: String
    @State private var notes: String
    @State private var tagsText: String

    init(container: Container, item: ContainerItem? = nil) {
        self.container = container
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _quantityText = State(initialValue: item?.quantity.map(String.init) ?? "")
        _notes = State(initialValue: item?.notes ?? "")
        _tagsText = State(initialValue: SearchService.joinedList(item?.tags ?? []))
    }

    private var canSave: Bool {
        !name.trimmed.isEmpty
    }

    var body: some View {
        Form {
            Section("Item") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)

                TextField("Quantity", text: $quantityText)
                    .keyboardType(.numberPad)

                TextField("Tags", text: $tagsText)
                    .textInputAutocapitalization(.words)

                Text("Use simple tags like holiday, cables, or camping.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
        .navigationTitle(item == nil ? "New Item" : "Edit Item")
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
    }

    private func save() {
        let parsedQuantity = Int(quantityText.trimmed)
        let parsedTags = SearchService.parseCommaSeparated(tagsText)

        if let item {
            item.name = name.trimmed
            item.quantity = parsedQuantity
            item.notes = notes.nilIfBlank
            item.tags = parsedTags
            item.touch()
        } else {
            let newItem = ContainerItem(
                name: name.trimmed,
                quantity: parsedQuantity,
                notes: notes.nilIfBlank,
                tags: parsedTags,
                container: container
            )
            modelContext.insert(newItem)
        }

        container.touch()
        try? modelContext.save()
        dismiss()
    }
}
