import SwiftUI

struct MarketPhaseIndicator: View {
    let phase: MarketPhase
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(phase.color)
                .frame(width: 8, height: 8)
            Text(phase.rawValue)
                .font(.caption2)
                .foregroundColor(phase.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(phase.color.opacity(0.1))
        )
    }
} 