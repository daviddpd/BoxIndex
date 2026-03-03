//
//  BoxIndexApp.swift
//  BoxIndex
//
//  Created by David P. Discher on 3/2/26.
//

import SwiftData
import SwiftUI

@main
struct BoxIndexApp: App {
    private let sharedModelContainer: ModelContainer

    init() {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: LaunchConfiguration.useInMemoryStore)

        do {
            sharedModelContainer = try ModelContainer(
                for: Container.self,
                ContainerItem.self,
                AppSettings.self,
                migrationPlan: BoxIndexMigrationPlan.self,
                configurations: configuration
            )
            AppBootstrapService.prepareIfNeeded(in: sharedModelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
