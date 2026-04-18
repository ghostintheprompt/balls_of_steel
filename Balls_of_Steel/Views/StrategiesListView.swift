import SwiftUI

// MARK: - Strategies List View
// Free: Institutional Flow only
// Paid: All 16 strategies

struct StrategiesListView: View {
    @StateObject private var storeKit = StoreKitService.shared
    @State private var selectedStrategy: Strategy?
    @State private var showingUnlock = false

    var body: some View {
        NavigationView {
            List {
                // Free Strategy (Always Available)
                freeStrategySection

                // Premium Strategies (Locked if not unlocked)
                if storeKit.hasUnlocked {
                    premiumStrategiesSection
                } else {
                    lockedStrategiesSection
                }

                // Unlock Banner
                if !storeKit.hasUnlocked {
                    unlockBannerSection
                }
            }
            .navigationTitle("VXX Strategies")
            .sheet(isPresented: $showingUnlock) {
                UnlockView()
            }
        }
    }

    // MARK: - Free Strategy
    private var freeStrategySection: some View {
        Section {
            StrategyRow(
                strategy: .vxxInstitutionalFlow,
                winRate: "90%",
                reliability: "(Rating: 3)",
                isUnlocked: true
            )
        } header: {
            HStack {
                Text("Free Strategy")
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        } footer: {
            Text("The supreme window. 90% reliability. This is your 3:45-4:10 PM edge.")
                .font(.caption)
        }
    }

    // MARK: - Premium Strategies (Unlocked)
    private var premiumStrategiesSection: some View {
        Section("All 16 Strategies Unlocked") {
            // VXX Strategies (5)
            StrategyRow(strategy: .vxxFadeSetup, winRate: "75%", reliability: "(Rating: 2)", isUnlocked: true)
            StrategyRow(strategy: .vxxPowerHour, winRate: "73%", reliability: "(Rating: 2)", isUnlocked: true)
            StrategyRow(strategy: .vxxMorningWindow, winRate: "72%", reliability: "(Rating: 2)", isUnlocked: true)
            StrategyRow(strategy: .vxxVolumeSpike, winRate: "70%", reliability: "(Rating: 2)", isUnlocked: true)
            StrategyRow(strategy: .vxxLunchWindow, winRate: "68%", reliability: "(Rating: 1)", isUnlocked: true)

            // Additional Strategies (11 more)
            StrategyRow(strategy: .weeklyOptionsExpiration, winRate: "75%", reliability: "(Rating: 2)", isUnlocked: true)
            StrategyRow(strategy: .panicReversal, winRate: "72%", reliability: "(Rating: 2)", isUnlocked: true)
            StrategyRow(strategy: .gapAndGo, winRate: "70%", reliability: "(Rating: 1)", isUnlocked: true)
            StrategyRow(strategy: .consolidationBreakout, winRate: "68%", reliability: "(Rating: 1)", isUnlocked: true)
            StrategyRow(strategy: .vwapReversal, winRate: "68%", reliability: "(Rating: 1)", isUnlocked: true)
            StrategyRow(strategy: .powerHour, winRate: "65%", reliability: "(Rating: 1)", isUnlocked: true)
            StrategyRow(strategy: .movingAverageCross, winRate: "65%", reliability: "(Rating: 1)", isUnlocked: true)
            StrategyRow(strategy: .earningsPlay, winRate: "62%", reliability: "(Rating: 1)", isUnlocked: true)
            StrategyRow(strategy: .vixSpike, winRate: "60%", reliability: "(Rating: 1)", isUnlocked: true)
            StrategyRow(strategy: .zeroDTE, winRate: "58%", reliability: "(Rating: 1)", isUnlocked: true)
            StrategyRow(strategy: .momentumReversal, winRate: "55%", reliability: "(Rating: 1)", isUnlocked: true)
        }
    }

    // MARK: - Locked Strategies (Preview)
    private var lockedStrategiesSection: some View {
        Section("Unlock All 16 Strategies") {
            // Show top strategies as preview
            LockedStrategyRow(strategy: .vxxFadeSetup, winRate: "75%")
            LockedStrategyRow(strategy: .weeklyOptionsExpiration, winRate: "75%")
            LockedStrategyRow(strategy: .vxxPowerHour, winRate: "73%")
            LockedStrategyRow(strategy: .vxxMorningWindow, winRate: "72%")
            LockedStrategyRow(strategy: .panicReversal, winRate: "72%")
            LockedStrategyRow(strategy: .vxxVolumeSpike, winRate: "70%")
            LockedStrategyRow(strategy: .gapAndGo, winRate: "70%")
            LockedStrategyRow(strategy: .vxxLunchWindow, winRate: "68%")

            // Show there are more
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                Text("+ 8 More Strategies")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Unlock Banner
    private var unlockBannerSection: some View {
        Section {
            Button(action: { showingUnlock = true }) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Unlock All 16 Strategies")
                            .font(.headline)
                        Spacer()
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Get the complete VXX system")
                                .font(.subheadline)
                            if let price = storeKit.formattedPrice {
                                Text("\(price) one-time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Strategy Row (Unlocked)
struct StrategyRow: View {
    let strategy: Strategy
    let winRate: String
    let reliability: String
    let isUnlocked: Bool

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

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Locked Strategy Row (Preview)
struct LockedStrategyRow: View {
    let strategy: Strategy
    let winRate: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.gray)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(winRate + " Win Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(0.6)
    }
}

// MARK: - Preview
#Preview {
    StrategiesListView()
}
