import SwiftUI
import WidgetKit

struct TradingWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small Widget Previews
            TradingWidgetView(entry: loadingEntry())
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - Loading")
            
            TradingWidgetView(entry: signalsEntry())
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - With Signal")
            
            TradingWidgetView(entry: marketClosedEntry())
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - Market Closed")
            
            // Medium Widget Previews
            TradingWidgetView(entry: multipleSignalsEntry())
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - Multiple Signals")
            
            TradingWidgetView(entry: emptyEntry())
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - No Signals")
            
            // Large Widget Previews
            TradingWidgetView(entry: manySignalsEntry())
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large - Many Signals")
            
            TradingWidgetView(entry: loadingEntry())
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large - Loading")
        }
    }
    
    static func loadingEntry() -> WidgetEntry {
        WidgetEntry(date: Date(), signals: [], isLoading: true)
    }
    
    static func signalsEntry() -> WidgetEntry {
        WidgetEntry(date: Date(), signals: [sampleSignal()])
    }
    
    static func marketClosedEntry() -> WidgetEntry {
        WidgetEntry(date: Date(), signals: [], error: WidgetError.marketClosed)
    }
    
    static func emptyEntry() -> WidgetEntry {
        WidgetEntry(date: Date(), signals: [], error: WidgetError.noData)
    }
    
    static func multipleSignalsEntry() -> WidgetEntry {
        WidgetEntry(date: Date(), signals: [
            sampleSignal(symbol: "SPY", strategy: .gapAndGo),
            sampleSignal(symbol: "QQQ", strategy: .vwapBounce),
            sampleSignal(symbol: "AAPL", strategy: .powerHourBreakout)
        ])
    }
    
    static func manySignalsEntry() -> WidgetEntry {
        WidgetEntry(date: Date(), signals: [
            sampleSignal(symbol: "SPY", strategy: .gapAndGo, entry: 450.0),
            sampleSignal(symbol: "QQQ", strategy: .vwapBounce, entry: 380.0),
            sampleSignal(symbol: "AAPL", strategy: .powerHourBreakout, entry: 175.0),
            sampleSignal(symbol: "TSLA", strategy: .momentumContinuation, entry: 250.0),
            sampleSignal(symbol: "NVDA", strategy: .breakoutPullback, entry: 800.0)
        ])
    }
    
    private static func sampleSignal(
        symbol: String = "SPY", 
        strategy: Strategy = .gapAndGo, 
        entry: Double = 450.0
    ) -> Signal {
        Signal(
            symbol: symbol,
            strategy: strategy,
            entry: entry,
            stop: entry * 0.995, // 0.5% stop
            target: entry * 1.015, // 1.5% target (3:1 R:R)
            timestamp: Date(),
            confidence: Double.random(in: 0.7...0.95),
            setupQuality: [.high, .medium, .low].randomElement() ?? .medium,
            positionSizePercent: Double.random(in: 1.0...3.0)
        )
    }
} 