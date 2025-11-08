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
                }
                Spacer()
                ProfitLossView(entry: trade.entry, current: trade.currentPrice)
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
                RiskLabel("Stop", price: trade.stop, isStop: true)
                Spacer()
                RiskLabel("Entry", price: trade.entry)
                Spacer()
                RiskLabel("Target", price: trade.target)
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
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
} 