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
        // v3.0: Institutional Flow (FREE) - Gold for premium status
        case .vxxInstitutionalFlow: return .cyan

        // VXX-specific strategies (5 core) - Blue family
        case .vxxFadeSetup: return .blue
        case .vxxPowerHour: return .purple
        case .vxxMorningWindow: return .indigo
        case .vxxVolumeSpike: return .teal
        case .vxxLunchWindow: return .mint

        // SPY-specific strategies
        case .spyOpenDrive: return .green
        case .spyCloseDrive: return .orange

        // Additional strategies (11 more) - Various colors
        case .consolidationBreakout: return .green
        case .movingAverageCross: return .blue
        case .earningsPlay: return .purple
        case .vixSpike: return .red
        case .zeroDTE: return .orange
        case .momentumReversal: return .pink
        case .gapAndGo: return .blue
        case .vwapReversal: return .purple
        case .powerHour: return .orange
        case .panicReversal: return .red
        case .weeklyOptionsExpiration: return .indigo
        }
    }
} 
