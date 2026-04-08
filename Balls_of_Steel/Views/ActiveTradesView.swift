import SwiftUI
import Charts

struct ActiveTradesView: View {
    @ObservedObject var signalMonitor: SignalMonitor
    
    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DeskSectionHeader(title: "Live Risk", systemImage: "flame.fill", accent: DesignSystem.warningColor)
                        LiveRiskSummaryStrip(trades: signalMonitor.activeTrades)

                        if signalMonitor.activeTrades.isEmpty {
                            InfoCard {
                                Text("No active trades. When the tape gives you something real, it will show up here.")
                                    .font(DesignSystem.Typography.bodyFont)
                                    .foregroundColor(DesignSystem.mutedText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            ForEach(signalMonitor.activeTrades) { trade in
                                TradeDetailCard(trade: trade)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Active Trades")
        }
    }
}

private struct LiveRiskSummaryStrip: View {
    let trades: [Trade]

    var body: some View {
        HStack(spacing: 12) {
            summaryTile(title: "Open Trades", value: "\(trades.count)", accent: DesignSystem.warningColor)
            summaryTile(title: "Net P/L", value: netPnLText, accent: netPnL >= 0 ? DesignSystem.bullishColor : DesignSystem.bearishColor)
            summaryTile(title: "Bias", value: biasText, accent: biasAccent)
        }
    }

    private var netPnL: Double {
        trades.reduce(0) { $0 + ($1.unrealizedPnL / 100) }
    }

    private var netPnLText: String {
        String(format: "$%.2f", netPnL)
    }

    private var bullishCount: Int {
        trades.filter { $0.direction == .bullish }.count
    }

    private var bearishCount: Int {
        trades.filter { $0.direction == .bearish }.count
    }

    private var biasText: String {
        if trades.isEmpty { return "Flat" }
        if bullishCount == bearishCount { return "Mixed" }
        return bullishCount > bearishCount ? "Calls" : "Puts"
    }

    private var biasAccent: Color {
        if trades.isEmpty { return DesignSystem.mutedText }
        if bullishCount == bearishCount { return DesignSystem.primaryColor }
        return bullishCount > bearishCount ? DesignSystem.bullishColor : DesignSystem.bearishColor
    }

    private func summaryTile(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                DeskPulseDot(accent: accent, size: 7)
                Text(title.uppercased())
                    .font(DesignSystem.Typography.labelFont)
                    .tracking(0.8)
                    .foregroundColor(DesignSystem.mutedText)
            }
            Text(value)
                .font(DesignSystem.Typography.headlineFont)
                .foregroundColor(DesignSystem.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .deskPanel(glow: accent.opacity(0.12), padding: 14)
    }
}

struct TradeDetailCard: View {
    let trade: Trade
    @StateObject private var monitor = MarketDataService.shared
    
    var body: some View {
        InfoCard(glow: pnlColor.opacity(0.18)) {
            VStack(spacing: 16) {
                HStack {
                    HStack(alignment: .top, spacing: 12) {
                        DeskSignalGlyph(symbol: trade.symbol, accent: pnlColor, secondaryAccent: directionColor)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(trade.symbol)
                                .font(DesignSystem.Typography.titleFont)
                                .bold()
                                .foregroundColor(DesignSystem.primaryText)
                            StrategyBadge(strategy: trade.strategy)
                            Text(trade.direction.optionLabel)
                                .font(DesignSystem.Typography.captionFont)
                                .foregroundColor(DesignSystem.mutedText)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            DeskPulseDot(accent: pnlColor, size: 7)
                            Text("LIVE")
                                .font(DesignSystem.Typography.labelFont)
                                .tracking(0.8)
                                .foregroundColor(DesignSystem.mutedText)
                        }
                        Text(String(format: "$%.2f", pnl))
                            .font(DesignSystem.Typography.titleFont)
                            .foregroundColor(pnlColor)
                        Text(String(format: "%.2f%%", pnlPercent))
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(pnlColor)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("MOVE TO TARGET")
                            .font(DesignSystem.Typography.labelFont)
                            .tracking(1)
                            .foregroundColor(DesignSystem.mutedText)
                        Spacer()
                        Text("\(Int(progressToTarget * 100))%")
                            .font(DesignSystem.Typography.captionFont)
                            .foregroundColor(pnlColor)
                    }
                    DeskMeterBar(value: progressToTarget, accent: pnlColor)
                }
                
                Chart(trade.priceHistory) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(pnlColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Price", point.price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [pnlColor.opacity(0.22), pnlColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 100)
                .chartYAxis(.hidden)
                .chartXAxis(.hidden)
                
                HStack {
                    VStack {
                        Text("Stop")
                            .font(DesignSystem.Typography.labelFont)
                            .foregroundColor(DesignSystem.mutedText)
                        Text(String(format: "$%.2f", trade.stop))
                            .foregroundColor(DesignSystem.dangerColor)
                    }
                    Spacer()
                    VStack {
                        Text("Entry")
                            .font(DesignSystem.Typography.labelFont)
                            .foregroundColor(DesignSystem.mutedText)
                        Text(String(format: "$%.2f", trade.entry))
                            .foregroundColor(DesignSystem.primaryText)
                    }
                    Spacer()
                    VStack {
                        Text("Target")
                            .font(DesignSystem.Typography.labelFont)
                            .foregroundColor(DesignSystem.mutedText)
                        Text(String(format: "$%.2f", trade.target))
                            .foregroundColor(DesignSystem.successColor)
                    }
                }
                
                HStack {
                    StandardButton(title: "Close Position", action: {
                    }
                    , style: .danger)
                    
                    StandardButton(title: "Adjust Stop", action: {
                    }
                    , style: .secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private var pnl: Double {
        trade.unrealizedPnL / 100
    }

    private var pnlPercent: Double {
        guard trade.entry != 0 else { return 0 }
        return (pnl / trade.entry) * 100
    }

    private var pnlColor: Color {
        pnl >= 0 ? DesignSystem.bullishColor : DesignSystem.bearishColor
    }

    private var directionColor: Color {
        trade.direction == .bullish ? DesignSystem.bullishColor : DesignSystem.bearishColor
    }

    private var progressToTarget: Double {
        let denominator = abs(trade.target - trade.entry)
        guard denominator > 0 else { return 0 }
        let moved = trade.direction == .bullish ? (trade.currentPrice - trade.entry) : (trade.entry - trade.currentPrice)
        return min(max(moved / denominator, 0), 1)
    }
}
