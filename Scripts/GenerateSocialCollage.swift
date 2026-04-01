import AppKit

private struct VisualCard {
    let path: String
    let frame: CGRect
    let rotationDegrees: CGFloat
    let symbolName: String
    let title: String
    let subtitle: String
    let accentColor: NSColor
}

private struct TextSpec {
    let text: String
    let rect: CGRect
    let fontSize: CGFloat
    let weight: NSFont.Weight
    let color: NSColor
    let lineHeightMultiple: CGFloat
    let alignment: NSTextAlignment
}

private struct EllipseSpec {
    let rect: CGRect
    let alpha: CGFloat
}

private struct PanelSpec {
    let panelRect: CGRect
    let eyebrow: TextSpec
    let title: TextSpec
    let subtitle: TextSpec
    let detail: TextSpec
    let iconRect: CGRect
}

private struct SocialAsset {
    let outputFileName: String
    let canvasSize: CGSize
    let startColor: NSColor
    let endColor: NSColor
    let accentCenter: CGPoint
    let accentRadius: CGFloat
    let ellipses: [EllipseSpec]
    let badgeRect: CGRect
    let headline: TextSpec
    let body: TextSpec
    let featuresOrigin: CGPoint
    let featureSpacing: CGFloat
    let panel: PanelSpec
    let cards: [VisualCard]
}

private let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
private let marketingRoot = projectRoot.appendingPathComponent("marketing", isDirectory: true)
private let rawScreensDirectory = marketingRoot.appendingPathComponent("raw-screens/iphone", isDirectory: true)
private let outputDirectory = marketingRoot.appendingPathComponent("social", isDirectory: true)
private let appIconURL = projectRoot.appendingPathComponent(
    "BoxIndex/Assets.xcassets/AppIcon.appiconset/AppIcon-Light.png"
)

private let features = [
    "Know what's in every box",
    "Scan labels and QR codes",
    "Print or export QR sheets",
    "Local-first with open exports",
]

private let assets: [SocialAsset] = [
    .init(
        outputFileName: "boxindex-linkedin-coming-soon.png",
        canvasSize: CGSize(width: 2400, height: 1500),
        startColor: NSColor(deviceRed: 0.97, green: 0.96, blue: 0.92, alpha: 1),
        endColor: NSColor(deviceRed: 0.84, green: 0.90, blue: 0.83, alpha: 1),
        accentCenter: CGPoint(x: 380, y: 1080),
        accentRadius: 760,
        ellipses: [
            .init(rect: CGRect(x: -120, y: 870, width: 720, height: 720), alpha: 0.22),
            .init(rect: CGRect(x: 1700, y: 30, width: 560, height: 560), alpha: 0.18),
        ],
        badgeRect: CGRect(x: 120, y: 1240, width: 320, height: 68),
        headline: .init(
            text: "BoxIndex\ncoming soon",
            rect: CGRect(x: 120, y: 920, width: 760, height: 260),
            fontSize: 88,
            weight: .bold,
            color: NSColor(deviceWhite: 0.10, alpha: 1),
            lineHeightMultiple: 0.92,
            alignment: .left
        ),
        body: .init(
            text: "A private iPhone app for boxes, bins, totes, shelves, and storage containers.",
            rect: CGRect(x: 128, y: 760, width: 690, height: 120),
            fontSize: 38,
            weight: .medium,
            color: NSColor(deviceWhite: 0.18, alpha: 0.82),
            lineHeightMultiple: 1.08,
            alignment: .left
        ),
        featuresOrigin: CGPoint(x: 172, y: 620),
        featureSpacing: 84,
        panel: .init(
            panelRect: CGRect(x: 120, y: 88, width: 940, height: 250),
            eyebrow: .init(
                text: "COMING SOON",
                rect: CGRect(x: 154, y: 278, width: 540, height: 28),
                fontSize: 18,
                weight: .bold,
                color: NSColor(deviceRed: 0.24, green: 0.39, blue: 0.25, alpha: 0.88),
                lineHeightMultiple: 1.0,
                alignment: .left
            ),
            title: .init(
                text: "Local-first container organization for iPhone",
                rect: CGRect(x: 154, y: 226, width: 610, height: 40),
                fontSize: 31,
                weight: .bold,
                color: NSColor(deviceWhite: 0.12, alpha: 1),
                lineHeightMultiple: 1.0,
                alignment: .left
            ),
            subtitle: .init(
                text: "Fast search, label scanning, QR support, and clean export without accounts or subscriptions.",
                rect: CGRect(x: 154, y: 160, width: 610, height: 58),
                fontSize: 23,
                weight: .medium,
                color: NSColor(deviceWhite: 0.20, alpha: 0.78),
                lineHeightMultiple: 1.08,
                alignment: .left
            ),
            detail: .init(
                text: "Built for garages, closets, storage rooms, and practical home organization.",
                rect: CGRect(x: 154, y: 106, width: 610, height: 34),
                fontSize: 17,
                weight: .semibold,
                color: NSColor(deviceRed: 0.24, green: 0.39, blue: 0.25, alpha: 0.94),
                lineHeightMultiple: 1.0,
                alignment: .left
            ),
            iconRect: CGRect(x: 816, y: 110, width: 190, height: 190)
        ),
        cards: [
            .init(
                path: "01-home.png",
                frame: CGRect(x: 1120, y: 525, width: 360, height: 780),
                rotationDegrees: -8,
                symbolName: "shippingbox.fill",
                title: "Container list",
                subtitle: "Search boxes, bins, and shelves fast.",
                accentColor: NSColor(deviceRed: 0.82, green: 0.90, blue: 0.83, alpha: 1)
            ),
            .init(
                path: "05-scan-label.png",
                frame: CGRect(x: 1450, y: 410, width: 360, height: 780),
                rotationDegrees: -3,
                symbolName: "text.viewfinder",
                title: "Label scanning",
                subtitle: "Match printed labels and jump straight in.",
                accentColor: NSColor(deviceRed: 0.80, green: 0.88, blue: 0.93, alpha: 1)
            ),
            .init(
                path: "07-qr-output.png",
                frame: CGRect(x: 1705, y: 210, width: 390, height: 840),
                rotationDegrees: 6,
                symbolName: "qrcode.viewfinder",
                title: "QR output",
                subtitle: "Print or export grouped labels.",
                accentColor: NSColor(deviceRed: 0.91, green: 0.86, blue: 0.79, alpha: 1)
            ),
            .init(
                path: "08-backup.png",
                frame: CGRect(x: 1320, y: 155, width: 430, height: 930),
                rotationDegrees: 2,
                symbolName: "square.and.arrow.up",
                title: "Open exports",
                subtitle: "Portable JSON, CSV, and image bundles.",
                accentColor: NSColor(deviceRed: 0.87, green: 0.90, blue: 0.83, alpha: 1)
            ),
            .init(
                path: "02-container-detail.png",
                frame: CGRect(x: 1000, y: 140, width: 330, height: 720),
                rotationDegrees: -12,
                symbolName: "list.bullet.rectangle.portrait.fill",
                title: "Quick detail",
                subtitle: "See notes, items, and QR in one place.",
                accentColor: NSColor(deviceRed: 0.86, green: 0.84, blue: 0.92, alpha: 1)
            ),
        ]
    ),
    .init(
        outputFileName: "boxindex-square-coming-soon.png",
        canvasSize: CGSize(width: 1800, height: 1800),
        startColor: NSColor(deviceRed: 0.97, green: 0.96, blue: 0.93, alpha: 1),
        endColor: NSColor(deviceRed: 0.84, green: 0.90, blue: 0.84, alpha: 1),
        accentCenter: CGPoint(x: 420, y: 1300),
        accentRadius: 820,
        ellipses: [
            .init(rect: CGRect(x: -150, y: 1060, width: 760, height: 760), alpha: 0.20),
            .init(rect: CGRect(x: 1180, y: 50, width: 560, height: 560), alpha: 0.18),
        ],
        badgeRect: CGRect(x: 110, y: 1535, width: 300, height: 66),
        headline: .init(
            text: "BoxIndex\ncoming soon",
            rect: CGRect(x: 110, y: 1200, width: 720, height: 260),
            fontSize: 84,
            weight: .bold,
            color: NSColor(deviceWhite: 0.10, alpha: 1),
            lineHeightMultiple: 0.92,
            alignment: .left
        ),
        body: .init(
            text: "A local-first iPhone app for practical storage container organization.",
            rect: CGRect(x: 118, y: 1040, width: 620, height: 110),
            fontSize: 35,
            weight: .medium,
            color: NSColor(deviceWhite: 0.18, alpha: 0.82),
            lineHeightMultiple: 1.08,
            alignment: .left
        ),
        featuresOrigin: CGPoint(x: 160, y: 900),
        featureSpacing: 75,
        panel: .init(
            panelRect: CGRect(x: 110, y: 94, width: 950, height: 260),
            eyebrow: .init(
                text: "COMING SOON",
                rect: CGRect(x: 144, y: 292, width: 540, height: 26),
                fontSize: 17,
                weight: .bold,
                color: NSColor(deviceRed: 0.24, green: 0.39, blue: 0.25, alpha: 0.88),
                lineHeightMultiple: 1.0,
                alignment: .left
            ),
            title: .init(
                text: "Simple, private, practical",
                rect: CGRect(x: 144, y: 236, width: 620, height: 38),
                fontSize: 30,
                weight: .bold,
                color: NSColor(deviceWhite: 0.12, alpha: 1),
                lineHeightMultiple: 1.0,
                alignment: .left
            ),
            subtitle: .init(
                text: "Track boxes, scan labels, print QR sheets, and keep everything local by default.",
                rect: CGRect(x: 144, y: 168, width: 620, height: 58),
                fontSize: 23,
                weight: .medium,
                color: NSColor(deviceWhite: 0.20, alpha: 0.78),
                lineHeightMultiple: 1.08,
                alignment: .left
            ),
            detail: .init(
                text: "Built for garages, closets, storage rooms, and everyday container lookup.",
                rect: CGRect(x: 144, y: 116, width: 620, height: 34),
                fontSize: 16,
                weight: .semibold,
                color: NSColor(deviceRed: 0.24, green: 0.39, blue: 0.25, alpha: 0.94),
                lineHeightMultiple: 1.0,
                alignment: .left
            ),
            iconRect: CGRect(x: 860, y: 118, width: 160, height: 160)
        ),
        cards: [
            .init(
                path: "01-home.png",
                frame: CGRect(x: 990, y: 840, width: 255, height: 555),
                rotationDegrees: -10,
                symbolName: "shippingbox.fill",
                title: "Containers",
                subtitle: "Know what lives where.",
                accentColor: NSColor(deviceRed: 0.82, green: 0.90, blue: 0.83, alpha: 1)
            ),
            .init(
                path: "05-scan-label.png",
                frame: CGRect(x: 1280, y: 790, width: 275, height: 595),
                rotationDegrees: 7,
                symbolName: "text.viewfinder",
                title: "Scan labels",
                subtitle: "Printed label lookup.",
                accentColor: NSColor(deviceRed: 0.80, green: 0.88, blue: 0.93, alpha: 1)
            ),
            .init(
                path: "07-qr-output.png",
                frame: CGRect(x: 1060, y: 420, width: 320, height: 690),
                rotationDegrees: 1.5,
                symbolName: "qrcode.viewfinder",
                title: "QR sheets",
                subtitle: "Print or export in batches.",
                accentColor: NSColor(deviceRed: 0.91, green: 0.86, blue: 0.79, alpha: 1)
            ),
            .init(
                path: "08-backup.png",
                frame: CGRect(x: 825, y: 355, width: 235, height: 510),
                rotationDegrees: -12,
                symbolName: "square.and.arrow.up",
                title: "Open export",
                subtitle: "Portable backups.",
                accentColor: NSColor(deviceRed: 0.87, green: 0.90, blue: 0.83, alpha: 1)
            ),
            .init(
                path: "02-container-detail.png",
                frame: CGRect(x: 1390, y: 405, width: 245, height: 535),
                rotationDegrees: 9,
                symbolName: "list.bullet.rectangle.portrait.fill",
                title: "Container detail",
                subtitle: "Contents, notes, QR, and more.",
                accentColor: NSColor(deviceRed: 0.86, green: 0.84, blue: 0.92, alpha: 1)
            ),
        ]
    ),
]

private func cgColor(_ color: NSColor) -> CGColor {
    color.usingColorSpace(.deviceRGB)!.cgColor
}

private func ensureDirectory(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

private func drawText(_ spec: TextSpec) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = spec.alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = spec.lineHeightMultiple

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: spec.fontSize, weight: spec.weight),
        .foregroundColor: spec.color,
        .paragraphStyle: paragraph,
        .kern: 0.1,
    ]

    NSAttributedString(string: spec.text, attributes: attributes).draw(in: spec.rect)
}

private func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

private func loadAppIcon() -> NSImage? {
    guard FileManager.default.fileExists(atPath: appIconURL.path) else {
        return nil
    }

    return NSImage(contentsOf: appIconURL)
}

private func loadImages() -> [String: NSImage] {
    var images: [String: NSImage] = [:]
    let uniquePaths = Set(assets.flatMap { $0.cards.map(\.path) })

    for path in uniquePaths {
        let sourceURL = rawScreensDirectory.appendingPathComponent(path)
        if let image = NSImage(contentsOf: sourceURL) {
            images[path] = image
        }
    }

    return images
}

private func drawBadge(in rect: CGRect) {
    let badgePath = roundedRectPath(rect, radius: rect.height / 2)
    NSColor.white.withAlphaComponent(0.78).setFill()
    badgePath.fill()

    drawText(
        .init(
            text: "BoxIndex",
            rect: CGRect(x: rect.minX, y: rect.minY - 4, width: rect.width, height: rect.height),
            fontSize: 42,
            weight: .bold,
            color: NSColor(deviceRed: 0.21, green: 0.34, blue: 0.23, alpha: 0.96),
            lineHeightMultiple: 1.0,
            alignment: .center
        )
    )
}

private func drawFeatures(in asset: SocialAsset) {
    for (index, feature) in features.enumerated() {
        let y = asset.featuresOrigin.y - (CGFloat(index) * asset.featureSpacing)
        let dotRect = CGRect(x: asset.featuresOrigin.x - 38, y: y + 10, width: 18, height: 18)
        let dotPath = roundedRectPath(dotRect, radius: 9)
        NSColor(deviceRed: 0.24, green: 0.44, blue: 0.25, alpha: 0.92).setFill()
        dotPath.fill()

        drawText(
            .init(
                text: feature,
                rect: CGRect(x: asset.featuresOrigin.x, y: y, width: asset.body.rect.width + 100, height: 42),
                fontSize: 33,
                weight: .semibold,
                color: NSColor(deviceWhite: 0.16, alpha: 0.92),
                lineHeightMultiple: 1.0,
                alignment: .left
            )
        )
    }
}

private func drawPanel(_ panel: PanelSpec, appIcon: NSImage?) {
    let panelPath = roundedRectPath(panel.panelRect, radius: 34)
    NSColor.white.withAlphaComponent(0.88).setFill()
    panelPath.fill()
    NSColor.white.withAlphaComponent(0.92).setStroke()
    panelPath.lineWidth = 1.5
    panelPath.stroke()

    drawText(panel.eyebrow)
    drawText(panel.title)
    drawText(panel.subtitle)
    drawText(panel.detail)

    let iconBackgroundRect = panel.iconRect.insetBy(dx: -10, dy: -10)
    let iconBackgroundPath = roundedRectPath(iconBackgroundRect, radius: 28)
    NSColor.white.withAlphaComponent(0.95).setFill()
    iconBackgroundPath.fill()

    if let appIcon {
        appIcon.draw(in: panel.iconRect)
    } else if let symbol = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: nil) {
        symbol.draw(in: panel.iconRect)
    }
}

private func drawScreenshotCard(image: NSImage, card: VisualCard, in context: CGContext) {
    let frame = card.frame
    let angle = card.rotationDegrees * .pi / 180

    context.saveGState()
    context.translateBy(x: frame.midX, y: frame.midY)
    context.rotate(by: angle)
    context.translateBy(x: -frame.midX, y: -frame.midY)

    let shadowRect = frame.offsetBy(dx: 0, dy: -24)
    let shadowPath = roundedRectPath(shadowRect, radius: 56)
    NSColor.black.withAlphaComponent(0.16).setFill()
    shadowPath.fill()

    let frameRect = frame.insetBy(dx: -18, dy: -18)
    let framePath = roundedRectPath(frameRect, radius: 62)
    NSColor.white.withAlphaComponent(0.92).setFill()
    framePath.fill()

    let clipPath = roundedRectPath(frame, radius: 48)
    clipPath.addClip()
    image.draw(in: frame)

    let highlightGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor.white.withAlphaComponent(0.22).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!

    context.drawLinearGradient(
        highlightGradient,
        start: CGPoint(x: frame.minX, y: frame.maxY),
        end: CGPoint(x: frame.minX, y: frame.maxY - 250),
        options: []
    )

    let borderPath = roundedRectPath(frame, radius: 48)
    NSColor.white.withAlphaComponent(0.75).setStroke()
    borderPath.lineWidth = 2.5
    borderPath.stroke()

    context.restoreGState()
}

private func drawPlaceholderCard(card: VisualCard, in context: CGContext) {
    let frame = card.frame
    let angle = card.rotationDegrees * .pi / 180

    context.saveGState()
    context.translateBy(x: frame.midX, y: frame.midY)
    context.rotate(by: angle)
    context.translateBy(x: -frame.midX, y: -frame.midY)

    let shadowRect = frame.offsetBy(dx: 0, dy: -24)
    let shadowPath = roundedRectPath(shadowRect, radius: 56)
    NSColor.black.withAlphaComponent(0.12).setFill()
    shadowPath.fill()

    let frameRect = frame.insetBy(dx: -18, dy: -18)
    let framePath = roundedRectPath(frameRect, radius: 62)
    NSColor.white.withAlphaComponent(0.92).setFill()
    framePath.fill()

    let cardPath = roundedRectPath(frame, radius: 48)
    cardPath.addClip()

    let backgroundGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            card.accentColor.withAlphaComponent(0.82).cgColor,
            NSColor.white.cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!

    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: frame.minX, y: frame.maxY),
        end: CGPoint(x: frame.maxX, y: frame.minY),
        options: []
    )

    context.setFillColor(NSColor.white.withAlphaComponent(0.22).cgColor)
    context.fillEllipse(
        in: CGRect(
            x: frame.minX - frame.width * 0.08,
            y: frame.maxY - frame.width * 0.28,
            width: frame.width * 0.42,
            height: frame.width * 0.42
        )
    )

    if let symbol = NSImage(systemSymbolName: card.symbolName, accessibilityDescription: nil) {
        let symbolRect = CGRect(
            x: frame.minX + frame.width * 0.20,
            y: frame.minY + frame.height * 0.46,
            width: frame.width * 0.60,
            height: frame.width * 0.60
        )
        symbol.draw(in: symbolRect)
    }

    drawText(
        .init(
            text: card.title,
            rect: CGRect(x: frame.minX + 34, y: frame.minY + 110, width: frame.width - 68, height: 54),
            fontSize: max(24, frame.width * 0.08),
            weight: .bold,
            color: NSColor(deviceWhite: 0.12, alpha: 1),
            lineHeightMultiple: 1.0,
            alignment: .center
        )
    )
    drawText(
        .init(
            text: card.subtitle,
            rect: CGRect(x: frame.minX + 36, y: frame.minY + 42, width: frame.width - 72, height: 56),
            fontSize: max(15, frame.width * 0.045),
            weight: .medium,
            color: NSColor(deviceWhite: 0.18, alpha: 0.74),
            lineHeightMultiple: 1.05,
            alignment: .center
        )
    )

    let borderPath = roundedRectPath(frame, radius: 48)
    NSColor.white.withAlphaComponent(0.80).setStroke()
    borderPath.lineWidth = 2.5
    borderPath.stroke()

    context.restoreGState()
}

private func render(asset: SocialAsset, images: [String: NSImage], appIcon: NSImage?) throws {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(asset.canvasSize.width),
            pixelsHigh: Int(asset.canvasSize.height),
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
        throw NSError(domain: "GenerateSocialCollage", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let context = graphicsContext.cgContext
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let backgroundGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            cgColor(asset.startColor),
            cgColor(asset.endColor),
        ] as CFArray,
        locations: [0, 1]
    )!

    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: 0, y: asset.canvasSize.height),
        end: CGPoint(x: asset.canvasSize.width, y: 0),
        options: []
    )

    let accentGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            NSColor(deviceRed: 0.23, green: 0.38, blue: 0.25, alpha: 0.18).cgColor,
            NSColor(deviceRed: 0.23, green: 0.38, blue: 0.25, alpha: 0.0).cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!

    context.drawRadialGradient(
        accentGradient,
        startCenter: asset.accentCenter,
        startRadius: 30,
        endCenter: asset.accentCenter,
        endRadius: asset.accentRadius,
        options: []
    )

    context.setFillColor(NSColor.white.cgColor)
    for ellipse in asset.ellipses {
        context.setAlpha(ellipse.alpha)
        context.fillEllipse(in: ellipse.rect)
    }
    context.setAlpha(1)

    drawBadge(in: asset.badgeRect)
    drawText(asset.headline)
    drawText(asset.body)
    drawFeatures(in: asset)

    for card in asset.cards {
        if let image = images[card.path] {
            drawScreenshotCard(image: image, card: card, in: context)
        } else {
            drawPlaceholderCard(card: card, in: context)
        }
    }

    drawPanel(asset.panel, appIcon: appIcon)

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateSocialCollage", code: 2)
    }

    let outputURL = outputDirectory.appendingPathComponent(asset.outputFileName)
    try pngData.write(to: outputURL)
    print("Generated \(outputURL.path)")
}

try ensureDirectory(marketingRoot)
try ensureDirectory(rawScreensDirectory)
try ensureDirectory(outputDirectory)

let images = loadImages()
let appIcon = loadAppIcon()
for asset in assets {
    try render(asset: asset, images: images, appIcon: appIcon)
}
