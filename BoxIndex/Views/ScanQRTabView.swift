//
//  ScanQRTabView.swift
//  BoxIndex
//
//  Created by Codex on 3/21/26.
//

import SwiftData
import SwiftUI

private enum ScanQRRoute: Hashable {
    case container(UUID)
}

struct ScanQRTabView: View {
    @Query(sort: [SortDescriptor(\Container.updatedAt, order: .reverse)]) private var containers: [Container]

    @State private var navigationPath: [ScanQRRoute] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScanQRView(
                containers: containers,
                showsCloseButton: false,
                onMatch: { container in
                    navigationPath.append(.container(container.id))
                }
            )
            .navigationDestination(for: ScanQRRoute.self) { route in
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
