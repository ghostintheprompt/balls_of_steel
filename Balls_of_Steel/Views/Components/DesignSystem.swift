import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

struct DesignSystem {
    // MARK: - Brand Colors
    static let backgroundTop = Color(red: 0.07, green: 0.05, blue: 0.04)
    static let backgroundBottom = Color(red: 0.12, green: 0.09, blue: 0.07)
    static let panelTop = Color(red: 0.20, green: 0.15, blue: 0.11)
    static let panelBottom = Color(red: 0.11, green: 0.08, blue: 0.07)
    static let panelStroke = Color.white.opacity(0.08)

    static let primaryColor = Color(red: 0.84, green: 0.68, blue: 0.43)
    static let successColor = Color(red: 0.43, green: 0.95, blue: 0.58)
    static let dangerColor = Color(red: 0.97, green: 0.40, blue: 0.30)
    static let warningColor = Color(red: 0.95, green: 0.71, blue: 0.28)
    static let secondaryColor = Color(red: 0.58, green: 0.53, blue: 0.49)

    static let primaryText = Color(red: 0.95, green: 0.92, blue: 0.88)
    static let mutedText = Color(red: 0.70, green: 0.65, blue: 0.60)
    static let edgeGlow = Color(red: 0.97, green: 0.71, blue: 0.28)

    // MARK: - Trading Colors
    static let bullishColor = Color(red: 0.45, green: 0.96, blue: 0.60)
    static let bearishColor = Color(red: 0.99, green: 0.43, blue: 0.34)
    static let neutralColor = Color(red: 0.84, green: 0.68, blue: 0.43)

    // MARK: - Spacing
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 16

    // MARK: - Typography
    struct Typography {
        static let heroFont = Font.system(size: 28, weight: .semibold, design: .serif)
        static let titleFont = Font.system(size: 21, weight: .semibold, design: .serif)
        static let headlineFont = Font.system(size: 14, weight: .semibold, design: .rounded)
        static let bodyFont = Font.system(size: 13, weight: .regular, design: .default)
        static let captionFont = Font.system(size: 11, weight: .medium, design: .default)
        static let labelFont = Font.system(size: 10, weight: .semibold, design: .default)
        static let monospacedFont = Font.system(size: 13, weight: .semibold, design: .monospaced)
    }

    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.35)
    static let shadowRadius: CGFloat = 14

    // MARK: - Animation
    static let defaultAnimation = Animation.easeInOut(duration: 0.3)
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

struct TradingBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignSystem.backgroundTop, DesignSystem.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [DesignSystem.edgeGlow.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )

            RadialGradient(
                colors: [DesignSystem.bullishColor.opacity(0.10), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

private struct DeskPanelModifier: ViewModifier {
    let glow: Color
    let padding: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.largeCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.panelTop, DesignSystem.panelBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.largeCornerRadius)
                    .stroke(DesignSystem.panelStroke, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.largeCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.12 : 0.06),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
            .shadow(color: glow, radius: 18, x: 0, y: 8)
            .shadow(color: DesignSystem.cardShadow, radius: DesignSystem.shadowRadius, x: 0, y: 10)
            .scaleEffect(isHovered ? 1.008 : 1)
            .offset(y: isHovered ? -2 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
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
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(accent)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .stroke(accent.opacity(0.45), lineWidth: 1.5)
                    .scaleEffect(pulse ? 2.4 : 1)
                    .opacity(pulse ? 0 : 0.9)
            )
            .shadow(color: accent.opacity(0.55), radius: 8)
            .onAppear {
                pulse = false
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
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

struct BallsOfSteelMark: View {
    var size: CGFloat = 72
    var primaryAccent: Color = DesignSystem.primaryColor
    var bullishAccent: Color = DesignSystem.bullishColor
    var bearishAccent: Color = DesignSystem.bearishColor

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.panelTop,
                            Color.black.opacity(0.82),
                            DesignSystem.panelBottom
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(primaryAccent.opacity(0.34), lineWidth: size * 0.025)

            Circle()
                .stroke(primaryAccent.opacity(0.18), lineWidth: size * 0.075)
                .padding(size * 0.2)

            Capsule(style: .continuous)
                .fill(primaryAccent)
                .frame(width: size * 0.68, height: size * 0.12)
                .rotationEffect(.degrees(-28))
                .offset(x: -size * 0.02, y: -size * 0.08)
                .shadow(color: primaryAccent.opacity(0.35), radius: size * 0.08, y: size * 0.03)

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [bullishAccent, primaryAccent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 0.48, height: size * 0.1)
                .rotationEffect(.degrees(28))
                .offset(x: size * 0.1, y: size * 0.14)

            Capsule(style: .continuous)
                .fill(bearishAccent.opacity(0.92))
                .frame(width: size * 0.28, height: size * 0.08)
                .rotationEffect(.degrees(-28))
                .offset(x: size * 0.2, y: size * 0.2)

            Text("B/S")
                .font(.system(size: size * 0.22, weight: .black, design: .serif))
                .kerning(size * 0.01)
                .foregroundColor(DesignSystem.primaryText)
                .shadow(color: Color.black.opacity(0.45), radius: 8, y: 3)

            Circle()
                .fill(primaryAccent)
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: size * 0.28, y: -size * 0.28)
                .shadow(color: primaryAccent.opacity(0.55), radius: 10)
        }
        .frame(width: size, height: size)
    }
}

struct BallsOfSteelWordmark: View {
    var alignment: HorizontalAlignment = .leading
    var title: String = "BALLS OF STEEL"
    var subtitle: String = "No fantasy fills."

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(title)
                .font(DesignSystem.Typography.titleFont)
                .tracking(1.1)
                .foregroundColor(DesignSystem.primaryText)
            Text(subtitle.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(1.3)
                .foregroundColor(DesignSystem.mutedText)
        }
    }
}

struct LaunchOverlayView: View {
    @State private var reveal = false
    @State private var tagLineVisible = false

    var body: some View {
        ZStack {
            TradingBackdrop()

            VStack(spacing: 18) {
                BallsOfSteelMark(size: 104)
                    .scaleEffect(reveal ? 1 : 0.86)
                    .opacity(reveal ? 1 : 0.18)

                BallsOfSteelWordmark(
                    alignment: .center,
                    title: "BALLS OF STEEL",
                    subtitle: "Open first. Close honest."
                )
                .multilineTextAlignment(.center)
                .opacity(reveal ? 1 : 0)
                .offset(y: reveal ? 0 : 8)

                VStack(spacing: 10) {
                    launchLine("SPY + VXX")
                    launchLine("Small size. Sharp reads. No fantasy fills.")
                }
                .opacity(tagLineVisible ? 1 : 0)
                .offset(y: tagLineVisible ? 0 : 10)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .shadow(color: DesignSystem.primaryColor.opacity(0.22), radius: 40, y: 12)
        }
        .onAppear {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
                reveal = true
            }

            withAnimation(.easeOut(duration: 0.45).delay(0.14)) {
                tagLineVisible = true
            }
        }
    }

    private func launchLine(_ text: String) -> some View {
        Text(text)
            .font(DesignSystem.Typography.captionFont)
            .tracking(0.6)
            .foregroundColor(DesignSystem.mutedText)
    }
}

#if canImport(AppKit)
enum BrandIconFactory {
    static func makeDockIcon(size: CGFloat = 512) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let background = NSBezierPath(roundedRect: rect, xRadius: size * 0.24, yRadius: size * 0.24)
        let backgroundGradient = NSGradient(
            colors: [
                NSColor(calibratedRed: 0.20, green: 0.15, blue: 0.11, alpha: 1),
                NSColor(calibratedRed: 0.05, green: 0.04, blue: 0.04, alpha: 1),
                NSColor(calibratedRed: 0.11, green: 0.08, blue: 0.07, alpha: 1)
            ]
        )
        backgroundGradient?.draw(in: background, angle: 300)

        NSColor(calibratedRed: 0.84, green: 0.68, blue: 0.43, alpha: 0.28).setStroke()
        background.lineWidth = size * 0.026
        background.stroke()

        let ringRect = rect.insetBy(dx: size * 0.18, dy: size * 0.18)
        let ring = NSBezierPath(ovalIn: ringRect)
        NSColor(calibratedRed: 0.84, green: 0.68, blue: 0.43, alpha: 0.18).setStroke()
        ring.lineWidth = size * 0.06
        ring.stroke()

        drawSlash(
            center: CGPoint(x: size * 0.43, y: size * 0.59),
            length: size * 0.54,
            thickness: size * 0.1,
            angle: -28,
            color: NSColor(calibratedRed: 0.84, green: 0.68, blue: 0.43, alpha: 1)
        )
        drawSlash(
            center: CGPoint(x: size * 0.58, y: size * 0.38),
            length: size * 0.38,
            thickness: size * 0.085,
            angle: 28,
            color: NSColor(calibratedRed: 0.45, green: 0.96, blue: 0.60, alpha: 1)
        )
        drawSlash(
            center: CGPoint(x: size * 0.67, y: size * 0.3),
            length: size * 0.2,
            thickness: size * 0.065,
            angle: -28,
            color: NSColor(calibratedRed: 0.99, green: 0.43, blue: 0.34, alpha: 0.95)
        )

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let title = "B/S" as NSString
        let titleRect = NSRect(x: size * 0.27, y: size * 0.42, width: size * 0.46, height: size * 0.14)
        title.draw(
            in: titleRect,
            withAttributes: [
                .font: NSFont.systemFont(ofSize: size * 0.13, weight: .black),
                .foregroundColor: NSColor(calibratedWhite: 0.95, alpha: 1),
                .paragraphStyle: paragraph
            ]
        )

        let pulseRect = NSRect(x: size * 0.72, y: size * 0.72, width: size * 0.08, height: size * 0.08)
        let pulse = NSBezierPath(ovalIn: pulseRect)
        NSColor(calibratedRed: 0.84, green: 0.68, blue: 0.43, alpha: 1).setFill()
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
