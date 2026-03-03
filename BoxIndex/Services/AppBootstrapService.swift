//
//  AppBootstrapService.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation
import SwiftData

@MainActor
enum AppBootstrapService {
    static func prepareIfNeeded(in modelContainer: ModelContainer) {
        guard LaunchConfiguration.seedDemoData else {
            return
        }

        let context = ModelContext(modelContainer)

        let existingContainers = (try? context.fetch(FetchDescriptor<Container>())) ?? []
        guard existingContainers.isEmpty else {
            ensureSettings(in: context)
            return
        }

        ensureSettings(in: context)

        let holidayDecor = Container(
            name: "Holiday Decor",
            labelCode: "HD-001",
            location: "Garage",
            subLocation: "Top Shelf",
            notes: "Lights, garlands, and extension cords.",
            colorTag: ContainerColorTag.amber.rawValue,
            aliases: ["Holiday Bin", "Decor Tote"]
        )

        let campingGear = Container(
            name: "Camping Gear",
            labelCode: "CG-002",
            location: "Basement",
            subLocation: "Rack B",
            notes: "Tent, stove, and cook kit.",
            colorTag: ContainerColorTag.green.rawValue,
            aliases: ["Camp Box"]
        )

        context.insert(holidayDecor)
        context.insert(campingGear)

        context.insert(
            ContainerItem(
                name: "String Lights",
                quantity: 4,
                notes: "Outdoor-rated",
                tags: ["holiday", "lights"],
                container: holidayDecor
            )
        )
        context.insert(
            ContainerItem(
                name: "Tree Hooks",
                quantity: 2,
                tags: ["holiday"],
                container: holidayDecor
            )
        )
        context.insert(
            ContainerItem(
                name: "Tent Stakes",
                quantity: 12,
                tags: ["camping"],
                container: campingGear
            )
        )

        try? context.save()
    }

    private static func ensureSettings(in context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        let settings = (try? context.fetch(descriptor)) ?? []

        guard settings.isEmpty else {
            return
        }

        context.insert(
            AppSettings(
                defaultLocation: "Garage",
                preferredExportFormat: .folderBundle
            )
        )
        try? context.save()
    }
}
