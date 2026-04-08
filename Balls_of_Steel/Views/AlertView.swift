import SwiftUI

struct AlertView: View {
    let signal: Signal
    
    var body: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(signal.symbol)
                            .font(DesignSystem.Typography.titleFont)
                            .foregroundColor(DesignSystem.primaryText)
                        HStack(spacing: 8) {
                            StrategyBadge(strategy: signal.strategy)
                            Text(signal.kind.displayName.uppercased())
                                .font(DesignSystem.Typography.labelFont)
                                .tracking(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(kindColor.opacity(0.14))
                                .overlay(
                                    Capsule().stroke(kindColor.opacity(0.35), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                                .foregroundColor(kindColor)
                        }
                    }

                    Spacer()

                    Text(signal.direction.optionLabel.uppercased())
                        .font(DesignSystem.Typography.labelFont)
                        .tracking(0.8)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(directionColor.opacity(0.14))
                        .overlay(
                            Capsule().stroke(directionColor.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .foregroundColor(directionColor)
                }

                HStack(spacing: 12) {
                    alertPriceTile(label: "Entry", price: signal.entry, color: DesignSystem.primaryColor)
                    alertPriceTile(label: "Stop", price: signal.stop, color: DesignSystem.bearishColor)
                    alertPriceTile(label: "Target", price: signal.target, color: DesignSystem.bullishColor)
                }

                HStack {
                    Text(signal.timestamp, style: .time)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                    
                    Spacer()
                    
                    Text("R:R \(signal.riskRewardRatio, specifier: "%.1f") • \(signal.confidence * 100, specifier: "%.0f")% confidence")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(signal.riskRewardRatio >= 2.0 ? DesignSystem.bullishColor : DesignSystem.warningColor)
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

    private func alertPriceTile(label: String, price: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(DesignSystem.Typography.labelFont)
                .tracking(0.8)
                .foregroundColor(DesignSystem.mutedText)
            Text("$\(price, specifier: "%.2f")")
                .font(DesignSystem.Typography.monospacedFont)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}

// Preview
struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView(signal: Signal(
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
        .frame(width: 400)
        .preferredColorScheme(.dark)
    }
} 
