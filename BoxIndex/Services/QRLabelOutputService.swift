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
        let canvasSize = Self.labelCanvasSize(
            aspectRatio: options.clampedLabelAspectRatio,
            minimumShortestSide: 300
        )

        guard let image = Self.renderLabelImage(
            for: container,
            options: options,
            canvasSize: canvasSize
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

        let imageCanvasSize = Self.labelCanvasSize(
            aspectRatio: options.clampedLabelAspectRatio,
            minimumShortestSide: 900
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
                    canvasSize: imageCanvasSize
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
            schemaVersion: 3,
            exportedAt: .now,
            appName: "BoxIndex",
            template: options.template,
            exportPaperSize: options.exportPaperSize,
            includeName: options.includeName,
            includeLabelCode: options.includeLabelCode,
            useColorAccent: options.useColorAccent,
            labelAspectRatio: options.labelAspectRatio,
            textPosition: options.textPosition,
            textScale: options.textScale,
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
            ) { _, _, error in
                if let error {
                    onComplete(.failure(error))
                } else {
                    onComplete(.success(()))
                }
            }
        } else {
            didPresent = controller.present(animated: true) { _, _, error in
                if let error {
                    onComplete(.failure(error))
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
        let aspect = String(format: "%.2f", options.labelAspectRatio).replacingOccurrences(of: ".", with: "_")
        return "sheet-\(options.exportPaperSize.rawValue)-r\(options.template.rows)-c\(options.template.columns)-a\(aspect)-\(options.textPosition.rawValue).pdf"
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
                context: context
            )
        }
    }

    private static func labelCanvasSize(
        aspectRatio: CGFloat,
        minimumShortestSide: CGFloat
    ) -> CGSize {
        let ratio = max(0.5, min(2.5, aspectRatio))
        let shortestSide = max(240, minimumShortestSide)
        let squareRootRatio = sqrt(ratio)

        let width = shortestSide * squareRootRatio
        let height = shortestSide / squareRootRatio
        return CGSize(width: width, height: height)
    }

    private static func fittedLabelRect(in slotRect: CGRect, aspectRatio: CGFloat) -> CGRect {
        let ratio = max(0.5, min(2.5, aspectRatio))
        let availableRect = slotRect.insetBy(dx: 2, dy: 2)
        let slotRatio = availableRect.width / max(1, availableRect.height)

        if slotRatio > ratio {
            let height = availableRect.height
            let width = height * ratio
            return CGRect(
                x: availableRect.midX - (width / 2),
                y: availableRect.minY,
                width: width,
                height: height
            ).integral
        } else {
            let width = availableRect.width
            let height = width / ratio
            return CGRect(
                x: availableRect.minX,
                y: availableRect.midY - (height / 2),
                width: width,
                height: height
            ).integral
        }
    }

    private static func renderLabelImage(
        for container: Container,
        options: QRLabelOutputOptions,
        canvasSize: CGSize
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
                context: imageContext.cgContext
            )
        }
    }

    private static func drawLabel(
        for container: Container,
        in slotRect: CGRect,
        options: QRLabelOutputOptions,
        context: CGContext
    ) {
        let labelRect = fittedLabelRect(in: slotRect, aspectRatio: options.clampedLabelAspectRatio)
        let printableAccent = printableAccentColor(for: container, useColorAccent: options.useColorAccent)
        let borderColor = options.useColorAccent ? printableAccent.withAlphaComponent(0.4) : UIColor.systemGray4
        let titleColor = options.useColorAccent ? printableAccent : UIColor.black
        let cornerRadius = max(10, min(28, min(labelRect.width, labelRect.height) * 0.08))
        let cardPath = UIBezierPath(roundedRect: labelRect, cornerRadius: cornerRadius)

        context.saveGState()
        context.setFillColor(UIColor.white.cgColor)
        cardPath.fill()
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(max(1, min(labelRect.width, labelRect.height) * 0.012))
        cardPath.stroke()

        if options.useColorAccent {
            let accentBandHeight = max(6, labelRect.height * 0.035)
            let accentBandRect = CGRect(
                x: labelRect.minX,
                y: labelRect.minY,
                width: labelRect.width,
                height: accentBandHeight
            )
            context.setFillColor(printableAccent.withAlphaComponent(0.18).cgColor)
            context.fill(accentBandRect)
        }

        let innerPadding = max(8, min(labelRect.width, labelRect.height) * 0.08)
        let interRegionSpacing = max(8, min(labelRect.width, labelRect.height) * 0.04)
        let scaleFactor = sqrt(options.clampedTextScale)
        let contentRect = labelRect.insetBy(dx: innerPadding, dy: innerPadding)
        let textLineCount = CGFloat((options.includeLabelCode ? 1 : 0) + (options.includeName ? 1 : 0))

        let metadataRect: CGRect
        let qrBounds: CGRect
        switch options.textPosition {
        case .top:
            let textHeight = min(
                contentRect.height * 0.54,
                max(58, contentRect.height * (0.20 + (textLineCount * 0.07) + 0.08) * scaleFactor)
            )
            metadataRect = CGRect(
                x: contentRect.minX,
                y: contentRect.minY,
                width: contentRect.width,
                height: textHeight
            )
            qrBounds = CGRect(
                x: contentRect.minX,
                y: metadataRect.maxY + interRegionSpacing,
                width: contentRect.width,
                height: max(0, contentRect.maxY - metadataRect.maxY - interRegionSpacing)
            )
        case .bottom:
            let textHeight = min(
                contentRect.height * 0.54,
                max(58, contentRect.height * (0.20 + (textLineCount * 0.07) + 0.08) * scaleFactor)
            )
            metadataRect = CGRect(
                x: contentRect.minX,
                y: contentRect.maxY - textHeight,
                width: contentRect.width,
                height: textHeight
            )
            qrBounds = CGRect(
                x: contentRect.minX,
                y: contentRect.minY,
                width: contentRect.width,
                height: max(0, metadataRect.minY - contentRect.minY - interRegionSpacing)
            )
        case .left:
            let textWidth = min(
                contentRect.width * 0.5,
                max(74, contentRect.width * (0.24 + (textLineCount * 0.08) + 0.10) * scaleFactor)
            )
            metadataRect = CGRect(
                x: contentRect.minX,
                y: contentRect.minY,
                width: textWidth,
                height: contentRect.height
            )
            qrBounds = CGRect(
                x: metadataRect.maxX + interRegionSpacing,
                y: contentRect.minY,
                width: max(0, contentRect.maxX - metadataRect.maxX - interRegionSpacing),
                height: contentRect.height
            )
        case .right:
            let textWidth = min(
                contentRect.width * 0.5,
                max(74, contentRect.width * (0.24 + (textLineCount * 0.08) + 0.10) * scaleFactor)
            )
            metadataRect = CGRect(
                x: contentRect.maxX - textWidth,
                y: contentRect.minY,
                width: textWidth,
                height: contentRect.height
            )
            qrBounds = CGRect(
                x: contentRect.minX,
                y: contentRect.minY,
                width: max(0, metadataRect.minX - contentRect.minX - interRegionSpacing),
                height: contentRect.height
            )
        }

        let qrSide = max(0, min(qrBounds.width, qrBounds.height))
        if qrSide > 0 {
            let qrFrame = CGRect(
                x: qrBounds.midX - (qrSide / 2),
                y: qrBounds.midY - (qrSide / 2),
                width: qrSide,
                height: qrSide
            ).integral

            if let qrImage = QRCodeService.image(for: container, size: qrSide * 4),
               let cgImage = qrImage.cgImage {
                context.interpolationQuality = .none
                context.draw(cgImage, in: qrFrame)
            }
        }

        drawMetadataBlock(
            for: container,
            in: metadataRect,
            titleColor: titleColor,
            accentColor: printableAccent,
            options: options
        )

        context.restoreGState()
    }

    private static func drawMetadataBlock(
        for container: Container,
        in rect: CGRect,
        titleColor: UIColor,
        accentColor: UIColor,
        options: QRLabelOutputOptions
    ) {
        guard rect.width > 0, rect.height > 0 else {
            return
        }

        let icon = container.resolvedIcon
        let iconContainerSize = min(
            max(28, min(rect.width, rect.height) * 0.28),
            rect.width * 0.5
        )
        let iconRect = CGRect(
            x: rect.midX - (iconContainerSize / 2),
            y: rect.minY,
            width: iconContainerSize,
            height: iconContainerSize
        )

        let iconBackground = options.useColorAccent
            ? accentColor.withAlphaComponent(0.14)
            : UIColor.systemGray6
        let iconPath = UIBezierPath(
            roundedRect: iconRect,
            cornerRadius: max(10, iconContainerSize * 0.28)
        )
        iconBackground.setFill()
        iconPath.fill()

        drawIcon(
            icon,
            in: iconRect.insetBy(dx: iconContainerSize * 0.2, dy: iconContainerSize * 0.2),
            color: titleColor
        )

        let textTop = iconRect.maxY + max(6, rect.height * 0.06)
        let textRect = CGRect(
            x: rect.minX,
            y: textTop,
            width: rect.width,
            height: max(0, rect.maxY - textTop)
        )

        drawText(
            for: container,
            in: textRect,
            titleColor: titleColor,
            options: options
        )
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
        let scale = options.clampedTextScale
        let referenceDimension = min(max(rect.width * 0.44, rect.height), max(rect.width, rect.height))
        let labelFont = UIFont.systemFont(
            ofSize: max(10, min(30, referenceDimension * 0.18 * scale)),
            weight: .semibold
        )
        let nameFont = UIFont.systemFont(
            ofSize: max(9, min(24, referenceDimension * 0.15 * scale)),
            weight: .regular
        )

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

        guard attributed.length > 0 else {
            return
        }

        attributed.draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )
    }

    private static func drawIcon(
        _ icon: ContainerIcon,
        in rect: CGRect,
        color: UIColor
    ) {
        let pointSize = min(rect.width, rect.height) * 0.88
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = UIImage(systemName: icon.resolvedSymbolName, withConfiguration: configuration)?
            .withTintColor(color, renderingMode: .alwaysOriginal)

        image?.draw(in: rect)
    }

    private static func printableAccentColor(for container: Container, useColorAccent: Bool) -> UIColor {
        guard useColorAccent else {
            return .black
        }

        let accent = ContainerColorTag.uiColor(for: container.colorTag) ?? container.resolvedIcon.uiColor
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
