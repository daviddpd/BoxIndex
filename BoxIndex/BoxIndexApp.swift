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
    private let sharedModelContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: Container.self,
                ContainerItem.self,
                AppSettings.self,
                configurations: configuration
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
