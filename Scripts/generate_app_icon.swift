import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let supportURL = rootURL.appendingPathComponent("Support", isDirectory: true)
let outputICNSURL = supportURL.appendingPathComponent("AppIcon.icns")
let previewURL = supportURL.appendingPathComponent("AppIconPreview.png")
let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("macpause-icon-\(UUID().uuidString)", isDirectory: true)
let masterPNGURL = tempURL.appendingPathComponent("AppIcon-master.png")
let iconResourceURL = tempURL.appendingPathComponent("AppIcon.rsrc")
let sourcePNGURL = tempURL.appendingPathComponent("AppIcon-source.png")

try? FileManager.default.removeItem(at: tempURL)
try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)

func makeImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let inset = size * 0.06
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let corner = size * 0.225

    NSColor(calibratedWhite: 0.06, alpha: 1).setFill()
    rect.fill()

    let shadow = NSShadow()
    shadow.shadowBlurRadius = size * 0.045
    shadow.shadowOffset = NSSize(width: 0, height: -(size * 0.025))
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.45)
    shadow.set()

    let basePath = NSBezierPath(roundedRect: iconRect, xRadius: corner, yRadius: corner)
    let baseGradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.19, green: 0.20, blue: 0.23, alpha: 1),
            NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.11, alpha: 1)
        ]
    )!
    baseGradient.draw(in: basePath, angle: -90)

    NSGraphicsContext.current?.saveGraphicsState()
    basePath.addClip()

    let glossRect = NSRect(
        x: iconRect.minX,
        y: iconRect.midY - (size * 0.03),
        width: iconRect.width,
        height: iconRect.height * 0.52
    )
    let glossPath = NSBezierPath(roundedRect: glossRect, xRadius: corner * 0.9, yRadius: corner * 0.9)
    let glossGradient = NSGradient(
        colors: [
            NSColor(calibratedWhite: 1, alpha: 0.28),
            NSColor(calibratedWhite: 1, alpha: 0.08),
            NSColor(calibratedWhite: 1, alpha: 0)
        ]
    )!
    glossGradient.draw(in: glossPath, angle: -90)

    let ringRect = iconRect.insetBy(dx: size * 0.12, dy: size * 0.12)
    let ringPath = NSBezierPath(ovalIn: ringRect)
    NSColor(calibratedWhite: 1, alpha: 0.08).setStroke()
    ringPath.lineWidth = max(1, size * 0.018)
    ringPath.stroke()

    let aquaRect = iconRect.insetBy(dx: size * 0.20, dy: size * 0.20)
    let aquaPath = NSBezierPath(ovalIn: aquaRect)
    let aquaGradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.59, green: 0.92, blue: 1.0, alpha: 1),
            NSColor(calibratedRed: 0.14, green: 0.58, blue: 0.98, alpha: 1)
        ]
    )!
    aquaGradient.draw(in: aquaPath, relativeCenterPosition: .zero)

    let aquaHighlight = NSBezierPath(ovalIn: aquaRect.insetBy(dx: size * 0.02, dy: size * 0.02))
    NSColor(calibratedWhite: 1, alpha: 0.17).setStroke()
    aquaHighlight.lineWidth = max(1, size * 0.01)
    aquaHighlight.stroke()

    let barWidth = aquaRect.width * 0.14
    let barHeight = aquaRect.height * 0.48
    let barSpacing = aquaRect.width * 0.10
    let barRadius = barWidth * 0.45
    let leftX = aquaRect.midX - barSpacing / 2 - barWidth
    let rightX = aquaRect.midX + barSpacing / 2
    let barY = aquaRect.midY - barHeight / 2

    let barColor = NSColor(calibratedWhite: 1, alpha: 0.95)
    barColor.setFill()
    NSBezierPath(
        roundedRect: NSRect(x: leftX, y: barY, width: barWidth, height: barHeight),
        xRadius: barRadius,
        yRadius: barRadius
    ).fill()
    NSBezierPath(
        roundedRect: NSRect(x: rightX, y: barY, width: barWidth, height: barHeight),
        xRadius: barRadius,
        yRadius: barRadius
    ).fill()

    let lowerReflectionRect = NSRect(
        x: iconRect.minX + size * 0.12,
        y: iconRect.minY + size * 0.13,
        width: iconRect.width * 0.76,
        height: iconRect.height * 0.22
    )
    let lowerReflection = NSBezierPath(roundedRect: lowerReflectionRect, xRadius: size * 0.08, yRadius: size * 0.08)
    let reflectionGradient = NSGradient(
        colors: [
            NSColor(calibratedWhite: 1, alpha: 0.13),
            NSColor(calibratedWhite: 1, alpha: 0)
        ]
    )!
    reflectionGradient.draw(in: lowerReflection, angle: 90)

    NSGraphicsContext.current?.restoreGraphicsState()

    let strokePath = NSBezierPath(roundedRect: iconRect, xRadius: corner, yRadius: corner)
    NSColor(calibratedWhite: 1, alpha: 0.12).setStroke()
    strokePath.lineWidth = max(1, size * 0.01)
    strokePath.stroke()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "MacPauseIcon", code: 1)
    }

    try pngData.write(to: url)
}

func runProcess(_ launchPath: String, _ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw NSError(domain: "MacPauseIcon", code: Int(process.terminationStatus))
    }
}

func shellQuote(_ path: String) -> String {
    "'\(path.replacingOccurrences(of: "'", with: "'\\''"))'"
}

let masterImage = makeImage(size: 1024)
try writePNG(masterImage, to: masterPNGURL)

try runProcess(
    "/usr/bin/sips",
    [
        "-z",
        "512",
        "512",
        masterPNGURL.path,
        "--out",
        previewURL.path
    ]
)

try runProcess(
    "/usr/bin/sips",
    ["-i", masterPNGURL.path]
)

try runProcess(
    "/bin/zsh",
    [
        "-lc",
        """
        cp \(shellQuote(previewURL.path)) \(shellQuote(sourcePNGURL.path))
        sips -i \(shellQuote(sourcePNGURL.path))
        DeRez -only icns \(shellQuote(sourcePNGURL.path)) > \(shellQuote(iconResourceURL.path))
        Rez -append \(shellQuote(iconResourceURL.path)) -o \(shellQuote(outputICNSURL.path))
        """
    ]
)

try? FileManager.default.removeItem(at: tempURL)
print("Wrote \(outputICNSURL.path)")
