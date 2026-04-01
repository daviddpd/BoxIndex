import AppKit

private struct SlideSpec {
    let inputFile: String
    let title: String
    let subtitle: String
    let outputStem: String
    let startColor: NSColor
    let endColor: NSColor
}

private struct CanvasSpec {
    let name: String
    let width: Int
    let height: Int
    let screenshotWidthRatio: CGFloat
}

private struct RenderFamily {
    let name: String
    let rawDirectory: URL
    let canvases: [CanvasSpec]
}

private let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
private let marketingRoot = projectRoot.appendingPathComponent("marketing", isDirectory: true)
private let rawScreensRoot = marketingRoot.appendingPathComponent("raw-screens", isDirectory: true)
private let iphoneRawDirectory = rawScreensRoot.appendingPathComponent("iphone", isDirectory: true)
private let ipad13RawDirectory = rawScreensRoot.appendingPathComponent("ipad-13", isDirectory: true)
private let outputDirectory = marketingRoot.appendingPathComponent("app-store", isDirectory: true)

private let slides: [SlideSpec] = [
    .init(
        inputFile: "01-home.png",
        title: "Know What's in Every Box",
        subtitle: "Browse containers by label, location, and latest updates in a fast local-first list.",
        outputStem: "01-home",
        startColor: .init(deviceRed: 0.98, green: 0.97, blue: 0.94, alpha: 1),
        endColor: .init(deviceRed: 0.89, green: 0.91, blue: 0.83, alpha: 1)
    ),
    .init(
        inputFile: "02-container-detail.png",
        title: "Open the Right Container Fast",
        subtitle: "See contents, notes, locations, photos, and QR codes together without digging around.",
        outputStem: "02-detail",
        startColor: .init(deviceRed: 0.95, green: 0.98, blue: 0.99, alpha: 1),
        endColor: .init(deviceRed: 0.80, green: 0.89, blue: 0.94, alpha: 1)
    ),
    .init(
        inputFile: "03-container-editor.png",
        title: "Label Containers Clearly",
        subtitle: "Set names, stable label codes, aliases, notes, locations, and color tags in one quick form.",
        outputStem: "03-editor",
        startColor: .init(deviceRed: 0.98, green: 0.98, blue: 0.95, alpha: 1),
        endColor: .init(deviceRed: 0.88, green: 0.92, blue: 0.84, alpha: 1)
    ),
    .init(
        inputFile: "04-search.png",
        title: "Search Containers and Contents",
        subtitle: "Find a tote, shelf, or box by name, label code, alias, notes, or saved item names.",
        outputStem: "04-search",
        startColor: .init(deviceRed: 0.96, green: 0.97, blue: 1.0, alpha: 1),
        endColor: .init(deviceRed: 0.83, green: 0.87, blue: 0.96, alpha: 1)
    ),
    .init(
        inputFile: "05-scan-label.png",
        title: "Scan Printed Labels",
        subtitle: "Point the camera at labels like GB-004 or Holiday Decor and jump to the best match.",
        outputStem: "05-scan-label",
        startColor: .init(deviceRed: 0.97, green: 0.99, blue: 0.97, alpha: 1),
        endColor: .init(deviceRed: 0.81, green: 0.90, blue: 0.85, alpha: 1)
    ),
    .init(
        inputFile: "06-scan-qr.png",
        title: "Open Containers with QR",
        subtitle: "Print a QR once, scan it later, and reopen the exact container from your iPhone.",
        outputStem: "06-scan-qr",
        startColor: .init(deviceRed: 0.98, green: 0.97, blue: 1.0, alpha: 1),
        endColor: .init(deviceRed: 0.88, green: 0.84, blue: 0.94, alpha: 1)
    ),
    .init(
        inputFile: "07-qr-output.png",
        title: "Print or Export QR Sheets",
        subtitle: "Select containers in batches, fit rows and columns, then print or export PDF and PNG labels.",
        outputStem: "07-qr-output",
        startColor: .init(deviceRed: 0.96, green: 0.99, blue: 0.99, alpha: 1),
        endColor: .init(deviceRed: 0.79, green: 0.89, blue: 0.89, alpha: 1)
    ),
    .init(
        inputFile: "08-backup.png",
        title: "Keep It Local and Portable",
        subtitle: "Export open JSON, CSV, and attachments, then restore from a prior BoxIndex backup any time.",
        outputStem: "08-backup",
        startColor: .init(deviceRed: 0.99, green: 0.97, blue: 0.95, alpha: 1),
        endColor: .init(deviceRed: 0.93, green: 0.85, blue: 0.82, alpha: 1)
    ),
]

private let renderFamilies: [RenderFamily] = [
    .init(
        name: "iPhone",
        rawDirectory: iphoneRawDirectory,
        canvases: [
            .init(name: "6.9", width: 1320, height: 2868, screenshotWidthRatio: 0.78),
            .init(name: "6.5", width: 1242, height: 2688, screenshotWidthRatio: 0.78),
        ]
    ),
    .init(
        name: "13-inch iPad",
        rawDirectory: ipad13RawDirectory,
        canvases: [
            .init(name: "ipad-13", width: 2064, height: 2752, screenshotWidthRatio: 0.59),
        ]
    ),
]

private func cgColor(_ color: NSColor) -> CGColor {
    color.usingColorSpace(.deviceRGB)!.cgColor
}

private func ensureDirectory(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

private func drawText(
    _ text: String,
    in rect: CGRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .center,
    lineHeightMultiple: CGFloat = 1.05
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = lineHeightMultiple

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
        .kern: 0.15,
    ]

    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

private func clearGeneratedPNGs(in directory: URL) throws {
    let contents = try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )

    for fileURL in contents where fileURL.pathExtension.lowercased() == "png" {
        try FileManager.default.removeItem(at: fileURL)
    }
}

private func missingInputFiles(in directory: URL) -> [String] {
    slides.compactMap { slide in
        let sourceURL = directory.appendingPathComponent(slide.inputFile)
        return FileManager.default.fileExists(atPath: sourceURL.path) ? nil : slide.inputFile
    }
}

private func renderSlide(
    slide: SlideSpec,
    canvas: CanvasSpec,
    sourceImage: NSImage,
    outputURL: URL
) throws {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: canvas.width,
            pixelsHigh: canvas.height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
        let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
    else {
        throw NSError(domain: "GenerateMarketingScreenshots", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let context = graphicsContext.cgContext
    let size = CGSize(width: canvas.width, height: canvas.height)
    let scale = min(CGFloat(canvas.width) / 1320.0, CGFloat(canvas.height) / 2868.0)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let backgroundGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [cgColor(slide.startColor), cgColor(slide.endColor)] as CFArray,
        locations: [0.0, 1.0]
    )!

    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: 0, y: size.height),
        end: CGPoint(x: size.width, y: 0),
        options: []
    )

    context.setFillColor(NSColor.white.withAlphaComponent(0.24).cgColor)
    context.fillEllipse(in: CGRect(x: 0.03 * size.width, y: 0.70 * size.height, width: 0.34 * size.width, height: 0.34 * size.width))
    context.fillEllipse(in: CGRect(x: 0.74 * size.width, y: 0.09 * size.height, width: 0.22 * size.width, height: 0.22 * size.width))

    let accentGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            NSColor(deviceRed: 0.20, green: 0.33, blue: 0.23, alpha: 0.12).cgColor,
            NSColor(deviceRed: 0.20, green: 0.33, blue: 0.23, alpha: 0.02).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        accentGradient,
        start: CGPoint(x: size.width * 0.72, y: size.height),
        end: CGPoint(x: size.width * 0.32, y: 0),
        options: []
    )

    let badgeRect = CGRect(
        x: 0.27 * size.width,
        y: size.height - (232 * scale),
        width: 0.46 * size.width,
        height: 58 * scale
    )
    let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 29 * scale, yRadius: 29 * scale)
    NSColor.white.withAlphaComponent(0.72).setFill()
    badgePath.fill()

    drawText(
        "BoxIndex",
        in: CGRect(x: badgeRect.minX, y: badgeRect.minY + (7 * scale), width: badgeRect.width, height: badgeRect.height),
        font: .systemFont(ofSize: 43 * scale, weight: .bold),
        color: NSColor(deviceRed: 0.19, green: 0.31, blue: 0.21, alpha: 0.96)
    )

    drawText(
        slide.title,
        in: CGRect(x: 86 * scale, y: size.height - (510 * scale), width: size.width - (172 * scale), height: 240 * scale),
        font: .systemFont(ofSize: 74 * scale, weight: .bold),
        color: NSColor(deviceWhite: 0.10, alpha: 1.0)
    )

    drawText(
        slide.subtitle,
        in: CGRect(x: 120 * scale, y: size.height - (648 * scale), width: size.width - (240 * scale), height: 124 * scale),
        font: .systemFont(ofSize: 37 * scale, weight: .medium),
        color: NSColor(deviceWhite: 0.18, alpha: 0.82),
        lineHeightMultiple: 1.08
    )

    let screenshotAspect = sourceImage.size.height / sourceImage.size.width
    let screenshotWidth = size.width * canvas.screenshotWidthRatio
    let screenshotHeight = screenshotWidth * screenshotAspect
    let screenshotRect = CGRect(
        x: (size.width - screenshotWidth) / 2.0,
        y: 118 * scale,
        width: screenshotWidth,
        height: screenshotHeight
    )

    let shadowRect = screenshotRect.offsetBy(dx: 0, dy: -15 * scale)
    let shadowPath = NSBezierPath(roundedRect: shadowRect, xRadius: 72 * scale, yRadius: 72 * scale)
    NSColor.black.withAlphaComponent(0.16).setFill()
    shadowPath.fill()

    let frameRect = screenshotRect.insetBy(dx: -15 * scale, dy: -15 * scale)
    let framePath = NSBezierPath(roundedRect: frameRect, xRadius: 78 * scale, yRadius: 78 * scale)
    NSColor.white.withAlphaComponent(0.82).setFill()
    framePath.fill()

    let clipPath = NSBezierPath(roundedRect: screenshotRect, xRadius: 64 * scale, yRadius: 64 * scale)
    clipPath.addClip()
    sourceImage.draw(in: screenshotRect)

    context.saveGState()
    context.setAlpha(0.12)
    context.drawLinearGradient(
        CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor.white.cgColor,
                NSColor.white.withAlphaComponent(0.0).cgColor,
            ] as CFArray,
            locations: [0, 1]
        )!,
        start: CGPoint(x: screenshotRect.minX, y: screenshotRect.maxY),
        end: CGPoint(x: screenshotRect.minX, y: screenshotRect.maxY - 320 * scale),
        options: []
    )
    context.restoreGState()

    let borderPath = NSBezierPath(roundedRect: screenshotRect, xRadius: 64 * scale, yRadius: 64 * scale)
    NSColor.white.withAlphaComponent(0.78).setStroke()
    borderPath.lineWidth = 3.0 * scale
    borderPath.stroke()

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateMarketingScreenshots", code: 2)
    }

    try pngData.write(to: outputURL)
}

try ensureDirectory(marketingRoot)
try ensureDirectory(rawScreensRoot)
try ensureDirectory(iphoneRawDirectory)
try ensureDirectory(ipad13RawDirectory)
try ensureDirectory(outputDirectory)

for family in renderFamilies {
    let missingFiles = missingInputFiles(in: family.rawDirectory)

    if !missingFiles.isEmpty {
        print("Skipping \(family.name) renders. Add these screenshots in \(family.rawDirectory.path):")
        for file in missingFiles {
            print("  - \(file)")
        }
        continue
    }

    for canvas in family.canvases {
        let canvasDirectory = outputDirectory.appendingPathComponent(canvas.name, isDirectory: true)
        try ensureDirectory(canvasDirectory)
        try clearGeneratedPNGs(in: canvasDirectory)

        for slide in slides {
            let sourceURL = family.rawDirectory.appendingPathComponent(slide.inputFile)

            guard let sourceImage = NSImage(contentsOf: sourceURL) else {
                throw NSError(
                    domain: "GenerateMarketingScreenshots",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Missing source image: \(sourceURL.path)"]
                )
            }

            let outputURL = canvasDirectory.appendingPathComponent("\(slide.outputStem).png")
            try renderSlide(slide: slide, canvas: canvas, sourceImage: sourceImage, outputURL: outputURL)
            print("Generated \(outputURL.path)")
        }
    }
}
