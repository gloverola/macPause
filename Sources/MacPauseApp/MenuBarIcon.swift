import AppKit

enum MenuBarIconState {
    case ready
    case arming
    case active
    case warning
}

enum MenuBarIcon {
    static func image(for state: MenuBarIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            drawPauseBars()
            drawSparkle(state: state)
            drawBadge(state: state)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawPauseBars() {
        NSColor.labelColor.setFill()

        NSBezierPath(
            roundedRect: NSRect(x: 4.2, y: 3.6, width: 3.0, height: 10.4),
            xRadius: 1.5,
            yRadius: 1.5
        ).fill()

        NSBezierPath(
            roundedRect: NSRect(x: 9.2, y: 3.6, width: 3.0, height: 10.4),
            xRadius: 1.5,
            yRadius: 1.5
        ).fill()
    }

    private static func drawSparkle(state: MenuBarIconState) {
        let outerRadius: CGFloat = state == .active ? 2.4 : 2.0
        let innerRadius: CGFloat = state == .active ? 0.9 : 0.75
        let center = NSPoint(x: 13.5, y: 13.3)
        let path = NSBezierPath()

        for index in 0..<8 {
            let angle = (CGFloat(index) * (.pi / 4)) - (.pi / 2)
            let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = NSPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }
        }

        path.close()
        path.fill()
    }

    private static func drawBadge(state: MenuBarIconState) {
        switch state {
        case .ready:
            break
        case .arming:
            NSBezierPath(
                ovalIn: NSRect(x: 7.2, y: 1.6, width: 3.2, height: 3.2)
            ).fill()
        case .active:
            NSBezierPath(
                roundedRect: NSRect(x: 5.2, y: 1.5, width: 6.6, height: 2.4),
                xRadius: 1.2,
                yRadius: 1.2
            ).fill()
        case .warning:
            NSBezierPath(
                roundedRect: NSRect(x: 12.6, y: 1.7, width: 1.8, height: 4.8),
                xRadius: 0.9,
                yRadius: 0.9
            ).fill()
            NSBezierPath(
                ovalIn: NSRect(x: 12.75, y: 0.2, width: 1.5, height: 1.5)
            ).fill()
        }
    }
}
