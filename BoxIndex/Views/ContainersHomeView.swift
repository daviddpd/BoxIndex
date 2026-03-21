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

    @State private var containers: [Container] = []
    @State private var navigationPath: [HomeRoute] = []
    @State private var searchText = ""
    @State private var isShowingAddContainer = false
    @State private var isShowingQRScanner = false
    @State private var isShowingLabelScanner = false

    private var filteredContainers: [Container] {
        SearchService.search(query: searchText, in: containers)
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
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
            .toolbar {
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
            .sheet(isPresented: $isShowingQRScanner) {
                NavigationStack {
                    ScanQRView(containers: containers) { container in
                        open(container)
                    }
                }
            }
            .sheet(isPresented: $isShowingLabelScanner) {
                NavigationStack {
                    ScanLabelView(
                        containers: containers,
                        openContainer: { container in
                            open(container)
                        },
                        prefillSearch: { recognizedText in
                            searchText = recognizedText
                            isShowingLabelScanner = false
                        }
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

    private func open(_ container: Container) {
        isShowingQRScanner = false
        isShowingLabelScanner = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            navigationPath.append(.container(container.id))
        }
    }

    private func reloadContainers() {
        let descriptor = FetchDescriptor<Container>(
            sortBy: [SortDescriptor(\Container.updatedAt, order: .reverse)]
        )
        containers = (try? modelContext.fetch(descriptor)) ?? []
    }

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button {
                isShowingQRScanner = true
            } label: {
                Label("Scan QR", systemImage: "qrcode.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("home.scanQR")

            Button {
                isShowingLabelScanner = true
            } label: {
                Label("Scan Label", systemImage: "text.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("home.scanLabel")
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }
}
