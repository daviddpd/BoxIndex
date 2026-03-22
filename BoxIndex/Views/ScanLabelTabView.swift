//
//  ScanLabelTabView.swift
//  BoxIndex
//
//  Created by Codex on 3/21/26.
//

import SwiftData
import SwiftUI

private enum ScanLabelRoute: Hashable {
    case container(UUID)
}

struct ScanLabelTabView: View {
    @Query(sort: [SortDescriptor(\Container.updatedAt, order: .reverse)]) private var containers: [Container]

    let onUseSearch: (String) -> Void

    @State private var navigationPath: [ScanLabelRoute] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScanLabelView(
                containers: containers,
                showsCloseButton: false,
                openContainer: { container in
                    navigationPath.append(.container(container.id))
                },
                prefillSearch: onUseSearch
            )
            .navigationDestination(for: ScanLabelRoute.self) { route in
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
        }
    }
}
