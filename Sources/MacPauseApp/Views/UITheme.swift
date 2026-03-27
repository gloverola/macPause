import SwiftUI

enum MacPauseTheme {
    static let ink = Color(hex: 0xEDF1F5)
    static let inkMuted = Color(hex: 0xA0A8B3)
    static let aqua = Color(hex: 0x8EBBFF)
    static let aquaStrong = Color(hex: 0x5E93D9)
    static let success = Color(hex: 0x85B488)
    static let warning = Color(hex: 0xD3A55B)
    static let chromeLine = Color.white.opacity(0.14)
    static let chromeHighlight = Color.white.opacity(0.10)
    static let separator = Color.white.opacity(0.09)
    static let insetLine = Color.black.opacity(0.38)

    static let permissionBackground = LinearGradient(
        colors: [
            Color(hex: 0x1C2128),
            Color(hex: 0x11151A)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let chromeFill = LinearGradient(
        colors: [
            Color(hex: 0x363D46),
            Color(hex: 0x272D35),
            Color(hex: 0x1A1F26)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let panelFill = LinearGradient(
        colors: [
            Color(hex: 0x303740),
            Color(hex: 0x20262D)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let insetFill = LinearGradient(
        colors: [
            Color(hex: 0x1A2026),
            Color(hex: 0x0F1318)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let buttonFill = LinearGradient(
        colors: [
            Color(hex: 0x434C57),
            Color(hex: 0x2B3138)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let buttonPressedFill = LinearGradient(
        colors: [
            Color(hex: 0x242A31),
            Color(hex: 0x3C444E)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let primaryButtonFill = LinearGradient(
        colors: [
            Color(hex: 0x7EA7DF),
            Color(hex: 0x3E70B1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let primaryButtonPressedFill = LinearGradient(
        colors: [
            Color(hex: 0x4F7EBC),
            Color(hex: 0x7198CF)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let overlayBackground = LinearGradient(
        colors: [
            Color(hex: 0x12161B, opacity: 0.97),
            Color(hex: 0x080A0D, opacity: 0.99)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let hudFill = LinearGradient(
        colors: [
            Color(hex: 0x323941, opacity: 0.97),
            Color(hex: 0x1C2229, opacity: 0.97)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let progressTrack = LinearGradient(
        colors: [
            Color(hex: 0x20262D),
            Color(hex: 0x12171C)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension View {
    func macPauseSurface(
        cornerRadius: CGFloat = 10,
        fill: LinearGradient = MacPauseTheme.panelFill,
        stroke: Color = MacPauseTheme.chromeLine
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(stroke, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(MacPauseTheme.chromeHighlight, lineWidth: 0.8)
                        .padding(0.5)
                )
        )
    }

    func macPauseInsetSurface(cornerRadius: CGFloat = 8) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(MacPauseTheme.insetFill)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(MacPauseTheme.insetLine, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        .padding(0.5)
                )
        )
    }
}

enum MacPauseButtonKind {
    case secondary
    case primary
}

struct MacPauseBezelButtonStyle: ButtonStyle {
    let kind: MacPauseButtonKind

    init(kind: MacPauseButtonKind = .secondary) {
        self.kind = kind
    }

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(backgroundFill(isPressed: configuration.isPressed))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(borderColor(isPressed: configuration.isPressed), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(kind == .primary ? 0.22 : 0.10), lineWidth: 0.8)
                            .padding(0.5)
                    )
            )
            .opacity(isEnabled ? 1 : 0.58)
            .offset(y: configuration.isPressed ? 0.5 : 0)
    }

    private var foregroundColor: Color {
        if kind == .primary {
            return .white
        }

        return MacPauseTheme.ink
    }

    private func backgroundFill(isPressed: Bool) -> LinearGradient {
        switch kind {
        case .secondary:
            return isPressed ? MacPauseTheme.buttonPressedFill : MacPauseTheme.buttonFill
        case .primary:
            return isPressed ? MacPauseTheme.primaryButtonPressedFill : MacPauseTheme.primaryButtonFill
        }
    }

    private func borderColor(isPressed: Bool) -> Color {
        switch kind {
        case .secondary:
            return MacPauseTheme.chromeLine.opacity(isPressed ? 0.9 : 0.78)
        case .primary:
            return MacPauseTheme.aquaStrong.opacity(isPressed ? 1 : 0.9)
        }
    }
}

struct MacPauseKeyCap: View {
    let title: String
    var minWidth: CGFloat = 34

    var body: some View {
        Text(title)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(MacPauseTheme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minWidth: minWidth)
            .macPauseInsetSurface(cornerRadius: 6)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
