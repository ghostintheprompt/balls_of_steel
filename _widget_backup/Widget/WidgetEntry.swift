import WidgetKit

struct WidgetEntry: TimelineEntry {
    let date: Date
    let signals: [Signal]
    let error: Error?
    let isLoading: Bool
    
    init(date: Date, signals: [Signal], error: Error? = nil, isLoading: Bool = false) {
        self.date = date
        self.signals = signals
        self.error = error
        self.isLoading = isLoading
    }
    
    var relevance: TimelineEntryRelevance? {
        // Higher relevance for active signals
        let score: Float = isLoading ? 0.1 : (signals.isEmpty ? 0 : 1.0)
        return TimelineEntryRelevance(score: score)
    }
    
    var isMarketOpen: Bool {
        date.isWithinTradingHours()
    }
    
    var currentPhase: MarketPhase {
        TimeManager.shared.currentPhase()
    }
} 