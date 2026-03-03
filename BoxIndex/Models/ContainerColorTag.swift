//
//  ContainerColorTag.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftUI

enum ContainerColorTag: String, CaseIterable, Identifiable {
    case slate
    case blue
    case green
    case amber
    case coral

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slate:
            return "Slate"
        case .blue:
            return "Blue"
        case .green:
            return "Green"
        case .amber:
            return "Amber"
        case .coral:
            return "Coral"
        }
    }

    var color: Color {
        switch self {
        case .slate:
            return Color(red: 0.36, green: 0.42, blue: 0.50)
        case .blue:
            return Color(red: 0.16, green: 0.48, blue: 0.82)
        case .green:
            return Color(red: 0.18, green: 0.58, blue: 0.39)
        case .amber:
            return Color(red: 0.88, green: 0.56, blue: 0.12)
        case .coral:
            return Color(red: 0.82, green: 0.34, blue: 0.29)
        }
    }

    static func color(for rawValue: String?) -> Color? {
        guard let rawValue else {
            return nil
        }

        return ContainerColorTag(rawValue: rawValue)?.color
    }

    static func title(for rawValue: String?) -> String? {
        guard let rawValue else {
            return nil
        }

        return ContainerColorTag(rawValue: rawValue)?.title
    }
}
