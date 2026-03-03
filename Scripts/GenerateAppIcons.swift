import AppKit

struct Palette {
    let background: NSColor
    let frame: NSColor
    let lid: NSColor
    let body: NSColor
    let label: NSColor
    let line: NSColor
    let lens: NSColor
}

let iconSetURL = URL(fileURLWithPath: "/Users/dpd/Documents/projects/github/BoxIndex/BoxIndex/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let canvasSize: CGFloat = 1_024

let palettes: [(String, Palette)] = [
    (
        "AppIcon-Light.png",
        Palette(
            background: NSColor(calibratedRed: 0.95, green: 0.92, blue: 0.86, alpha: 1.0),
            frame: NSColor(calibratedRed: 0.82, green: 0.76, blue: 0.67, alpha: 1.0),
            lid: NSColor(calibratedRed: 0.22, green: 0.29, blue: 0.36, alpha: 1.0),
            body: NSColor(calibratedRed: 0.16, green: 0.22, blue: 0.28, alpha: 1.0),
            label: NSColor(calibratedRed: 0.23, green: 0.58, blue: 0.62, alpha: 1.0),
            line: NSColor(calibratedRed: 0.92, green: 0.95, blue: 0.97, alpha: 1.0),
            lens: NSColor(calibratedRed: 0.91, green: 0.66, blue: 0.22, alpha: 1.0)
        )
    ),
    (
        "AppIcon-Dark.png",
        Palette(
            background: NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.18, alpha: 1.0),
            frame: NSColor(calibratedRed: 0.24, green: 0.28, blue: 0.32, alpha: 1.0),
            lid: NSColor(calibratedRed: 0.93, green: 0.94, blue: 0.95, alpha: 1.0),
            body: NSColor(calibratedRed: 0.82, green: 0.86, blue: 0.90, alpha: 1.0),
            label: NSColor(calibratedRed: 0.94, green: 0.63, blue: 0.24, alpha: 1.0),
            line: NSColor(calibratedRed: 0.20, green: 0.24, blue: 0.29, alpha: 1.0),
            lens: NSColor(calibratedRed: 0.31, green: 0.69, blue: 0.72, alpha: 1.0)
        )
    ),
    (
        "AppIcon-Tinted.png",
        Palette(
            background: NSColor(calibratedRed: 0.17, green: 0.41, blue: 0.46, alpha: 1.0),
            frame: NSColor(calibratedRed: 0.24, green: 0.55, blue: 0.60, alpha: 1.0),
            lid: NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.91, alpha: 1.0),
            body: NSColor(calibratedRed: 0.88, green: 0.92, blue: 0.85, alpha: 1.0),
            label: NSColor(calibratedRed: 0.94, green: 0.72, blue: 0.28, alpha: 1.0),
            line: NSColor(calibratedRed: 0.20, green: 0.32, blue: 0.35, alpha: 1.0),
            lens: NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        )
    ),
]

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawIcon(filename: String, palette: Palette) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize),
        pixelsHigh: Int(canvasSize),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "GenerateAppIcons", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap image rep."])
    }

    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "GenerateAppIcons", code: 2, userInfo: [NSLocalizedDescriptionKey: "No graphics context available."])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer { NSGraphicsContext.restoreGraphicsState() }

    let context = graphicsContext.cgContext

    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let backgroundRect = NSRect(x: 40, y: 40, width: canvasSize - 80, height: canvasSize - 80)
    let frameRect = NSRect(x: 72, y: 72, width: canvasSize - 144, height: canvasSize - 144)

    palette.background.setFill()
    roundedRect(backgroundRect, radius: 220).fill()

    palette.frame.setFill()
    roundedRect(frameRect, radius: 180).fill()

    let lidPath = NSBezierPath()
    lidPath.move(to: NSPoint(x: 252, y: 676))
    lidPath.line(to: NSPoint(x: 446, y: 796))
    lidPath.line(to: NSPoint(x: 772, y: 796))
    lidPath.line(to: NSPoint(x: 578, y: 676))
    lidPath.close()
    palette.lid.setFill()
    lidPath.fill()

    let bodyRect = NSRect(x: 226, y: 248, width: 572, height: 432)
    palette.body.setFill()
    roundedRect(bodyRect, radius: 86).fill()

    let topFacePath = NSBezierPath()
    topFacePath.move(to: NSPoint(x: 226, y: 636))
    topFacePath.line(to: NSPoint(x: 420, y: 748))
    topFacePath.line(to: NSPoint(x: 798, y: 748))
    topFacePath.line(to: NSPoint(x: 604, y: 636))
    topFacePath.close()
    palette.lid.withAlphaComponent(0.82).setFill()
    topFacePath.fill()

    let labelRect = NSRect(x: 286, y: 474, width: 314, height: 92)
    palette.label.setFill()
    roundedRect(labelRect, radius: 34).fill()

    let labelNotchRect = NSRect(x: 622, y: 452, width: 116, height: 136)
    palette.label.withAlphaComponent(0.92).setFill()
    roundedRect(labelNotchRect, radius: 40).fill()

    let lineRects = [
        NSRect(x: 302, y: 404, width: 320, height: 20),
        NSRect(x: 302, y: 358, width: 262, height: 20),
        NSRect(x: 302, y: 312, width: 290, height: 20),
    ]

    palette.line.setFill()
    for rect in lineRects {
        roundedRect(rect, radius: 10).fill()
    }

    let lensOuterRect = NSRect(x: 638, y: 338, width: 122, height: 122)
    let lensInnerRect = lensOuterRect.insetBy(dx: 24, dy: 24)
    let handleRect = NSRect(x: 730, y: 276, width: 28, height: 96)

    palette.lens.setFill()
    roundedRect(lensOuterRect, radius: 61).fill()

    palette.body.setFill()
    roundedRect(lensInnerRect, radius: 37).fill()

    let handlePath = NSBezierPath(roundedRect: handleRect, xRadius: 14, yRadius: 14)
    var transform = AffineTransform()
    let handleCenter = NSPoint(x: handleRect.midX, y: handleRect.midY)
    transform.translate(x: handleCenter.x, y: handleCenter.y)
    transform.rotate(byDegrees: -34)
    transform.translate(x: -handleCenter.x, y: -handleCenter.y)
    handlePath.transform(using: transform)
    palette.lens.setFill()
    handlePath.fill()

    let highlightRect = NSRect(x: 310, y: 510, width: 160, height: 18)
    palette.line.withAlphaComponent(0.85).setFill()
    roundedRect(highlightRect, radius: 9).fill()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateAppIcons", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG data."])
    }

    try pngData.write(to: iconSetURL.appendingPathComponent(filename), options: .atomic)
}

try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

for (filename, palette) in palettes {
    try drawIcon(filename: filename, palette: palette)
    print("Wrote \(filename)")
}
