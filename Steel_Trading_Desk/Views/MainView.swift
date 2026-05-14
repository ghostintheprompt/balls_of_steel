import SwiftUI

private enum CompactPhoneTab: Hashable {
    case desk
    case tape
    case risk
}

private enum ExpandedDeskTab: Hashable {
    case desk
    case manual
    case vxx
    case spy
    case live
    case settings
}

struct MainView: View {
    @StateObject private var signalMonitor = SignalMonitor.shared
    @StateObject private var marketState = MarketPulse.shared
    @AppStorage("isBackgroundMonitoringEnabled") private var isBackgroundMonitoringEnabled = false
    @State private var showLaunchOverlay = true
    @State private var compactTab: CompactPhoneTab = .desk
    @State private var expandedTab: ExpandedDeskTab = .desk
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ZStack {
            TradingBackdrop()

            if horizontalSizeClass == .compact {
                TabView(selection: $compactTab) {
                    compactPhoneTabs
                }
                .tint(DesignSystem.primaryColor)
            } else {
                TabView(selection: $expandedTab) {
                    expandedDeskTabs
                }
                .tint(DesignSystem.primaryColor)
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

    @ViewBuilder
    private var expandedDeskTabs: some View {
        TradingDashboard(signalMonitor: signalMonitor)
            .tabItem {
                Label("Desk", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(ExpandedDeskTab.desk)

        ManualDataEntryView()
            .tabItem {
                Label("Manual", systemImage: "slider.horizontal.3")
            }
            .tag(ExpandedDeskTab.manual)

        VXXTradingDashboard(signalMonitor: signalMonitor)
            .tabItem {
                Label("VXX", systemImage: "waveform.path.ecg")
            }
            .tag(ExpandedDeskTab.vxx)

        SPYTradingDashboard(signalMonitor: signalMonitor)
            .tabItem {
                Label("SPY", systemImage: "arrow.left.arrow.right")
            }
            .tag(ExpandedDeskTab.spy)

        ActiveTradesView(signalMonitor: signalMonitor)
            .tabItem {
                Label("Live", systemImage: "clock.arrow.circlepath")
            }
            .tag(ExpandedDeskTab.live)

        SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(ExpandedDeskTab.settings)
    }
}
