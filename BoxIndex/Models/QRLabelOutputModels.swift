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

enum QRLabelTextPosition: String, CaseIterable, Codable, Identifiable {
    case top
    case bottom
    case left
    case right

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

enum QRLabelSheetRotation: String, CaseIterable, Codable, Identifiable {
    case none
    case clockwise90
    case counterclockwise90

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return "None"
        case .clockwise90:
            return "+90°"
        case .counterclockwise90:
            return "-90°"
        }
    }

    var radians: CGFloat {
        switch self {
        case .none:
            return 0
        case .clockwise90:
            return .pi / 2
        case .counterclockwise90:
            return -.pi / 2
        }
    }

    var swapsDimensions: Bool {
        self != .none
    }
}

enum QRLabelLengthUnit: String, Codable, Identifiable {
    case inches
    case centimeters

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .inches:
            return "in"
        case .centimeters:
            return "cm"
        }
    }

    static var preferred: QRLabelLengthUnit {
        let measurementSystem = String(describing: Locale.current.measurementSystem).lowercased()
        return measurementSystem.contains("metric") ? .centimeters : .inches
    }

    func displayValue(fromInches inches: Double) -> Double {
        switch self {
        case .inches:
            return inches
        case .centimeters:
            return Measurement(value: inches, unit: UnitLength.inches)
                .converted(to: .centimeters)
                .value
        }
    }

    func inchesValue(fromDisplayValue value: Double) -> Double {
        switch self {
        case .inches:
            return value
        case .centimeters:
            return Measurement(value: value, unit: UnitLength.centimeters)
                .converted(to: .inches)
                .value
        }
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
    var aspectWidthUnits = 1
    var aspectHeightUnits = 1
    var textPosition: QRLabelTextPosition = .bottom
    var textScale = 1.0
    var usesExplicitLabelSize = false
    var explicitLabelWidthInches = 3.0
    var explicitLabelHeightInches = 5.0
    var sheetRotation: QRLabelSheetRotation = .none

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
    let aspectWidthUnits: Int
    let aspectHeightUnits: Int
    let textPosition: QRLabelTextPosition
    let textScale: Double
    let usesExplicitLabelSize: Bool
    let explicitLabelWidthInches: Double?
    let explicitLabelHeightInches: Double?
    let sheetRotation: QRLabelSheetRotation
    let packaging: QRLabelExportPackaging
    let exportsPDFSheet: Bool
    let exportsIndividualPNGs: Bool
    let individualAssetFormat: QRLabelIndividualAssetFormat
    let sheetFileName: String?
    let individualFiles: [QRLabelExportFileRecord]
}

extension QRLabelOutputOptions {
    var clampedAspectWidthUnits: Int {
        max(1, min(100, aspectWidthUnits))
    }

    var clampedAspectHeightUnits: Int {
        max(1, min(100, aspectHeightUnits))
    }

    var clampedLabelAspectRatio: CGFloat {
        CGFloat(clampedAspectWidthUnits) / CGFloat(clampedAspectHeightUnits)
    }

    var clampedTextScale: CGFloat {
        CGFloat(max(0.65, min(1.8, textScale)))
    }

    var aspectRatioSummary: String {
        "\(clampedAspectWidthUnits):\(clampedAspectHeightUnits) • \(String(format: "%.2f", clampedLabelAspectRatio)):1"
    }

    var textScaleSummary: String {
        String(format: "%.0f%%", textScale * 100)
    }

    var explicitLabelWidthInchesClamped: Double {
        max(0.25, min(20, explicitLabelWidthInches))
    }

    var explicitLabelHeightInchesClamped: Double {
        max(0.25, min(20, explicitLabelHeightInches))
    }

    var explicitLabelSizeInches: CGSize {
        CGSize(width: explicitLabelWidthInchesClamped, height: explicitLabelHeightInchesClamped)
    }

    func explicitLabelSizeSummary(in unit: QRLabelLengthUnit = .preferred) -> String {
        let width = unit.displayValue(fromInches: explicitLabelWidthInchesClamped)
        let height = unit.displayValue(fromInches: explicitLabelHeightInchesClamped)
        return String(format: "%.2f %@ × %.2f %@", width, unit.shortTitle, height, unit.shortTitle)
    }
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
        contentRect: CGRect? = nil,
        preferredLabelSize: CGSize? = nil
    ) -> QRLabelLayoutSpec {
        let layoutRect = contentRect ?? pageRect.insetBy(
            dx: max(12, min(pageRect.width, pageRect.height) * 0.03),
            dy: max(12, min(pageRect.width, pageRect.height) * 0.03)
        )

        let contentInset = max(8, min(layoutRect.width, layoutRect.height) * 0.02)
        let usableRect = layoutRect.insetBy(dx: contentInset, dy: contentInset)
        let itemSpacing = max(4, min(usableRect.width, usableRect.height) * 0.015)
        var frames: [CGRect] = []
        let finalItemSpacing: CGFloat
        let labelWidth: CGFloat
        let labelHeight: CGFloat

        if let preferredLabelSize {
            let desiredGridWidth = (preferredLabelSize.width * CGFloat(template.columns))
                + (itemSpacing * CGFloat(max(0, template.columns - 1)))
            let desiredGridHeight = (preferredLabelSize.height * CGFloat(template.rows))
                + (itemSpacing * CGFloat(max(0, template.rows - 1)))
            let scale = min(
                1,
                usableRect.width / max(1, desiredGridWidth),
                usableRect.height / max(1, desiredGridHeight)
            )
            labelWidth = preferredLabelSize.width * scale
            labelHeight = preferredLabelSize.height * scale
            finalItemSpacing = itemSpacing * scale

            let gridWidth = (labelWidth * CGFloat(template.columns))
                + (finalItemSpacing * CGFloat(max(0, template.columns - 1)))
            let gridHeight = (labelHeight * CGFloat(template.rows))
                + (finalItemSpacing * CGFloat(max(0, template.rows - 1)))
            let originX = usableRect.midX - (gridWidth / 2)
            let originY = usableRect.midY - (gridHeight / 2)

            for row in 0..<template.rows {
                for column in 0..<template.columns {
                    let x = originX + CGFloat(column) * (labelWidth + finalItemSpacing)
                    let y = originY + CGFloat(row) * (labelHeight + finalItemSpacing)
                    frames.append(CGRect(x: x, y: y, width: labelWidth, height: labelHeight))
                }
            }
        } else {
            let availableWidth = usableRect.width - (CGFloat(template.columns - 1) * itemSpacing)
            let availableHeight = usableRect.height - (CGFloat(template.rows - 1) * itemSpacing)
            labelWidth = availableWidth / CGFloat(template.columns)
            labelHeight = availableHeight / CGFloat(template.rows)
            finalItemSpacing = itemSpacing

            for row in 0..<template.rows {
                for column in 0..<template.columns {
                    let originX = usableRect.minX + CGFloat(column) * (labelWidth + finalItemSpacing)
                    let originY = usableRect.minY + CGFloat(row) * (labelHeight + finalItemSpacing)
                    frames.append(CGRect(x: originX, y: originY, width: labelWidth, height: labelHeight))
                }
            }
        }

        let cornerRadius = max(10, min(28, min(labelWidth, labelHeight) * 0.08))

        return QRLabelLayoutSpec(
            pageRect: pageRect,
            labelFrames: frames,
            contentInset: contentInset,
            itemSpacing: finalItemSpacing,
            cornerRadius: cornerRadius
        )
    }
}
