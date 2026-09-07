import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

struct DesignSystem {
    // MARK: - Boiler-Room Palette
    //
    // CRT phosphor amber on near-black ground. Hex source: CLAUDE_CODE_DIRECTIONS.md.
    // Legacy token names below are aliases preserved for Phase 1 — call sites are
    // collapsed to the canonical names in later phases.

    static let bg = Color.black                                          // #000000
    static let bg1 = Color(red: 0.0196, green: 0.0196, blue: 0.0196)     // #050505 sidebars
    static let panel = Color(red: 0.0392, green: 0.0392, blue: 0.0392)   // #0a0a0a cards
    static let hairline = Color(red: 0.1020, green: 0.1020, blue: 0.1020) // #1a1a1a borders
    static let amber = Color(red: 1.0, green: 0.6902, blue: 0.0)         // #FFB000 primary
    static let long = Color(red: 0.0, green: 0.8235, blue: 0.4157)       // #00D26A pass / win
    static let short = Color(red: 1.0, green: 0.2196, blue: 0.2196)      // #FF3838 fail / loss
    static let vwap = Color(red: 0.4039, green: 0.8510, blue: 1.0)       // #67D9FF chart only
    static let steel = Color(red: 0.4863, green: 0.5412, blue: 0.6)      // #7C8A99 neutral
    static let text = Color(red: 0.9098, green: 0.9098, blue: 0.9098)    // #E8E8E8
    static let text2 = Color(red: 0.6588, green: 0.6588, blue: 0.6588)   // #A8A8A8
    static let muted = Color(red: 0.4157, green: 0.4157, blue: 0.4157)   // #6A6A6A
    static let faint = Color(red: 0.2275, green: 0.2275, blue: 0.2275)   // #3A3A3A

    // MARK: - Legacy aliases (token-swap compatibility shims)
    static let backgroundTop = bg
    static let backgroundBottom = bg
    static let panelTop = panel
    static let panelBottom = panel
    static let panelStroke = hairline

    static let primaryColor = amber
    static let successColor = long
    static let dangerColor = short
    static let warningColor = amber
    static let secondaryColor = steel

    static let primaryText = text
    static let mutedText = muted
    static let edgeGlow = Color.clear

    static let bullishColor = long
    static let bearishColor = short
    static let neutralColor = steel

    // MARK: - Spacing
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24

    // MARK: - Corner Radius
    // Boiler-room corners: sharp. 2pt everywhere; 0 acceptable for industrial bars.
    static let cornerRadius: CGFloat = 2
    static let smallCornerRadius: CGFloat = 2
    static let largeCornerRadius: CGFloat = 2

    // MARK: - Typography
    //
    // Bundled: IBM Plex Sans (Regular + SemiBold), Sans Condensed (Bold),
    // Mono (Regular + SemiBold). System fallback retained per-family in case
    // the .ttf registration fails on a given build.
    struct Typography {
        static let useSansFallback = false
        static let useMonoFallback = false

        private static func isHeavy(_ weight: Font.Weight) -> Bool {
            switch weight {
            case .semibold, .bold, .heavy, .black: return true
            default: return false
            }
        }

        private static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            if useSansFallback {
                return .system(size: size, weight: weight, design: .default)
            }
            return Font.custom(isHeavy(weight) ? "IBMPlexSans-SemiBold" : "IBMPlexSans-Regular", size: size)
        }

        private static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
            if useSansFallback {
                return .system(size: size, weight: weight, design: .default).width(.condensed)
            }
            // Only Bold of Condensed is bundled; that's the heaviest in the
            // standard Plex distribution and reads correctly for the hero verb.
            return Font.custom("IBMPlexSansCondensed-Bold", size: size)
        }

        private static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            if useMonoFallback {
                return .system(size: size, weight: weight, design: .monospaced)
            }
            return Font.custom(isHeavy(weight) ? "IBMPlexMono-SemiBold" : "IBMPlexMono-Regular", size: size)
        }

        // Hero command verb ("NO TRADE.", "CLOSE IT.")
        static let heroFont = display(36, weight: .heavy)
        // Section titles
        static let titleFont = display(22, weight: .bold)
        // Card headers
        static let headlineFont = sans(16, weight: .semibold)
        // Body copy
        static let bodyFont = sans(13, weight: .regular)
        // Inline numeric / dense readouts
        static let captionFont = mono(12, weight: .semibold)
        // Tiny uppercase labels — apply .tracking(1.4) at the call site
        static let labelFont = mono(10, weight: .semibold)
        // Settings screen only: labelFont/captionFont read too small on a
        // dense, text-heavy settings page (especially on a high-res external
        // display). A couple points larger, same family/weight.
        static let settingsLabelFont = mono(12, weight: .semibold)
        static let settingsValueFont = mono(14, weight: .semibold)
        // Primary number readouts (price, ratio)
        static let monospacedFont = mono(15, weight: .semibold)
    }

    // MARK: - Shadows
    // Boiler-room: flat panels with hairline borders. Phase 2 kills shadow modifiers
    // at every call site; this stays neutral so the swap is one place to flip.
    static let cardShadow = Color.clear
    static let shadowRadius: CGFloat = 0

    // MARK: - Animation
    static let defaultAnimation = Animation.easeInOut(duration: 0.2)
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.85)
}

struct TradingBackdrop: View {
    var body: some View {
        DesignSystem.bg
            .ignoresSafeArea()
    }
}

private struct DeskPanelModifier: ViewModifier {
    let glow: Color
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.largeCornerRadius)
                    .fill(DesignSystem.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.largeCornerRadius)
                    .stroke(DesignSystem.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func deskPanel(glow: Color = DesignSystem.edgeGlow, padding: CGFloat = DesignSystem.spacing) -> some View {
        modifier(DeskPanelModifier(glow: glow, padding: padding))
    }
}

struct InfoCard<Content: View>: View {
    let glow: Color
    let content: Content

    init(glow: Color = DesignSystem.edgeGlow, @ViewBuilder content: () -> Content) {
        self.glow = glow
        self.content = content()
    }

    var body: some View {
        content
            .deskPanel(glow: glow)
    }
}

struct DeskSectionHeader: View {
    let title: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(accent)
            Text(title.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.4)
                .foregroundColor(DesignSystem.muted)
            Spacer()
        }
    }
}

struct DeskCountBadge: View {
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            DeskPulseDot(accent: accent, size: 6)
            Text(value)
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(accent.opacity(0.10))
        .overlay(
            Capsule().stroke(accent.opacity(0.4), lineWidth: 1)
        )
        .clipShape(Capsule())
        .foregroundColor(accent)
    }
}

struct DeskPulseDot: View {
    let accent: Color
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(accent)
            .frame(width: size, height: size)
    }
}

struct DeskSignalGlyph: View {
    let symbol: String
    let accent: Color
    let secondaryAccent: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.bg1)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(accent.opacity(0.5), lineWidth: 1)
                )
                .frame(width: 54, height: 54)

            Text(symbol)
                .font(DesignSystem.Typography.headlineFont)
                .kerning(0.6)
                .foregroundColor(DesignSystem.text)

            DeskPulseDot(accent: accent, size: 7)
                .offset(x: 4, y: -4)
        }
    }
}

struct DeskMeterBar: View {
    let value: Double
    let accent: Color

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(DesignSystem.faint)

                Rectangle()
                    .fill(accent)
                    .frame(width: max(2, geometry.size.width * clampedValue))
            }
        }
        .frame(height: 4)
    }
}

struct StandardButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle

    enum ButtonStyle {
        case primary, secondary, danger

        var backgroundColor: Color {
            switch self {
            case .primary: return DesignSystem.amber
            case .secondary: return DesignSystem.steel
            case .danger: return DesignSystem.short
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .danger: return .black
            case .secondary: return DesignSystem.text
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(style.foregroundColor)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.horizontal, DesignSystem.spacing)
                .padding(.vertical, DesignSystem.smallSpacing)
                .background(style.backgroundColor)
                .cornerRadius(DesignSystem.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PriceDisplay: View {
    let price: Double
    let trend: PriceTrend?

    enum PriceTrend {
        case up, down, flat

        var color: Color {
            switch self {
            case .up: return DesignSystem.long
            case .down: return DesignSystem.short
            case .flat: return DesignSystem.steel
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .flat: return "minus"
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("$\(price, specifier: "%.2f")")
                .font(DesignSystem.Typography.monospacedFont)
                .foregroundColor(trend?.color ?? DesignSystem.text)

            if let trend = trend {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
        }
    }
}

struct SteelDeskMark: View {
    var size: CGFloat = 72
    var primaryAccent: Color = DesignSystem.amber
    var bullishAccent: Color = DesignSystem.long
    var bearishAccent: Color = DesignSystem.short

    var body: some View {
        ZStack {
            Rectangle()
                .fill(DesignSystem.bg)

            Rectangle()
                .stroke(primaryAccent, lineWidth: 1)

            // Industrial crosshairs
            Rectangle()
                .fill(primaryAccent.opacity(0.20))
                .frame(width: size, height: 1)
                .offset(y: -size * 0.1)

            Rectangle()
                .fill(primaryAccent.opacity(0.20))
                .frame(width: 1, height: size)
                .offset(x: size * 0.1)

            Rectangle()
                .fill(primaryAccent)
                .frame(width: size * 0.7, height: size * 0.06)
                .rotationEffect(.degrees(-45))

            Text("STEEL")
                .font(.system(size: size * 0.16, weight: .heavy, design: .monospaced))
                .foregroundColor(DesignSystem.text)
                .offset(y: size * 0.25)

            Rectangle()
                .fill(primaryAccent)
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(x: size * 0.35, y: -size * 0.35)
        }
        .frame(width: size, height: size)
    }
}

struct SteelDeskWordmark: View {
    var alignment: HorizontalAlignment = .leading
    var title: String = "STEEL TRADING DESK"
    var subtitle: String = "No fantasy fills."

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(DesignSystem.Typography.titleFont)
                .tracking(1.5)
                .foregroundColor(DesignSystem.text)
            Text(subtitle.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(2.0)
                .foregroundColor(DesignSystem.amber)
        }
    }
}

struct LaunchOverlayView: View {
    @State private var reveal = false
    @State private var tagLineVisible = false

    var body: some View {
        ZStack {
            TradingBackdrop()

            VStack(spacing: 24) {
                SteelDeskMark(size: 120)
                    .scaleEffect(reveal ? 1 : 0.96)
                    .opacity(reveal ? 1 : 0)

                SteelDeskWordmark(
                    alignment: .center,
                    title: "STEEL TRADING DESK",
                    subtitle: "Open first. Close honest."
                )
                .multilineTextAlignment(.center)
                .opacity(reveal ? 1 : 0)
                .offset(y: reveal ? 0 : 6)

                VStack(spacing: 8) {
                    launchLine("AGGRESSIVE TAPE READING")
                    launchLine("INSTITUTIONAL FLOW ONLY")
                }
                .opacity(tagLineVisible ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                reveal = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.15)) {
                tagLineVisible = true
            }
        }
    }

    private func launchLine(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.labelFont)
            .tracking(1.5)
            .foregroundColor(DesignSystem.amber)
    }
}

#if canImport(AppKit)
enum BrandIconFactory {
    static func makeDockIcon(size: CGFloat = 512) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let amber = NSColor(calibratedRed: 1.0, green: 0.6902, blue: 0.0, alpha: 1)
        let amberFaint = NSColor(calibratedRed: 1.0, green: 0.6902, blue: 0.0, alpha: 0.20)

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let background = NSBezierPath(rect: rect)
        NSColor.black.setFill()
        background.fill()

        amber.setStroke()
        background.lineWidth = max(1, size * 0.005)
        background.stroke()

        let lineLength = size * 0.1
        let horizontal = NSBezierPath()
        horizontal.move(to: NSPoint(x: size * 0.5 - lineLength, y: size * 0.5))
        horizontal.line(to: NSPoint(x: size * 0.5 + lineLength, y: size * 0.5))
        let vertical = NSBezierPath()
        vertical.move(to: NSPoint(x: size * 0.5, y: size * 0.5 - lineLength))
        vertical.line(to: NSPoint(x: size * 0.5, y: size * 0.5 + lineLength))

        amberFaint.setStroke()
        horizontal.lineWidth = 1
        vertical.lineWidth = 1
        horizontal.stroke()
        vertical.stroke()

        drawSlash(
            center: CGPoint(x: size * 0.5, y: size * 0.5),
            length: size * 0.7,
            thickness: size * 0.06,
            angle: -45,
            color: amber
        )

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let title = "STEEL" as NSString
        let titleRect = NSRect(x: 0, y: size * 0.15, width: size, height: size * 0.15)
        title.draw(
            in: titleRect,
            withAttributes: [
                .font: NSFont.monospacedSystemFont(ofSize: size * 0.1, weight: .heavy),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraph
            ]
        )

        let pulseRect = NSRect(x: size * 0.8, y: size * 0.8, width: size * 0.08, height: size * 0.08)
        let pulse = NSBezierPath(rect: pulseRect)
        amber.setFill()
        pulse.fill()

        image.unlockFocus()
        return image
    }

    private static func drawSlash(center: CGPoint, length: CGFloat, thickness: CGFloat, angle: CGFloat, color: NSColor) {
        let path = NSBezierPath(
            rect: NSRect(
                x: center.x - length / 2,
                y: center.y - thickness / 2,
                width: length,
                height: thickness
            )
        )

        var transform = AffineTransform()
        transform.translate(x: center.x, y: center.y)
        transform.rotate(byDegrees: angle)
        transform.translate(x: -center.x, y: -center.y)
        path.transform(using: transform)

        color.setFill()
        path.fill()
    }
}
#endif
