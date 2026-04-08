import SwiftUI

struct SharedSignalRowView: View {
    let signal: Signal
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        InfoCard(glow: kindColor.opacity(0.18)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    HStack(alignment: .top, spacing: 12) {
                        DeskSignalGlyph(
                            symbol: signal.symbol,
                            accent: kindColor,
                            secondaryAccent: directionColor
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(signal.symbol)
                                    .font(DesignSystem.Typography.titleFont)
                                    .foregroundColor(DesignSystem.primaryText)

                                Text(signal.kind.displayName.uppercased())
                                    .font(DesignSystem.Typography.labelFont)
                                    .tracking(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(kindColor.opacity(0.15))
                                    .overlay(
                                        Capsule().stroke(kindColor.opacity(0.4), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                                    .foregroundColor(kindColor)
                            }

                            HStack(spacing: 8) {
                                StrategyBadge(strategy: signal.strategy)
                                DirectionPill(direction: signal.direction)
                            }

                            Text(signalSummary)
                                .font(DesignSystem.Typography.captionFont)
                                .foregroundColor(DesignSystem.mutedText)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        Text(signal.timestamp, style: .time)
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(DesignSystem.mutedText)
                        Text("R:R")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1)
                            .foregroundColor(DesignSystem.mutedText)
                        Text("\(signal.riskRewardRatio, specifier: "%.1f")")
                            .font(DesignSystem.Typography.monospacedFont)
                            .foregroundColor(DesignSystem.primaryText)
                        Text("\(signal.confidence * 100, specifier: "%.0f")% confidence")
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(DesignSystem.mutedText)
                        DeskMeterBar(value: signal.confidence, accent: kindColor)
                            .frame(width: 92)
                    }
                }

                HStack(spacing: 12) {
                    PriceTile(label: "Entry", value: signal.entry, color: DesignSystem.primaryText)
                    PriceTile(label: "Stop", value: signal.stop, color: DesignSystem.dangerColor)
                    PriceTile(label: "Target", value: signal.target, color: DesignSystem.successColor)
                }
            }
        }
        .animation(DesignSystem.defaultAnimation, value: signal.id)
    }

    private var kindColor: Color {
        switch signal.kind {
        case .entry:
            return DesignSystem.successColor
        case .watch:
            return DesignSystem.warningColor
        case .exit:
            return DesignSystem.dangerColor
        }
    }

    private var directionColor: Color {
        signal.direction == .bullish ? DesignSystem.bullishColor : DesignSystem.bearishColor
    }

    private var signalSummary: String {
        switch signal.kind {
        case .entry:
            return "\(signal.direction.optionLabel) are green-lit. Size stays honest."
        case .watch:
            return "Watch it. Promotion only if the tape keeps its word."
        case .exit:
            return "Either take the money or kill the lie."
        }
    }
}

private struct DirectionPill: View {
    let direction: TradeDirection

    var body: some View {
        Text(direction.displayName.uppercased())
            .font(DesignSystem.Typography.labelFont)
            .tracking(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.14))
            .overlay(
                Capsule().stroke(color.opacity(0.35), lineWidth: 1)
            )
            .clipShape(Capsule())
            .foregroundColor(color)
    }

    private var color: Color {
        direction == .bullish ? DesignSystem.bullishColor : DesignSystem.bearishColor
    }
}

private struct PriceTile: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.labelFont)
                .tracking(0.8)
                .foregroundColor(DesignSystem.mutedText)
            Text("$\(value, specifier: "%.2f")")
                .font(DesignSystem.Typography.monospacedFont)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
    }
}

struct SharedSignalRowView_Previews: PreviewProvider {
    static var previews: some View {
        SharedSignalRowView(signal: Signal(
            symbol: "SPY",
            strategy: .gapAndGo,
            direction: .bullish,
            entry: 450.0,
            stop: 448.0,
            target: 454.0,
            timestamp: Date(),
            confidence: 0.85,
            setupQuality: .perfect,
            positionSizePercent: 2.0,
            kind: .entry
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
