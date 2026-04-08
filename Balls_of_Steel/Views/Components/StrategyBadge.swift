import SwiftUI

struct StrategyBadge: View {
    let strategy: Strategy
    
    var body: some View {
        Text(strategy.rawValue.uppercased())
            .font(DesignSystem.Typography.labelFont)
            .tracking(0.9)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(strategy.color.opacity(0.14))
            )
            .overlay(
                Capsule().stroke(strategy.color.opacity(0.35), lineWidth: 1)
            )
            .foregroundColor(strategy.color)
            .clipShape(Capsule())
            .animation(DesignSystem.springAnimation, value: strategy)
    }
}

extension Strategy {
    var color: Color {
        switch self {
        case .vxxInstitutionalFlow: return .cyan
        case .vxxFadeSetup: return .blue
        case .vxxPowerHour: return .purple
        case .vxxMorningWindow: return .indigo
        case .vxxVolumeSpike: return .teal
        case .vxxLunchWindow: return .mint
        case .spyOpenDrive: return .green
        case .spyCloseDrive: return .orange
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
