//
//  QRLabelOutputModels.swift
//  BoxIndex
//
//  Created by Codex on 3/22/26.
//

import CoreGraphics
import Foundation

enum QRLabelTemplateKind: String, CaseIterable, Codable, Identifiable {
    case flexibleGrid

    var id: String { rawValue }
}

enum QRLabelPageSize: String, CaseIterable, Codable, Identifiable {
    case letter
    case legal
    case a4

    var id: String { rawValue }

    var title: String {
        switch self {
        case .letter:
            return "Letter"
        case .legal:
            return "Legal"
        case .a4:
            return "A4"
        }
    }

    var pageRect: CGRect {
        switch self {
        case .letter:
            return CGRect(x: 0, y: 0, width: 612, height: 792)
        case .legal:
            return CGRect(x: 0, y: 0, width: 612, height: 1008)
        case .a4:
            return CGRect(x: 0, y: 0, width: 595, height: 842)
        }
    }
}

enum QRLabelGridPreset: String, CaseIterable, Codable, Identifiable {
    case oneByOne
    case twoByTwo
    case threeBySix

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneByOne:
            return "1×1"
        case .twoByTwo:
            return "2×2"
        case .threeBySix:
            return "3×6"
        }
    }

    var columns: Int {
        switch self {
        case .oneByOne:
            return 1
        case .twoByTwo:
            return 2
        case .threeBySix:
            return 3
        }
    }

    var rows: Int {
        switch self {
        case .oneByOne:
            return 1
        case .twoByTwo:
            return 2
        case .threeBySix:
            return 6
        }
    }

    var itemsPerPage: Int {
        columns * rows
    }
}

enum QRLabelExportPackaging: String, CaseIterable, Codable, Identifiable {
    case folder
    case bundle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .folder:
            return "Folder"
        case .bundle:
            return "Bundle"
        }
    }

    var fileExtension: String? {
        switch self {
        case .folder:
            return nil
        case .bundle:
            return "boxindexlabels"
        }
    }
}

enum QRLabelIndividualAssetFormat: String, CaseIterable, Codable, Identifiable {
    case png

    var id: String { rawValue }

    var title: String {
        switch self {
        case .png:
            return "PNG"
        }
    }

    var fileExtension: String {
        rawValue
    }
}

struct QRLabelTemplateDescriptor: Codable, Hashable {
    var kind: QRLabelTemplateKind = .flexibleGrid
    var pageSize: QRLabelPageSize = .letter
    var grid: QRLabelGridPreset = .twoByTwo
}

struct QRLabelOutputOptions: Codable, Hashable {
    var template = QRLabelTemplateDescriptor()
    var includeName = true
    var includeLabelCode = true
    var useColorAccent = true
    var packaging: QRLabelExportPackaging = .folder
    var individualAssetFormat: QRLabelIndividualAssetFormat = .png
}

struct QRLabelLayoutSpec {
    let pageRect: CGRect
    let labelFrames: [CGRect]
    let contentInset: CGFloat
    let itemSpacing: CGFloat
    let cornerRadius: CGFloat
}

struct QRLabelExportManifest: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let appName: String
    let template: QRLabelTemplateDescriptor
    let includeName: Bool
    let includeLabelCode: Bool
    let useColorAccent: Bool
    let packaging: QRLabelExportPackaging
    let individualAssetFormat: QRLabelIndividualAssetFormat
    let sheetFileName: String
    let individualFiles: [QRLabelExportFileRecord]
}

struct QRLabelExportFileRecord: Codable, Identifiable {
    let id: UUID
    let name: String
    let labelCode: String
    let fileName: String
}

extension QRLabelLayoutSpec {
    static func make(for template: QRLabelTemplateDescriptor) -> QRLabelLayoutSpec {
        let pageRect = template.pageSize.pageRect

        let contentInset: CGFloat
        let itemSpacing: CGFloat
        let cornerRadius: CGFloat

        switch template.grid {
        case .oneByOne:
            contentInset = 48
            itemSpacing = 0
            cornerRadius = 28
        case .twoByTwo:
            contentInset = 28
            itemSpacing = 18
            cornerRadius = 22
        case .threeBySix:
            contentInset = 16
            itemSpacing = 9
            cornerRadius = 14
        }

        let availableWidth = pageRect.width - (contentInset * 2) - (CGFloat(template.grid.columns - 1) * itemSpacing)
        let availableHeight = pageRect.height - (contentInset * 2) - (CGFloat(template.grid.rows - 1) * itemSpacing)
        let labelWidth = availableWidth / CGFloat(template.grid.columns)
        let labelHeight = availableHeight / CGFloat(template.grid.rows)

        var frames: [CGRect] = []
        for row in 0..<template.grid.rows {
            for column in 0..<template.grid.columns {
                let originX = contentInset + CGFloat(column) * (labelWidth + itemSpacing)
                let originY = contentInset + CGFloat(row) * (labelHeight + itemSpacing)
                frames.append(CGRect(x: originX, y: originY, width: labelWidth, height: labelHeight))
            }
        }

        return QRLabelLayoutSpec(
            pageRect: pageRect,
            labelFrames: frames,
            contentInset: contentInset,
            itemSpacing: itemSpacing,
            cornerRadius: cornerRadius
        )
    }
}
