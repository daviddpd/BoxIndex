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
    var rows = 2
    var columns = 2

    var itemsPerPage: Int {
        rows * columns
    }
}

struct QRLabelOutputOptions: Codable, Hashable {
    var template = QRLabelTemplateDescriptor()
    var includeName = true
    var includeLabelCode = true
    var useColorAccent = true
    var packaging: QRLabelExportPackaging = .folder
    var individualAssetFormat: QRLabelIndividualAssetFormat = .png
    var exportPaperSize: QRLabelPageSize = .letter
    var exportsPDFSheet = true
    var exportsIndividualPNGs = true

    var hasExportSelection: Bool {
        exportsPDFSheet || exportsIndividualPNGs
    }
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
    let exportPaperSize: QRLabelPageSize
    let includeName: Bool
    let includeLabelCode: Bool
    let useColorAccent: Bool
    let packaging: QRLabelExportPackaging
    let exportsPDFSheet: Bool
    let exportsIndividualPNGs: Bool
    let individualAssetFormat: QRLabelIndividualAssetFormat
    let sheetFileName: String?
    let individualFiles: [QRLabelExportFileRecord]
}

struct QRLabelExportFileRecord: Codable, Identifiable {
    let id: UUID
    let name: String
    let labelCode: String
    let fileName: String
}

extension QRLabelLayoutSpec {
    static func make(
        pageRect: CGRect,
        template: QRLabelTemplateDescriptor,
        contentRect: CGRect? = nil
    ) -> QRLabelLayoutSpec {
        let layoutRect = contentRect ?? pageRect.insetBy(
            dx: max(12, min(pageRect.width, pageRect.height) * 0.03),
            dy: max(12, min(pageRect.width, pageRect.height) * 0.03)
        )

        let contentInset = max(8, min(layoutRect.width, layoutRect.height) * 0.02)
        let usableRect = layoutRect.insetBy(dx: contentInset, dy: contentInset)
        let itemSpacing = max(4, min(usableRect.width, usableRect.height) * 0.015)
        let availableWidth = usableRect.width - (CGFloat(template.columns - 1) * itemSpacing)
        let availableHeight = usableRect.height - (CGFloat(template.rows - 1) * itemSpacing)
        let labelWidth = availableWidth / CGFloat(template.columns)
        let labelHeight = availableHeight / CGFloat(template.rows)
        let cornerRadius = max(10, min(28, min(labelWidth, labelHeight) * 0.08))

        var frames: [CGRect] = []
        for row in 0..<template.rows {
            for column in 0..<template.columns {
                let originX = usableRect.minX + CGFloat(column) * (labelWidth + itemSpacing)
                let originY = usableRect.minY + CGFloat(row) * (labelHeight + itemSpacing)
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
