import SwiftUI

// MARK: - Strategies List View
// All 16 strategies are free and open source.

struct StrategiesListView: View {
    @State private var selectedStrategy: Strategy?

    var body: some View {
        NavigationView {
            List {
                Section("Core VXX Strategies") {
                    StrategyRow(strategy: .vxxInstitutionalFlow, winRate: "90%", reliability: "(Rating: 3)")
                    StrategyRow(strategy: .vxxFadeSetup, winRate: "75%", reliability: "(Rating: 2)")
                    StrategyRow(strategy: .vxxPowerHour, winRate: "73%", reliability: "(Rating: 2)")
                    StrategyRow(strategy: .vxxMorningWindow, winRate: "72%", reliability: "(Rating: 2)")
                    StrategyRow(strategy: .vxxVolumeSpike, winRate: "70%", reliability: "(Rating: 2)")
                    StrategyRow(strategy: .vxxLunchWindow, winRate: "68%", reliability: "(Rating: 1)")
                }

                Section("Additional Trading Strategies") {
                    StrategyRow(strategy: .weeklyOptionsExpiration, winRate: "75%", reliability: "(Rating: 2)")
                    StrategyRow(strategy: .panicReversal, winRate: "72%", reliability: "(Rating: 2)")
                    StrategyRow(strategy: .gapAndGo, winRate: "70%", reliability: "(Rating: 1)")
                    StrategyRow(strategy: .consolidationBreakout, winRate: "68%", reliability: "(Rating: 1)")
                    StrategyRow(strategy: .vwapReversal, winRate: "68%", reliability: "(Rating: 1)")
                    StrategyRow(strategy: .powerHour, winRate: "65%", reliability: "(Rating: 1)")
                    StrategyRow(strategy: .movingAverageCross, winRate: "65%", reliability: "(Rating: 1)")
                    StrategyRow(strategy: .earningsPlay, winRate: "62%", reliability: "(Rating: 1)")
                    StrategyRow(strategy: .vixSpike, winRate: "60%", reliability: "(Rating: 1)")
                    StrategyRow(strategy: .zeroDTE, winRate: "58%", reliability: "(Rating: 1)")
                    StrategyRow(strategy: .momentumReversal, winRate: "55%", reliability: "(Rating: 1)")
                }
            }
            .navigationTitle("VXX Strategies")
        }
    }
}

// MARK: - Strategy Row
struct StrategyRow: View {
    let strategy: Strategy
    let winRate: String
    let reliability: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Text(winRate)
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(reliability)
                        .font(.caption)
                }
            }

            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    StrategiesListView()
}
