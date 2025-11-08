import SwiftUI

struct SharedSignalRowView: View {
    let signal: Signal
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        InfoCard {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.smallSpacing) {
                    HStack {
                        Text(signal.symbol)
                            .font(DesignSystem.Typography.monospacedFont)
                            .bold()
                        Text(signal.strategy.rawValue)
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Price info with design system
                    HStack(spacing: DesignSystem.spacing) {
                        PriceTag("Entry", value: signal.entry, color: .primary)
                        PriceTag("Stop", value: signal.stop, color: DesignSystem.dangerColor)
                        PriceTag("Target", value: signal.target, color: DesignSystem.successColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.smallSpacing) {
                    StrategyBadge(strategy: signal.strategy)
                    
                    Text("R:R \(signal.riskRewardRatio, specifier: "%.1f")")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(.secondary)
                }
            }
        }
        .animation(DesignSystem.defaultAnimation, value: signal.id)
    }
}

private struct PriceTag: View {
    let label: String
    let value: Double
    let color: Color
    
    init(_ label: String, value: Double, color: Color = .primary) {
        self.label = label
        self.value = value
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(.secondary)
            Text("$\(value, specifier: "%.2f")")
                .font(DesignSystem.Typography.captionFont)
                .bold()
                .foregroundColor(color)
        }
    }
}

// Preview
struct SharedSignalRowView_Previews: PreviewProvider {
    static var previews: some View {
        SharedSignalRowView(signal: Signal(
            symbol: "SPY",
            strategy: .gapAndGo,
            entry: 450.0,
            stop: 448.0,
            target: 454.0,
            timestamp: Date(),
            confidence: 0.85,
            setupQuality: .high,
            positionSizePercent: 2.0
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
