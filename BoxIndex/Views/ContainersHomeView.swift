//
//  ContainersHomeView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftData
import SwiftUI

private enum HomeRoute: Hashable {
    case container(UUID)
}

struct ContainersHomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var searchText: String
    @State private var containers: [Container] = []
    @State private var navigationPath: [HomeRoute] = []
    @State private var isShowingAddContainer = false
    @State private var isShowingQROutput = false

    private var filteredContainers: [Container] {
        SearchService.search(query: searchText, in: containers)
    }

    private var qrOutputSelectionIDs: Set<UUID> {
        let preferredContainers = filteredContainers.isEmpty ? containers : filteredContainers
        return Set(preferredContainers.map(\.id))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if containers.isEmpty && searchText.trimmed.isEmpty {
                    ContentUnavailableView {
                        Label("No Containers Yet", systemImage: "shippingbox")
                    } description: {
                        Text("Add a box, bin, tote, or shelf so you can quickly find it later.")
                    } actions: {
                        Button("Add Your First Container") {
                            isShowingAddContainer = true
                        }
                    }
                } else if filteredContainers.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredContainers, id: \.id) { container in
                            NavigationLink(value: HomeRoute.container(container.id)) {
                                ContainerRowView(container: container)
                            }
                            .accessibilityLabel("\(container.displayTitle), \(container.labelCode)")
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("BoxIndex")
            .searchable(text: $searchText, prompt: "Search boxes, labels, items")
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .container(let containerID):
                    if let container = containers.first(where: { $0.id == containerID }) {
                        ContainerDetailView(container: container)
                    } else {
                        ContentUnavailableView(
                            "Container Not Found",
                            systemImage: "shippingbox.badge.xmark",
                            description: Text("This container may have been deleted or archived elsewhere.")
                        )
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingQROutput = true
                    } label: {
                        Label("QR Output", systemImage: "printer")
                    }
                    .disabled(containers.isEmpty)
                    .accessibilityIdentifier("home.qrOutput")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddContainer = true
                    } label: {
                        Label("Add Container", systemImage: "plus")
                    }
                    .accessibilityIdentifier("home.addContainer")
                }
            }
            .sheet(isPresented: $isShowingAddContainer) {
                NavigationStack {
                    ContainerEditorView()
                }
            }
            .sheet(isPresented: $isShowingQROutput) {
                NavigationStack {
                    QRLabelOutputView(
                        availableContainers: containers,
                        initialSelectionIDs: qrOutputSelectionIDs,
                        navigationTitle: "QR Output"
                    )
                }
            }
            .task {
                reloadContainers()
            }
            .onChange(of: isShowingAddContainer) { _, isShowing in
                if !isShowing {
                    reloadContainers()
                }
            }
        }
    }

    private func reloadContainers() {
        let descriptor = FetchDescriptor<Container>(
            sortBy: [SortDescriptor(\Container.updatedAt, order: .reverse)]
        )
        containers = (try? modelContext.fetch(descriptor)) ?? []
    }
}
