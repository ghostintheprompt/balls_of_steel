import SwiftUI

struct StrategyBadge: View {
    let strategy: Strategy
    
    var body: some View {
        Text(strategy.rawValue)
            .font(DesignSystem.Typography.captionFont)
            .bold()
            .padding(.horizontal, DesignSystem.smallSpacing)
            .padding(.vertical, 4)
            .background(strategy.color.opacity(0.15))
            .foregroundColor(strategy.color)
            .clipShape(Capsule())
            .animation(DesignSystem.springAnimation, value: strategy)
    }
}

extension Strategy {
    var color: Color {
        switch self {
        // Core strategies
        case .earningsVolatilityCrush: return .purple
        case .gapFill: return .blue
        case .zdteIronButterfly: return .orange
        case .vixSpikePremiumSelling: return .red
        case .momentumBreakout: return .green
        case .preMarketInstitutionalFlow: return .cyan
        case .weeklyOptionsExpiration: return .indigo
        // Legacy strategies  
        case .gapAndGo: return .blue
        case .vwapReversal: return .purple
        case .powerHour: return .orange
        case .panicReversal: return .red
        }
    }
} 