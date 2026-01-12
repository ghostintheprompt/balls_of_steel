import SwiftUI

// MARK: - Pattern Badge View
struct PatternBadgeView: View {
    let pattern: CandlestickPattern

    var body: some View {
        HStack(spacing: 4) {
            // Pattern icon
            Image(systemName: patternIcon)
                .font(.caption)
                .foregroundColor(signalColor)

            // Pattern name
            Text(pattern.type.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(signalColor)

            // Strength indicator
            strengthIndicator
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(signalColor.opacity(0.1))
        .cornerRadius(6)
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
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Technical Indicators")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // SMA Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Moving Averages")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

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

            Divider()

            // VWAP Section
            HStack {
                Text("VWAP")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(indicators.vwap, specifier: "%.2f")")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.cyan)
                if indicators.isPriceAboveVWAP {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                }
            }

            // VWAP Deviation
            if abs(indicators.vwapDeviation) > 0.5 {
                HStack {
                    Text("Deviation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(indicators.vwapDeviation, specifier: "%+.2f")%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(indicators.vwapDeviation > 0 ? .green : .red)
                }
            }

            Divider()

            // Volume Section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Volume")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(indicators.volumeSignal.displayName)
                        .font(.caption)
                        .foregroundColor(volumeColor)
                }

                HStack {
                    Text("\(indicators.currentVolume)")
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Text("\(indicators.volumeMultiple, specifier: "%.1f")x avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // RSI
            if indicators.rsi > 0 {
                Divider()
                HStack {
                    Text("RSI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(indicators.rsi, specifier: "%.0f")")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(rsiColor)
                }
            }

            // IV if available
            if indicators.impliedVolatility > 0 {
                Divider()
                HStack {
                    Text("Implied Volatility")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(indicators.impliedVolatility, specifier: "%.1f")%")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private var volumeColor: Color {
        switch indicators.volumeSignal {
        case .extremelyHigh:
            return .red
        case .high:
            return .orange
        case .aboveAverage:
            return .green
        case .belowAverage:
            return .gray
        case .veryLow:
            return .gray.opacity(0.5)
        }
    }

    private var rsiColor: Color {
        if indicators.rsi >= 70 {
            return .red // Overbought
        } else if indicators.rsi <= 30 {
            return .green // Oversold
        } else {
            return .primary
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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 4) {
                Text("$\(value, specifier: "%.2f")")
                    .font(.system(.caption, design: .monospaced))
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
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
            // Header
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.purple)
                Text("VXX/VIX Ratio")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Ratio value
            HStack {
                Text("Ratio")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(ratio.ratio, specifier: "%.2f")")
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(ratioColor)
            }

            // Signal
            HStack {
                Text("Signal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(ratio.signal.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(signalColor)
            }

            // Visual indicator
            if ratio.signal != .neutral {
                HStack(spacing: 4) {
                    Image(systemName: ratio.isOverextended ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .foregroundColor(signalColor)
                    Text(ratio.isOverextended ? "Fade Setup" : "Reversal Setup")
                        .font(.caption)
                        .foregroundColor(signalColor)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(signalColor.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
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
            return .red
        case .reversalSetup:
            return .green
        case .neutral:
            return .gray
        }
    }
}

// MARK: - Trading Window Alert View
struct TradingWindowAlertView: View {
    let window: VXXTradingWindow
    let minutesUntil: Int

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(window.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(minutesUntil > 0 ? "Opens in \(minutesUntil) minutes" : "Window Active")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Time range
            Text(window.timeRange)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange, lineWidth: 2)
                )
        )
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
        VStack(alignment: .leading, spacing: 8) {
            // Top row: Symbol, Strategy, Confidence
            HStack {
                VStack(alignment: .leading) {
                    Text(signal.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                    StrategyBadge(strategy: signal.strategy)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(signal.confidence * 100, specifier: "%.0f")%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(confidenceColor)
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Pattern badge if available
            if let pattern = pattern {
                PatternBadgeView(pattern: pattern)
            }

            // Entry/Target/Stop
            HStack(spacing: 16) {
                PriceLabelView(label: "Entry", price: signal.entry, color: .blue)
                PriceLabelView(label: "Target", price: signal.target, color: .green)
                PriceLabelView(label: "Stop", price: signal.stop, color: .red)
            }

            // Quick indicators summary
            if let indicators = indicators {
                HStack(spacing: 8) {
                    if indicators.isVolumeAboveAverage {
                        MiniIndicator(icon: "arrow.up.circle.fill", label: "Vol", color: .orange)
                    }
                    if indicators.isPriceAboveVWAP {
                        MiniIndicator(icon: "chart.line.uptrend.xyaxis", label: "VWAP", color: .cyan)
                    }
                    if indicators.smaSignal == .bullish {
                        MiniIndicator(icon: "arrow.up.right", label: "SMA", color: .green)
                    } else if indicators.smaSignal == .bearish {
                        MiniIndicator(icon: "arrow.down.right", label: "SMA", color: .red)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private var confidenceColor: Color {
        if signal.confidence >= 0.8 {
            return .green
        } else if signal.confidence >= 0.6 {
            return .orange
        } else {
            return .red
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
                .font(.caption)
                .foregroundColor(.secondary)
            Text("$\(price, specifier: "%.2f")")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct MiniIndicator: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}
