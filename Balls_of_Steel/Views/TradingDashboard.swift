import SwiftUI

struct TradingDashboard: View {
    @ObservedObject var signalMonitor: SignalMonitor
    @StateObject private var marketPulse = MarketPulse.shared
    
    var body: some View {
        NavigationView {
            List {
                // Market Status Card
                MarketStatusView(phase: marketPulse.currentPhase)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                
                // Active Signals Section
                Section("Active Signals") {
                    ForEach(signalMonitor.activeSignals) { signal in
                        SharedSignalRowView(signal: signal)
                            .swipeActions {
                                Button("Trade") {
                                    signalMonitor.startTrade(signal)
                                }
                                .tint(.green)
                            }
                    }
                }
                
                // Active Trades Section
                Section("Active Trades") {
                    ForEach(signalMonitor.activeTrades) { trade in
                        TradeRowView(trade: trade)
                    }
                }
            }
            .navigationTitle("Trading Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add Symbol") { }
                        Button("Refresh Data") { }
                        Button("Clear All") { }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// Modern, clean market status view
struct MarketStatusView: View {
    let phase: MarketPhase
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Market Phase")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(phase.displayName)
                        .font(.title2)
                        .bold()
                }
                Spacer()
                phaseIndicator
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
                .shadow(radius: 2)
        )
        .padding()
    }
    
    private var phaseIndicator: some View {
        Circle()
            .fill(phase.color)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(phase.color.opacity(0.3), lineWidth: 4)
            )
    }
}

struct TradeRowView: View {
    let trade: Trade
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trade.symbol)
                    .font(.headline)
                StrategyBadge(strategy: trade.strategy)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("P/L: \(trade.unrealizedPnL, specifier: "%.2f")")
                    .foregroundColor(trade.unrealizedPnL >= 0 ? .green : .red)
                    .bold()
            }
        }
        .padding(.vertical, 4)
    }
} 