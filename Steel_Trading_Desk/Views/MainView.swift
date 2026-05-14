import SwiftUI

private enum CompactPhoneTab: Hashable {
    case desk
    case tape
    case risk
}

struct MainView: View {
    @StateObject private var signalMonitor = SignalMonitor.shared
    @StateObject private var marketState = MarketPulse.shared
    @AppStorage("isBackgroundMonitoringEnabled") private var isBackgroundMonitoringEnabled = false
    @State private var showLaunchOverlay = true
    @State private var compactTab: CompactPhoneTab = .desk
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack {
            TradingBackdrop()

            if horizontalSizeClass == .compact {
                TabView(selection: $compactTab) {
                    compactPhoneTabs
                }
                .tint(DesignSystem.amber)
            } else {
                // Mac / iPad regular size class: single-window terminal.
                // Gate spine is the navigation; no tab bar, no sub-screens.
                TradingDashboard(signalMonitor: signalMonitor)
            }

            if showLaunchOverlay {
                LaunchOverlayView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.03)),
                            removal: .opacity
                        )
                    )
                    .zIndex(2)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: isBackgroundMonitoringEnabled, initial: false) { _, newValue in
            if newValue {
                signalMonitor.startBackgroundMonitoring()
            } else {
                signalMonitor.stopBackgroundMonitoring()
            }
        }
        .task {
            let holdTime: UInt64 = reduceMotion ? 650_000_000 : 1_250_000_000
            try? await Task.sleep(nanoseconds: holdTime)
            withAnimation(.easeOut(duration: reduceMotion ? 0.18 : 0.38)) {
                showLaunchOverlay = false
            }
        }
    }

    @ViewBuilder
    private var compactPhoneTabs: some View {
        TradingDashboard(
            signalMonitor: signalMonitor,
            openTape: { compactTab = .tape },
            openRisk: { compactTab = .risk }
        )
            .tabItem {
                Label("Desk", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(CompactPhoneTab.desk)

        ManualDataEntryView()
            .tabItem {
                Label("Tape", systemImage: "slider.horizontal.3")
            }
            .tag(CompactPhoneTab.tape)

        ActiveTradesView(signalMonitor: signalMonitor)
            .tabItem {
                Label("Risk", systemImage: "shield.lefthalf.filled")
            }
            .tag(CompactPhoneTab.risk)
    }
}
