import SwiftUI

struct AlertView: View {
    let signal: Signal
    
    var body: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: DesignSystem.spacing) {
                HStack {
                    Text(signal.symbol)
                        .font(DesignSystem.Typography.titleFont)
                    Spacer()
                    StrategyBadge(strategy: signal.strategy)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.smallSpacing) {
                    HStack {
                        Text("Entry:")
                            .foregroundColor(.secondary)
                        Spacer()
                        PriceDisplay(price: signal.entry, trend: nil)
                    }
                    
                    HStack {
                        Text("Target:")
                            .foregroundColor(.secondary)
                        Spacer()
                        PriceDisplay(price: signal.target, trend: .up)
                    }
                    
                    HStack {
                        Text("Stop:")
                            .foregroundColor(.secondary)
                        Spacer()
                        PriceDisplay(price: signal.stop, trend: .down)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Risk/Reward:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(signal.riskRewardRatio, specifier: "%.1f"):1")
                            .font(DesignSystem.Typography.bodyFont)
                            .bold()
                            .foregroundColor(signal.riskRewardRatio >= 2.0 ? DesignSystem.successColor : DesignSystem.warningColor)
                    }
                }
                .font(DesignSystem.Typography.bodyFont)
                
                HStack {
                    Text(signal.timestamp, style: .time)
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Confidence: \(signal.confidence * 100, specifier: "%.0f")%")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(.secondary)
                }
            }
        }
        .animation(DesignSystem.defaultAnimation, value: signal.id)
    }
}

// Preview
struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView(signal: Signal(
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
        .frame(width: 400)
        .preferredColorScheme(.dark)
    }
} 