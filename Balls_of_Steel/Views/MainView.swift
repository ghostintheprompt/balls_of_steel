import SwiftUI

struct MainView: View {
    @StateObject private var signalMonitor = SignalMonitor.shared
    @StateObject private var marketState = MarketPulse.shared
    @AppStorage("isBackgroundMonitoringEnabled") private var isBackgroundMonitoringEnabled = false
    
    var body: some View {
        TabView {
            TradingDashboard(signalMonitor: signalMonitor)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            ActiveTradesView(signalMonitor: signalMonitor)
                .tabItem {
                    Label("Active", systemImage: "clock.arrow.circlepath")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onChange(of: isBackgroundMonitoringEnabled) { newValue in
            if newValue {
                signalMonitor.startBackgroundMonitoring()
            } else {
                signalMonitor.stopBackgroundMonitoring()
            }
        }
    }
} 