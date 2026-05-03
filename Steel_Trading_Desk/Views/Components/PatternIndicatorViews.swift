import SwiftUI

// MARK: - Pattern Badge View
struct PatternBadgeView: View {
    let pattern: CandlestickPattern

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: patternIcon)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(signalColor)

            Text(pattern.type.rawValue)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(signalColor)

            strengthIndicator
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(signalColor.opacity(0.12))
        .overlay(
            Capsule().stroke(signalColor.opacity(0.24), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private var patternIcon: String {
        switch pattern.type {
        case .shootingStar:
            return "arrow.down.right.circle.fill"
        case .doji:
            return "minus.circle.fill"
        case .hammer:
            return "arrow.up.right.circle.fill"
        case .hangingMan:
            return "arrow.down.right.circle.fill"
        }
    }

    private var signalColor: Color {
        switch pattern.type.tradingBias {
        case .bearish:
            return .red
        case .bullish:
            return .green
        case .neutral:
            return .orange
        }
    }

    private var strengthIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < strengthBars ? signalColor : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }

    private var strengthBars: Int {
        switch pattern.signal {
        case .strong:
            return 3
        case .moderate:
            return 2
        case .weak:
            return 1
        }
    }
}

// MARK: - Technical Indicators Card
struct TechnicalIndicatorsCard: View {
    let indicators: TechnicalIndicators

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeskSectionHeader(title: "Structure Read", systemImage: "chart.line.uptrend.xyaxis", accent: DesignSystem.primaryColor)

            VStack(alignment: .leading, spacing: 8) {
                Text("Moving Averages")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(DesignSystem.mutedText)

                HStack {
                    IndicatorRow(
                        label: "20 SMA",
                        value: indicators.sma20,
                        color: .yellow,
                        isActive: indicators.isPriceAboveSMA20
                    )
                    Spacer()
                    IndicatorRow(
                        label: "50 SMA",
                        value: indicators.sma50,
                        color: .orange,
                        isActive: indicators.isPriceAboveSMA50
                    )
                }
            }

            HStack {
                Text("VWAP")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(DesignSystem.mutedText)
                Spacer()
                Text("$\(indicators.vwap, specifier: "%.2f")")
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(DesignSystem.primaryColor)
                if indicators.isPriceAboveVWAP {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(DesignSystem.bullishColor)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(DesignSystem.bearishColor)
                }
            }

            if abs(indicators.vwapDeviation) > 0.5 {
                HStack {
                    Text("Deviation")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                    Spacer()
                    Text("\(indicators.vwapDeviation, specifier: "%+.2f")%")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(indicators.vwapDeviation > 0 ? DesignSystem.bullishColor : DesignSystem.bearishColor)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Volume")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(0.8)
                        .foregroundColor(DesignSystem.mutedText)
                    Spacer()
                    Text(indicators.volumeSignal.displayName)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(volumeColor)
                }

                HStack {
                    Text("\(indicators.currentVolume)")
                        .font(DesignSystem.Typography.monospacedFont)
                        .foregroundColor(DesignSystem.primaryText)
                    Spacer()
                    Text("\(indicators.volumeMultiple, specifier: "%.1f")x avg")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }
            }

            if indicators.rsi > 0 {
                HStack {
                    Text("RSI")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(0.8)
                        .foregroundColor(DesignSystem.mutedText)
                    Spacer()
                    Text("\(indicators.rsi, specifier: "%.0f")")
                        .font(DesignSystem.Typography.monospacedFont)
                        .foregroundColor(rsiColor)
                }
            }

            if indicators.impliedVolatility > 0 {
                HStack {
                    Text("Implied Volatility")
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(0.8)
                        .foregroundColor(DesignSystem.mutedText)
                    Spacer()
                    Text("\(indicators.impliedVolatility, specifier: "%.1f")%")
                        .font(DesignSystem.Typography.monospacedFont)
                        .foregroundColor(DesignSystem.primaryColor)
                }
            }
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.12))
    }

    private var volumeColor: Color {
        switch indicators.volumeSignal {
        case .extremelyHigh:
            return DesignSystem.bearishColor
        case .high:
            return DesignSystem.warningColor
        case .aboveAverage:
            return DesignSystem.bullishColor
        case .belowAverage:
            return DesignSystem.mutedText
        case .veryLow:
            return DesignSystem.mutedText.opacity(0.6)
        }
    }

    private var rsiColor: Color {
        if indicators.rsi >= 70 {
            return DesignSystem.bearishColor
        } else if indicators.rsi <= 30 {
            return DesignSystem.bullishColor
        } else {
            return DesignSystem.primaryText
        }
    }
}

// MARK: - Indicator Row Helper
struct IndicatorRow: View {
    let label: String
    let value: Double
    let color: Color
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }
            HStack(spacing: 4) {
                Text("$\(value, specifier: "%.2f")")
                    .font(DesignSystem.Typography.monospacedFont)
                    .foregroundColor(DesignSystem.primaryText)
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.bullishColor)
                }
            }
        }
    }
}

// MARK: - VXX/VIX Ratio View
struct VXXVIXRatioView: View {
    let ratio: VXXVIXRatio

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DeskSectionHeader(title: "Ratio Pressure", systemImage: "chart.bar.xaxis", accent: DesignSystem.primaryColor)

            HStack {
                Text("Ratio")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(DesignSystem.mutedText)
                Spacer()
                Text("\(ratio.ratio, specifier: "%.2f")")
                    .font(DesignSystem.Typography.titleFont)
                    .foregroundColor(ratioColor)
            }

            HStack {
                Text("Read")
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(DesignSystem.mutedText)
                Spacer()
                Text(ratio.signal.displayName)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(signalColor)
            }

            if ratio.signal != .noTrade {
                HStack(spacing: 4) {
                    Image(systemName: ratio.signal == .fadeSetup ? "arrow.down.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(signalColor)
                    Text(ratio.signal.displayName)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(signalColor)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(signalColor.opacity(0.1))
                .cornerRadius(6)
            }

            Text(ratio.signal == .noTrade ? "If the ratio is dead, skip the fantasy." : "Useful only when the rest of the tape agrees.")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
        }
        .deskPanel(glow: signalColor.opacity(0.14))
    }

    private var ratioColor: Color {
        if ratio.isOverextended {
            return .red
        } else if ratio.isOversold {
            return .green
        } else {
            return .primary
        }
    }

    private var signalColor: Color {
        switch ratio.signal {
        case .fadeSetup:
            return .green  // Fade setup = puts = profitable = green
        case .cautionFade:
            return .orange // Caution = borderline
        case .noTrade:
            return .red    // No trade = skip
        }
    }
}

// MARK: - Trading Window Alert View
struct TradingWindowAlertView: View {
    let window: VXXTradingWindow
    let minutesUntil: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundColor(DesignSystem.warningColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(window.displayName)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(DesignSystem.primaryText)

                Text(minutesUntil > 0 ? "Opens in \(minutesUntil) minutes" : "Window active right now")
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }

            Spacer()

            Text(window.timeRange)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DesignSystem.warningColor.opacity(0.1))
                .cornerRadius(6)
        }
        .deskPanel(glow: DesignSystem.warningColor.opacity(0.16))
    }
}

// MARK: - VXX Trading Window Enum
enum VXXTradingWindow {
    case morning
    case lunch
    case powerHour

    var displayName: String {
        switch self {
        case .morning:
            return "Morning Window"
        case .lunch:
            return "Lunch Window"
        case .powerHour:
            return "Power Hour Window"
        }
    }

    var timeRange: String {
        switch self {
        case .morning:
            return "9:50-10:00 AM"
        case .lunch:
            return "12:20-12:35 PM"
        case .powerHour:
            return "3:10-3:25 PM"
        }
    }
}

// MARK: - Enhanced Signal Row with Patterns
struct EnhancedSignalRowView: View {
    let signal: Signal
    let pattern: CandlestickPattern?
    let indicators: TechnicalIndicators?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(signal.symbol)
                        .font(DesignSystem.Typography.titleFont)
                        .foregroundColor(DesignSystem.primaryText)
                    StrategyBadge(strategy: signal.strategy)
                    Text("\(signal.kind.displayName) - \(signal.direction.optionLabel)")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(signal.confidence * 100, specifier: "%.0f")%")
                        .font(DesignSystem.Typography.titleFont)
                        .foregroundColor(confidenceColor)
                    Text("Confidence")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }
            }

            if let pattern = pattern {
                PatternBadgeView(pattern: pattern)
            }

            HStack(spacing: 16) {
                PriceLabelView(label: "Entry", price: signal.entry, color: DesignSystem.primaryColor)
                PriceLabelView(label: "Target", price: signal.target, color: DesignSystem.bullishColor)
                PriceLabelView(label: "Stop", price: signal.stop, color: DesignSystem.bearishColor)
            }

            if let indicators = indicators {
                HStack(spacing: 8) {
                    if indicators.isVolumeAboveAverage {
                        MiniIndicator(icon: "arrow.up.circle.fill", label: "VOL", color: DesignSystem.warningColor)
                    }
                    if indicators.isPriceAboveVWAP {
                        MiniIndicator(icon: "chart.line.uptrend.xyaxis", label: "VWAP", color: DesignSystem.primaryColor)
                    }
                    if indicators.smaSignal == .bullish {
                        MiniIndicator(icon: "arrow.up.right", label: "SMA", color: DesignSystem.bullishColor)
                    } else if indicators.smaSignal == .bearish {
                        MiniIndicator(icon: "arrow.down.right", label: "SMA", color: DesignSystem.bearishColor)
                    }
                }
            }
        }
        .deskPanel(glow: confidenceColor.opacity(0.12))
    }

    private var confidenceColor: Color {
        if signal.confidence >= 0.8 {
            return DesignSystem.bullishColor
        } else if signal.confidence >= 0.6 {
            return DesignSystem.warningColor
        } else {
            return DesignSystem.bearishColor
        }
    }
}

// MARK: - Helper Views
struct PriceLabelView: View {
    let label: String
    let price: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
            Text("$\(price, specifier: "%.2f")")
                .font(DesignSystem.Typography.monospacedFont)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

struct MiniIndicator: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.captionFont)
            Text(label)
                .font(DesignSystem.Typography.captionFont)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}
