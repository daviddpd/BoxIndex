//
//  ContainerColorTag.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftUI
import UIKit

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
        Color(uiColor: uiColor)
    }

    var uiColor: UIColor {
        switch self {
        case .slate:
            return UIColor(red: 0.36, green: 0.42, blue: 0.50, alpha: 1)
        case .blue:
            return UIColor(red: 0.16, green: 0.48, blue: 0.82, alpha: 1)
        case .green:
            return UIColor(red: 0.18, green: 0.58, blue: 0.39, alpha: 1)
        case .amber:
            return UIColor(red: 0.88, green: 0.56, blue: 0.12, alpha: 1)
        case .coral:
            return UIColor(red: 0.82, green: 0.34, blue: 0.29, alpha: 1)
        }
    }

    static func color(for rawValue: String?) -> Color? {
        guard let rawValue else {
            return nil
        }

        return ContainerColorTag(rawValue: rawValue)?.color
    }

    static func uiColor(for rawValue: String?) -> UIColor? {
        guard let rawValue else {
            return nil
        }

        return ContainerColorTag(rawValue: rawValue)?.uiColor
    }

    static func title(for rawValue: String?) -> String? {
        guard let rawValue else {
            return nil
        }

        return ContainerColorTag(rawValue: rawValue)?.title
    }
}
