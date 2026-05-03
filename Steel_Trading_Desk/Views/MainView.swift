import SwiftUI

struct MainView: View {
    @StateObject private var signalMonitor = SignalMonitor.shared
    @StateObject private var marketState = MarketPulse.shared
    @AppStorage("isBackgroundMonitoringEnabled") private var isBackgroundMonitoringEnabled = false
    @State private var showLaunchOverlay = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            TradingBackdrop()

            TabView {
                TradingDashboard(signalMonitor: signalMonitor)
                    .tabItem {
                        Label("Desk", systemImage: "chart.line.uptrend.xyaxis")
                    }

                ManualDataEntryView()
                    .tabItem {
                        Label("Manual", systemImage: "slider.horizontal.3")
                    }

                VXXTradingDashboard(signalMonitor: signalMonitor)
                    .tabItem {
                        Label("VXX", systemImage: "waveform.path.ecg")
                    }

                SPYTradingDashboard(signalMonitor: signalMonitor)
                    .tabItem {
                        Label("SPY", systemImage: "arrow.left.arrow.right")
                    }
                
                ActiveTradesView(signalMonitor: signalMonitor)
                    .tabItem {
                        Label("Live", systemImage: "clock.arrow.circlepath")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .tint(DesignSystem.primaryColor)

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
}
