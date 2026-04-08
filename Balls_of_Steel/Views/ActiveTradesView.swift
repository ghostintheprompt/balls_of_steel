import SwiftUI
import Charts

struct ActiveTradesView: View {
    @ObservedObject var signalMonitor: SignalMonitor
    
    var body: some View {
        List {
            ForEach(signalMonitor.activeTrades) { trade in
                TradeDetailCard(trade: trade)
            }
        }
        .navigationTitle("Active Trades")
    }
}

struct TradeDetailCard: View {
    let trade: Trade
    @StateObject private var monitor = MarketDataService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(trade.symbol)
                        .font(.title2)
                        .bold()
                    StrategyBadge(strategy: trade.strategy)
                    Text(trade.direction.optionLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // P&L Display
                VStack(alignment: .trailing) {
                    let pnl = trade.unrealizedPnL / 100
                    let pnlPercent = (pnl / trade.entry) * 100
                    Text(String(format: "$%.2f", pnl))
                    .font(.title3)
                    .foregroundColor(pnl >= 0 ? .green : .red)
                    Text(String(format: "%.2f%%", pnlPercent))
                        .font(.caption)
                        .foregroundColor(pnl >= 0 ? .green : .red)
                }
            }
            
            // Chart
            Chart(trade.priceHistory) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Price", point.price)
                )
            }
            .frame(height: 100)
            
            // Risk Management
            HStack {
                // Stop
                VStack {
                    Text("Stop")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", trade.stop))
                        .foregroundColor(.red)
                }
                Spacer()
                // Entry
                VStack {
                    Text("Entry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", trade.entry))
                }
                Spacer()
                // Target
                VStack {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", trade.target))
                        .foregroundColor(.green)
                }
            }
            
            // Actions
            HStack {
                Button("Close Position") {
                    // Close trade logic
                }
                .buttonStyle(.borderedProminent)
                
                Button("Adjust Stop") {
                    // Stop adjustment logic
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
    }
} 
