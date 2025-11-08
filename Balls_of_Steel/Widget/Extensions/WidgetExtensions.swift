import SwiftUI
import WidgetKit

// MARK: - Widget-Specific Extensions

extension Signal {
    /// Shortened symbol for widget display
    var displaySymbol: String {
        // Keep symbol short for widget space constraints
        String(symbol.prefix(6))
    }
    
    /// Quick risk/reward display for widgets
    var compactRiskReward: String {
        "R:R \(riskRewardRatio, specifier: "%.1f")"
    }
    
    /// Priority score for widget ordering
    var widgetPriority: Double {
        // Higher confidence and better risk/reward get priority
        return confidence * min(riskRewardRatio, 5.0) // Cap at 5.0 for sorting
    }
}

extension Array where Element == Signal {
    /// Sort signals by widget display priority
    var sortedForWidget: [Signal] {
        return sorted { $0.widgetPriority > $1.widgetPriority }
    }
    
    /// Get top signals for widget display
    func topSignals(for family: WidgetFamily) -> [Signal] {
        let maxCount = WidgetConfiguration.maxSignalsForFamily(family)
        return sortedForWidget.prefix(maxCount).map { $0 }
    }
}

extension Strategy {
    /// Abbreviated name for compact widget display
    var shortName: String {
        switch self {
        case .gapAndGo: return "Gap"
        case .vwapBounce: return "VWAP"
        case .powerHourBreakout: return "Power"
        case .momentumContinuation: return "Momentum"
        case .supportResistance: return "S/R"
        case .volumeBreakout: return "Volume"
        case .reversalPattern: return "Reversal"
        case .trendFollowing: return "Trend"
        case .meanReversion: return "Mean Rev"
        case .breakoutPullback: return "Pullback"
        case .flagPattern: return "Flag"
        }
    }
    
    /// Single character indicator for minimal widget display
    var indicator: String {
        switch self {
        case .gapAndGo: return "G"
        case .vwapBounce: return "V"
        case .powerHourBreakout: return "P"
        case .momentumContinuation: return "M"
        case .supportResistance: return "S"
        case .volumeBreakout: return "B"
        case .reversalPattern: return "R"
        case .trendFollowing: return "T"
        case .meanReversion: return "E"
        case .breakoutPullback: return "U"
        case .flagPattern: return "F"
        }
    }
}

extension MarketPhase {
    /// Compact status text for widgets
    var shortStatus: String {
        switch self {
        case .preMarket: return "Pre"
        case .opening: return "Open" 
        case .midday: return "Mid"
        case .powerHour: return "Power"
        case .afterHours: return "After"
        case .regular: return "Live"
        }
    }
    
    /// Icon for market phase
    var icon: String {
        switch self {
        case .preMarket: return "sunrise"
        case .opening: return "bell"
        case .midday: return "sun.max"
        case .powerHour: return "bolt"
        case .afterHours: return "sunset"
        case .regular: return "clock"
        }
    }
}

extension WidgetEntry {
    /// Formatted time for display
    var timeDisplay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Priority signals for this entry
    var prioritySignals: [Signal] {
        return signals.sortedForWidget
    }
    
    /// Status message for empty states
    var statusMessage: String {
        if isLoading {
            return "Loading..."
        } else if let error = error {
            return error.localizedDescription
        } else if signals.isEmpty {
            return isMarketOpen ? "No signals" : "Market closed"
        } else {
            return "\(signals.count) signal\(signals.count == 1 ? "" : "s")"
        }
    }
}

// MARK: - Widget-Specific View Modifiers

extension View {
    /// Apply widget-specific styling
    func widgetStyle() -> some View {
        self
            .background(Color(UIColor.systemBackground))
            .cornerRadius(WidgetDesignSystem.cornerRadius)
    }
    
    /// Conditional widget padding based on family
    func widgetPadding(for family: WidgetFamily) -> some View {
        let padding: CGFloat = switch family {
        case .systemSmall: WidgetDesignSystem.smallWidgetPadding
        case .systemMedium, .systemLarge: WidgetDesignSystem.mediumWidgetPadding
        @unknown default: WidgetDesignSystem.smallWidgetPadding
        }
        
        return self.padding(padding)
    }
    
    /// Widget-specific animations
    func widgetAnimation() -> some View {
        self.animation(.easeInOut(duration: WidgetConfiguration.animationDuration), value: UUID())
    }
}
