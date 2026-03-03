//
//  ContainerDetailView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftData
import SwiftUI

struct ContainerDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let container: Container

    @State private var isShowingEditContainer = false
    @State private var isShowingAddItem = false
    @State private var itemBeingEdited: ContainerItem?

    private var sortedItems: [ContainerItem] {
        container.items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        List {
            Section("Container") {
                LabeledContent("Name", value: container.displayTitle)
                LabeledContent("Label", value: container.labelCode)
                LabeledContent("Location", value: container.locationDisplay)

                if let colorTitle = ContainerColorTag.title(for: container.colorTag) {
                    LabeledContent("Color Tag", value: colorTitle)
                }

                if let aliasSummary = container.aliasSummary {
                    LabeledContent("Aliases", value: aliasSummary)
                }

                if container.isArchived {
                    Label("Archived", systemImage: "archivebox")
                        .foregroundStyle(.secondary)
                }
            }

            if let notes = container.notes?.trimmed, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            if let image = PhotoStorageService.image(for: container.photoPath) {
                Section("Photo") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
            }

            Section {
                if sortedItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("No contents added yet", systemImage: "list.bullet.rectangle")
                            .font(.headline)
                        Text("Keep item entry lightweight. Add the essentials so this container stays quick to update.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                } else {
                    ForEach(sortedItems, id: \.id) { item in
                        Button {
                            itemBeingEdited = item
                        } label: {
                            ContainerItemRowView(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteItems)
                }
            } header: {
                HStack {
                    Text("Contents")
                    Spacer()
                    Text("\(sortedItems.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Tap an item to edit it. Swipe to delete.")
            }

            Section("QR Code") {
                QRCodePreviewView(container: container)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }
        }
        .navigationTitle(container.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isShowingEditContainer = true
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingEditContainer) {
            NavigationStack {
                ContainerEditorView(container: container)
            }
        }
        .sheet(isPresented: $isShowingAddItem) {
            NavigationStack {
                ItemEditorView(container: container)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { itemBeingEdited != nil },
                set: { isPresented in
                    if !isPresented {
                        itemBeingEdited = nil
                    }
                }
            )
        ) {
            if let itemBeingEdited {
                NavigationStack {
                    ItemEditorView(container: container, item: itemBeingEdited)
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = sortedItems[index]
            modelContext.delete(item)
        }

        container.touch()
        try? modelContext.save()
    }
}
