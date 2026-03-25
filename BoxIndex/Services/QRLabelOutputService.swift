//
//  QRLabelOutputService.swift
//  BoxIndex
//
//  Created by Codex on 3/22/26.
//

import Foundation
import UIKit

enum QRLabelOutputError: LocalizedError {
    case noContainers
    case noExportFormatsSelected
    case printUnavailable
    case missingPresentationContext
    case failedToPresentPrintUI
    case failedToGenerateImage

    var errorDescription: String? {
        switch self {
        case .noContainers:
            return "Select at least one container for QR output."
        case .noExportFormatsSelected:
            return "Choose a PDF sheet, individual PNGs, or both before exporting."
        case .printUnavailable:
            return "Printing is not available on this device."
        case .missingPresentationContext:
            return "BoxIndex could not find an active screen to present printing options."
        case .failedToPresentPrintUI:
            return "BoxIndex could not open the printing sheet."
        case .failedToGenerateImage:
            return "BoxIndex could not generate the QR label image."
        }
    }
}

struct QRLabelPreview {
    let image: UIImage
    let title: String
}

@MainActor
final class QRLabelOutputService {
    func preview(for container: Container, options: QRLabelOutputOptions) throws -> QRLabelPreview {
        let layout = QRLabelLayoutSpec.make(
            pageRect: options.exportPaperSize.pageRect,
            template: options.template
        )
        let previewFrame = layout.labelFrames.first ?? CGRect(x: 0, y: 0, width: 320, height: 320)
        let previewSize = CGSize(
            width: max(previewFrame.width, 220),
            height: max(previewFrame.height, 220)
        )

        guard let image = Self.renderLabelImage(
            for: container,
            options: options,
            canvasSize: previewSize,
            cornerRadius: layout.cornerRadius
        ) else {
            throw QRLabelOutputError.failedToGenerateImage
        }

        return QRLabelPreview(image: image, title: container.displayTitle)
    }

    func sheetPDFData(for containers: [Container], options: QRLabelOutputOptions) throws -> Data {
        let sortedContainers = Self.sorted(containers)
        guard !sortedContainers.isEmpty else {
            throw QRLabelOutputError.noContainers
        }

        let pageRect = options.exportPaperSize.pageRect
        let totalPages = pageCount(for: sortedContainers, options: options)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            for pageIndex in 0..<totalPages {
                context.beginPage()
                let cgContext = context.cgContext
                Self.fillPageBackground(pageRect, context: cgContext)

                let layout = QRLabelLayoutSpec.make(pageRect: pageRect, template: options.template)
                Self.drawPage(
                    pageIndex: pageIndex,
                    containers: sortedContainers,
                    layout: layout,
                    options: options,
                    context: cgContext
                )
            }
        }
    }

    func buildExportPackage(from containers: [Container], options: QRLabelOutputOptions) throws -> ExportPackage {
        let sortedContainers = Self.sorted(containers)
        guard !sortedContainers.isEmpty else {
            throw QRLabelOutputError.noContainers
        }
        guard options.hasExportSelection else {
            throw QRLabelOutputError.noExportFormatsSelected
        }

        let timestamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        let baseName = "BoxIndex QR Labels \(timestamp)"
        let rootName = if let fileExtension = options.packaging.fileExtension {
            "\(baseName).\(fileExtension)"
        } else {
            baseName
        }

        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(rootName, isDirectory: true)
        if FileManager.default.fileExists(atPath: rootURL.path) {
            try FileManager.default.removeItem(at: rootURL)
        }
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let previewLayout = QRLabelLayoutSpec.make(
            pageRect: options.exportPaperSize.pageRect,
            template: options.template
        )
        let previewFrame = previewLayout.labelFrames.first ?? CGRect(x: 0, y: 0, width: 340, height: 340)
        let imageCanvasSize = CGSize(
            width: max(previewFrame.width, 340),
            height: max(previewFrame.height, 340)
        )

        var fileNameCounts: [String: Int] = [:]
        var fileRecords: [QRLabelExportFileRecord] = []

        if options.exportsIndividualPNGs {
            let imagesURL = rootURL.appendingPathComponent("individual", isDirectory: true)
            try FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)

            for container in sortedContainers {
                let baseFileName = Self.sanitizedBaseFileName(for: container)
                let count = fileNameCounts[baseFileName, default: 0]
                fileNameCounts[baseFileName] = count + 1

                let resolvedBaseName = if count == 0 {
                    baseFileName
                } else {
                    "\(baseFileName)-\(count + 1)"
                }

                let fileName = "\(resolvedBaseName).\(options.individualAssetFormat.fileExtension)"
                let fileURL = imagesURL.appendingPathComponent(fileName)

                guard let image = Self.renderLabelImage(
                    for: container,
                    options: options,
                    canvasSize: imageCanvasSize,
                    cornerRadius: previewLayout.cornerRadius
                ) else {
                    throw QRLabelOutputError.failedToGenerateImage
                }

                guard let data = image.pngData() else {
                    throw QRLabelOutputError.failedToGenerateImage
                }

                try data.write(to: fileURL, options: .atomic)
                fileRecords.append(
                    QRLabelExportFileRecord(
                        id: container.id,
                        name: container.displayTitle,
                        labelCode: container.labelCode,
                        fileName: "individual/\(fileName)"
                    )
                )
            }
        }

        let sheetFileName: String?
        if options.exportsPDFSheet {
            let fileName = Self.sheetFileName(for: options)
            let sheetURL = rootURL.appendingPathComponent(fileName)
            try sheetPDFData(for: sortedContainers, options: options).write(to: sheetURL, options: .atomic)
            sheetFileName = fileName
        } else {
            sheetFileName = nil
        }

        let manifest = QRLabelExportManifest(
            schemaVersion: 2,
            exportedAt: .now,
            appName: "BoxIndex",
            template: options.template,
            exportPaperSize: options.exportPaperSize,
            includeName: options.includeName,
            includeLabelCode: options.includeLabelCode,
            useColorAccent: options.useColorAccent,
            packaging: options.packaging,
            exportsPDFSheet: options.exportsPDFSheet,
            exportsIndividualPNGs: options.exportsIndividualPNGs,
            individualAssetFormat: options.individualAssetFormat,
            sheetFileName: sheetFileName,
            individualFiles: fileRecords
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let manifestURL = rootURL.appendingPathComponent("qr-label-export.json")
        try encoder.encode(manifest).write(to: manifestURL, options: .atomic)

        return ExportPackage(directoryURL: rootURL, displayName: rootName)
    }

    func pageCount(for containers: [Container], options: QRLabelOutputOptions) -> Int {
        let count = Self.sorted(containers).count
        guard count > 0 else {
            return 0
        }

        let itemsPerPage = max(1, options.template.itemsPerPage)
        return Int(ceil(Double(count) / Double(itemsPerPage)))
    }

    func presentPrintSheet(
        for containers: [Container],
        options: QRLabelOutputOptions,
        onComplete: @escaping (Result<Void, Error>) -> Void
    ) {
        guard UIPrintInteractionController.isPrintingAvailable else {
            onComplete(.failure(QRLabelOutputError.printUnavailable))
            return
        }

        let sortedContainers = Self.sorted(containers)
        guard !sortedContainers.isEmpty else {
            onComplete(.failure(QRLabelOutputError.noContainers))
            return
        }

        let controller = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        printInfo.jobName = sortedContainers.count == 1
            ? "BoxIndex QR Label"
            : "BoxIndex QR Labels"
        printInfo.orientation = .portrait
        printInfo.duplex = .none
        printInfo.outputType = options.useColorAccent ? .general : .grayscale

        controller.printInfo = printInfo
        controller.showsNumberOfCopies = true
        controller.showsPaperSelectionForLoadedPapers = true
        controller.showsPaperOrientation = true
        controller.printingItem = nil
        controller.printingItems = nil
        controller.printPageRenderer = QRLabelPrintPageRenderer(
            containers: sortedContainers,
            options: options
        )

        guard let rootViewController = UIApplication.shared.topViewController() else {
            onComplete(.failure(QRLabelOutputError.missingPresentationContext))
            return
        }

        let didPresent: Bool
        if UIDevice.current.userInterfaceIdiom == .pad {
            let sourceRect = CGRect(
                x: rootViewController.view.bounds.midX - 1,
                y: rootViewController.view.bounds.midY - 1,
                width: 2,
                height: 2
            )
            didPresent = controller.present(
                from: sourceRect,
                in: rootViewController.view,
                animated: true
            ) { _, completed, error in
                if let error {
                    onComplete(.failure(error))
                } else if completed {
                    onComplete(.success(()))
                } else {
                    onComplete(.success(()))
                }
            }
        } else {
            didPresent = controller.present(animated: true) { _, completed, error in
                if let error {
                    onComplete(.failure(error))
                } else if completed {
                    onComplete(.success(()))
                } else {
                    onComplete(.success(()))
                }
            }
        }

        if !didPresent {
            onComplete(.failure(QRLabelOutputError.failedToPresentPrintUI))
        }
    }

    private static func sheetFileName(for options: QRLabelOutputOptions) -> String {
        "sheet-\(options.exportPaperSize.rawValue)-r\(options.template.rows)-c\(options.template.columns).pdf"
    }

    fileprivate static func fillPageBackground(_ rect: CGRect, context: CGContext) {
        context.saveGState()
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)
        context.restoreGState()
    }

    fileprivate static func drawPage(
        pageIndex: Int,
        containers: [Container],
        layout: QRLabelLayoutSpec,
        options: QRLabelOutputOptions,
        context: CGContext
    ) {
        let itemsPerPage = max(1, options.template.itemsPerPage)
        let startIndex = pageIndex * itemsPerPage

        for (offset, frame) in layout.labelFrames.enumerated() {
            let containerIndex = startIndex + offset
            guard containerIndex < containers.count else {
                break
            }

            drawLabel(
                for: containers[containerIndex],
                in: frame,
                options: options,
                cornerRadius: layout.cornerRadius,
                context: context
            )
        }
    }

    private static func renderLabelImage(
        for container: Container,
        options: QRLabelOutputOptions,
        canvasSize: CGSize,
        cornerRadius: CGFloat
    ) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = true
        format.scale = 3

        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { imageContext in
            let rect = CGRect(origin: .zero, size: canvasSize)
            fillPageBackground(rect, context: imageContext.cgContext)
            drawLabel(
                for: container,
                in: rect,
                options: options,
                cornerRadius: cornerRadius,
                context: imageContext.cgContext
            )
        }
    }

    private static func drawLabel(
        for container: Container,
        in rect: CGRect,
        options: QRLabelOutputOptions,
        cornerRadius: CGFloat,
        context: CGContext
    ) {
        let printableAccent = printableAccentColor(for: container, useColorAccent: options.useColorAccent)
        let borderColor = options.useColorAccent ? printableAccent.withAlphaComponent(0.4) : UIColor.systemGray4
        let titleColor = options.useColorAccent ? printableAccent : UIColor.black
        let cardRect = rect.insetBy(dx: 2, dy: 2)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cornerRadius)

        context.saveGState()
        context.setFillColor(UIColor.white.cgColor)
        cardPath.fill()
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(max(1, min(rect.width, rect.height) * 0.012))
        cardPath.stroke()

        if options.useColorAccent {
            let accentBandHeight = max(6, rect.height * 0.035)
            let accentBandRect = CGRect(
                x: cardRect.minX,
                y: cardRect.minY,
                width: cardRect.width,
                height: accentBandHeight
            )
            context.setFillColor(printableAccent.withAlphaComponent(0.18).cgColor)
            context.fill(accentBandRect)
        }

        let innerPadding = max(8, min(rect.width, rect.height) * 0.08)
        let textLineCount = [options.includeLabelCode, options.includeName].filter { $0 }.count
        let textRegionHeight: CGFloat = if textLineCount == 0 {
            0
        } else if textLineCount == 1 {
            max(34, rect.height * 0.18)
        } else {
            max(58, rect.height * 0.30)
        }

        let qrSide = min(
            cardRect.width - (innerPadding * 2),
            cardRect.height - (innerPadding * 2) - textRegionHeight
        )
        let qrFrame = CGRect(
            x: cardRect.midX - (qrSide / 2),
            y: cardRect.minY + innerPadding,
            width: qrSide,
            height: qrSide
        )

        if let qrImage = QRCodeService.image(for: container, size: qrSide * 4),
           let cgImage = qrImage.cgImage {
            context.interpolationQuality = .none
            context.draw(cgImage, in: qrFrame)
        }

        let textRegionY = qrFrame.maxY + max(6, innerPadding * 0.45)
        let textRect = CGRect(
            x: cardRect.minX + innerPadding,
            y: textRegionY,
            width: cardRect.width - (innerPadding * 2),
            height: max(0, cardRect.maxY - textRegionY - innerPadding)
        )

        drawText(
            for: container,
            in: textRect,
            titleColor: titleColor,
            options: options
        )

        context.restoreGState()
    }

    private static func drawText(
        for container: Container,
        in rect: CGRect,
        titleColor: UIColor,
        options: QRLabelOutputOptions
    ) {
        guard rect.height > 0 else {
            return
        }

        let labelCode = container.labelCode.trimmed
        let name = container.displayTitle.trimmed
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributed = NSMutableAttributedString()
        let maxDimension = min(rect.width, rect.height)
        let labelFont = UIFont.systemFont(ofSize: max(10, min(22, maxDimension * 0.36)), weight: .semibold)
        let nameFont = UIFont.systemFont(ofSize: max(9, min(19, maxDimension * 0.28)), weight: .regular)

        if options.includeLabelCode, !labelCode.isEmpty {
            attributed.append(
                NSAttributedString(
                    string: labelCode,
                    attributes: [
                        .font: labelFont,
                        .foregroundColor: titleColor,
                        .paragraphStyle: paragraphStyle,
                    ]
                )
            )
        }

        if options.includeName, !name.isEmpty {
            if attributed.length > 0 {
                attributed.append(NSAttributedString(string: "\n"))
            }

            attributed.append(
                NSAttributedString(
                    string: name,
                    attributes: [
                        .font: nameFont,
                        .foregroundColor: options.useColorAccent ? titleColor : UIColor.black,
                        .paragraphStyle: paragraphStyle,
                    ]
                )
            )
        }

        attributed.draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )
    }

    private static func printableAccentColor(for container: Container, useColorAccent: Bool) -> UIColor {
        guard useColorAccent, let accent = ContainerColorTag.uiColor(for: container.colorTag) else {
            return .black
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        accent.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return UIColor(
            red: max(0, red * 0.65),
            green: max(0, green * 0.65),
            blue: max(0, blue * 0.65),
            alpha: 1
        )
    }

    private static func sorted(_ containers: [Container]) -> [Container] {
        containers.sorted {
            if $0.labelCode.localizedCaseInsensitiveCompare($1.labelCode) == .orderedSame {
                return $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
            }

            return $0.labelCode.localizedCaseInsensitiveCompare($1.labelCode) == .orderedAscending
        }
    }

    private static func sanitizedBaseFileName(for container: Container) -> String {
        let base = [container.labelCode.trimmed, container.displayTitle.trimmed]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let cleanedScalars = base.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }

        let cleaned = String(cleanedScalars)
            .replacingOccurrences(of: "  ", with: " ")
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "- "))

        return cleaned.isEmpty ? container.id.uuidString : cleaned
    }
}

private final class QRLabelPrintPageRenderer: UIPrintPageRenderer {
    private let containers: [Container]
    private let options: QRLabelOutputOptions
    private let pageTotal: Int

    init(containers: [Container], options: QRLabelOutputOptions) {
        self.containers = containers
        self.options = options
        self.pageTotal = Int(
            ceil(Double(containers.count) / Double(max(1, options.template.itemsPerPage)))
        )
        super.init()
        headerHeight = 0
        footerHeight = 0
    }

    override var numberOfPages: Int {
        pageTotal
    }

    override func drawPage(at pageIndex: Int, in printableRect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        let resolvedPaperRect = paperRect.isEmpty
            ? CGRect(origin: .zero, size: printableRect.size)
            : paperRect
        let resolvedContentRect = printableRect.isEmpty
            ? resolvedPaperRect.insetBy(dx: 18, dy: 18)
            : printableRect.insetBy(dx: 4, dy: 4)

        QRLabelOutputService.fillPageBackground(resolvedPaperRect, context: context)

        let layout = QRLabelLayoutSpec.make(
            pageRect: resolvedPaperRect,
            template: options.template,
            contentRect: resolvedContentRect
        )

        QRLabelOutputService.drawPage(
            pageIndex: pageIndex,
            containers: containers,
            layout: layout,
            options: options,
            context: context
        )
    }
}

private extension UIApplication {
    func topViewController() -> UIViewController? {
        let activeScenes = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        let keyWindow = activeScenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        return keyWindow?.rootViewController?.topMostPresentedViewController
    }
}

private extension UIViewController {
    var topMostPresentedViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostPresentedViewController
        }

        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topMostPresentedViewController
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topMostPresentedViewController
        }

        return self
    }
}
