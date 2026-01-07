import WidgetKit
import SwiftUI

// Note: Widget extensions need their own target. This is currently disabled.
// @main
struct TradingWidgets: WidgetBundle {
    var body: some Widget {
        TradingWidget()
    }
}

struct TradingWidget: Widget {
    private let kind = "com.ballsofsteel.trading"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SignalProvider()) { entry in
            TradingWidgetView(entry: entry)
        }
        .configurationDisplayName("Trading Signals")
        .description("Shows active trading signals")
        .supportedFamilies(WidgetConfiguration.supportedFamilies)
    }
}

struct SignalProvider: TimelineProvider {
    private let scanner = SignalScanner()
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            signals: [],
            isLoading: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        // For preview in widget gallery
        let sampleSignal = Signal(
            symbol: "SPY",
            strategy: .gapAndGo,
            entry: 450.0,
            stop: 448.0,
            target: 454.0,
            timestamp: Date(),
            confidence: 0.85,
            setupQuality: .high,
            positionSizePercent: 2.0
        )
        
        let entry = WidgetEntry(
            date: Date(),
            signals: [sampleSignal]
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        Task { @MainActor in
            do {
                // Get active signals from scanner
                let signals = try await scanner.currentSignals()
                let nextUpdate = WidgetConfiguration.nextUpdateDate()
                
                let entry = WidgetEntry(
                    date: Date(),
                    signals: Array(signals.prefix(WidgetConfiguration.maxSignals))
                )
                
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let errorEntry = WidgetEntry(
                    date: Date(),
                    signals: [],
                    error: WidgetError.networkError(error)
                )
                
                // Retry sooner on error
                let retryDate = Date().addingTimeInterval(300) // 5 minutes
                let timeline = Timeline(entries: [errorEntry], policy: .after(retryDate))
                completion(timeline)
            }
        }
    }
} 