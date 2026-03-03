//
//  LaunchConfiguration.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation

enum LaunchConfiguration {
    private static let launchArguments = ProcessInfo.processInfo.arguments

    static var useInMemoryStore: Bool {
        launchArguments.contains("UITEST_USE_IN_MEMORY_STORE")
    }

    static var seedDemoData: Bool {
        launchArguments.contains("UITEST_SEED_DEMO_DATA")
    }

    static var disableDocumentPickers: Bool {
        launchArguments.contains("UITEST_DISABLE_DOCUMENT_PICKERS")
    }
}
