import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

struct DesignSystem {
    // MARK: - Brand Colors (Black, Steel, Status)
    static let backgroundTop = Color(red: 0.035, green: 0.037, blue: 0.040)
    static let backgroundBottom = Color(red: 0.015, green: 0.016, blue: 0.018)
    static let panelTop = Color(red: 0.105, green: 0.112, blue: 0.122)
    static let panelBottom = Color(red: 0.075, green: 0.080, blue: 0.088)
    static let panelStroke = Color.white.opacity(0.12)

    static let primaryColor = Color(red: 0.72, green: 0.82, blue: 0.86) // cold steel
    static let successColor = Color(red: 0.12, green: 0.72, blue: 0.34)
    static let dangerColor = Color(red: 0.88, green: 0.18, blue: 0.16)
    static let warningColor = Color(red: 0.86, green: 0.70, blue: 0.24)
    static let secondaryColor = Color(red: 0.62, green: 0.66, blue: 0.70)

    static let primaryText = Color(red: 0.94, green: 0.95, blue: 0.96)
    static let mutedText = Color(red: 0.68, green: 0.71, blue: 0.74)
    static let edgeGlow = Color.clear

    // MARK: - Trading Colors
    static let bullishColor = successColor
    static let bearishColor = dangerColor
    static let neutralColor = secondaryColor

    // MARK: - Spacing
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 6
    static let largeCornerRadius: CGFloat = 8

    // MARK: - Typography
    struct Typography {
        static let heroFont = Font.system(size: 30, weight: .black, design: .default)
        static let titleFont = Font.system(size: 23, weight: .bold, design: .default)
        static let headlineFont = Font.system(size: 16, weight: .bold, design: .default)
        static let bodyFont = Font.system(size: 15, weight: .medium, design: .default)
        static let captionFont = Font.system(size: 13, weight: .semibold, design: .default)
        static let labelFont = Font.system(size: 11, weight: .black, design: .monospaced)
        static let monospacedFont = Font.system(size: 15, weight: .bold, design: .monospaced)
    }

    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.18)
    static let shadowRadius: CGFloat = 4

    // MARK: - Animation
    static let defaultAnimation = Animation.easeInOut(duration: 0.3)
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

struct TradingBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [DesignSystem.backgroundTop, DesignSystem.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
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
                    .fill(DesignSystem.panelTop)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.largeCornerRadius)
                    .stroke(DesignSystem.panelStroke, lineWidth: 1)
            )
            .shadow(color: DesignSystem.cardShadow, radius: DesignSystem.shadowRadius, x: 0, y: 2)
    }
}

extension View {
    func deskPanel(glow: Color = DesignSystem.edgeGlow.opacity(0.08), padding: CGFloat = DesignSystem.spacing) -> some View {
        modifier(DeskPanelModifier(glow: glow, padding: padding))
    }
}

struct InfoCard<Content: View>: View {
    let glow: Color
    let content: Content

    init(glow: Color = DesignSystem.edgeGlow.opacity(0.08), @ViewBuilder content: () -> Content) {
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
                .tracking(1.2)
                .foregroundColor(DesignSystem.mutedText)
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
                .tracking(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(accent.opacity(0.14))
        .overlay(
            Capsule().stroke(accent.opacity(0.35), lineWidth: 1)
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
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.24),
                            secondaryAccent.opacity(0.10),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accent.opacity(0.28), lineWidth: 1)
                )
                .frame(width: 54, height: 54)

            Text(symbol)
                .font(DesignSystem.Typography.headlineFont)
                .kerning(0.6)
                .foregroundColor(DesignSystem.primaryText)

            DeskPulseDot(accent: accent, size: 7)
                .offset(x: 4, y: -4)
        }
        .shadow(color: accent.opacity(0.20), radius: 10, x: 0, y: 6)
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
                Capsule()
                    .fill(Color.white.opacity(0.06))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.75), accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(12, geometry.size.width * clampedValue))
            }
        }
        .frame(height: 6)
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
            case .primary: return DesignSystem.primaryColor
            case .secondary: return DesignSystem.secondaryColor
            case .danger: return DesignSystem.dangerColor
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .danger: return .white
            case .secondary: return DesignSystem.primaryText
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(style.foregroundColor)
                .textCase(.uppercase)
                .tracking(0.8)
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
            case .up: return DesignSystem.bullishColor
            case .down: return DesignSystem.bearishColor
            case .flat: return DesignSystem.neutralColor
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
                .foregroundColor(trend?.color ?? DesignSystem.primaryText)

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
    var primaryAccent: Color = DesignSystem.primaryColor
    var bullishAccent: Color = DesignSystem.bullishColor
    var bearishAccent: Color = DesignSystem.bearishColor

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.panelTop,
                            Color.black,
                            DesignSystem.panelBottom
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(primaryAccent.opacity(0.4), lineWidth: size * 0.02)

            // Sharp industrial elements
            Rectangle()
                .fill(primaryAccent.opacity(0.1))
                .frame(width: size, height: 1)
                .offset(y: -size * 0.1)
            
            Rectangle()
                .fill(primaryAccent.opacity(0.1))
                .frame(width: 1, height: size)
                .offset(x: size * 0.1)

            Capsule(style: .continuous)
                .fill(primaryAccent)
                .frame(width: size * 0.7, height: size * 0.08)
                .rotationEffect(.degrees(-45))
                .shadow(color: primaryAccent.opacity(0.5), radius: size * 0.05)

            Text("STEEL")
                .font(.system(size: size * 0.16, weight: .black, design: .monospaced))
                .foregroundColor(DesignSystem.primaryText)
                .offset(y: size * 0.25)

            Circle()
                .fill(primaryAccent)
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(x: size * 0.35, y: -size * 0.35)
                .shadow(color: primaryAccent, radius: 8)
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
                .fontWeight(.black)
                .tracking(1.5)
                .foregroundColor(DesignSystem.primaryText)
            Text(subtitle.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(2.0)
                .foregroundColor(DesignSystem.primaryColor)
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
                    .scaleEffect(reveal ? 1 : 0.9)
                    .opacity(reveal ? 1 : 0)

                SteelDeskWordmark(
                    alignment: .center,
                    title: "STEEL TRADING DESK",
                    subtitle: "Open first. Close honest."
                )
                .multilineTextAlignment(.center)
                .opacity(reveal ? 1 : 0)
                .offset(y: reveal ? 0 : 10)

                VStack(spacing: 8) {
                    launchLine("AGGRESSIVE TAPE READING")
                    launchLine("INSTITUTIONAL FLOW ONLY")
                }
                .opacity(tagLineVisible ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                reveal = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                tagLineVisible = true
            }
        }
    }

    private func launchLine(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.captionFont)
            .fontWeight(.bold)
            .tracking(1.5)
            .foregroundColor(DesignSystem.primaryColor)
    }
}

#if canImport(AppKit)
enum BrandIconFactory {
    static func makeDockIcon(size: CGFloat = 512) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let background = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
        let backgroundGradient = NSGradient(
            colors: [
                NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.11, alpha: 1),
                NSColor(calibratedRed: 0.02, green: 0.02, blue: 0.02, alpha: 1),
                NSColor(calibratedRed: 0.06, green: 0.06, blue: 0.07, alpha: 1)
            ]
        )
        backgroundGradient?.draw(in: background, angle: 300)

        NSColor(calibratedRed: 0.00, green: 0.95, blue: 1.00, alpha: 0.4).setStroke()
        background.lineWidth = size * 0.02
        background.stroke()

        // Industrial crosshairs
        let lineLength = size * 0.1
        let horizontal = NSBezierPath()
        horizontal.move(to: NSPoint(x: size * 0.5 - lineLength, y: size * 0.5))
        horizontal.line(to: NSPoint(x: size * 0.5 + lineLength, y: size * 0.5))
        let vertical = NSBezierPath()
        vertical.move(to: NSPoint(x: size * 0.5, y: size * 0.5 - lineLength))
        vertical.line(to: NSPoint(x: size * 0.5, y: size * 0.5 + lineLength))
        
        NSColor(calibratedRed: 0.00, green: 0.95, blue: 1.00, alpha: 0.15).setStroke()
        horizontal.lineWidth = 1
        vertical.lineWidth = 1
        horizontal.stroke()
        vertical.stroke()

        drawSlash(
            center: CGPoint(x: size * 0.5, y: size * 0.5),
            length: size * 0.7,
            thickness: size * 0.08,
            angle: -45,
            color: NSColor(calibratedRed: 0.00, green: 0.95, blue: 1.00, alpha: 1)
        )

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let title = "STEEL" as NSString
        let titleRect = NSRect(x: 0, y: size * 0.15, width: size, height: size * 0.15)
        title.draw(
            in: titleRect,
            withAttributes: [
                .font: NSFont.monospacedSystemFont(ofSize: size * 0.1, weight: .black),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraph
            ]
        )

        let pulseRect = NSRect(x: size * 0.8, y: size * 0.8, width: size * 0.08, height: size * 0.08)
        let pulse = NSBezierPath(ovalIn: pulseRect)
        NSColor(calibratedRed: 0.00, green: 0.95, blue: 1.00, alpha: 1).setFill()
        pulse.fill()

        image.unlockFocus()
        return image
    }

    private static func drawSlash(center: CGPoint, length: CGFloat, thickness: CGFloat, angle: CGFloat, color: NSColor) {
        let path = NSBezierPath(
            roundedRect: NSRect(
                x: center.x - length / 2,
                y: center.y - thickness / 2,
                width: length,
                height: thickness
            ),
            xRadius: thickness / 2,
            yRadius: thickness / 2
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
