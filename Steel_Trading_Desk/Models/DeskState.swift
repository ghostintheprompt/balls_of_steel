import Foundation

// MARK: - DeskState (Phase 7)
//
// Single piece of state that drives what the desk screen actually shows.
// Every visual transition in the app keys off this — pre-market quiet,
// active window, open position, session-close warning, close, after-hours.
//
// Derived from TimeManager + SignalMonitor; never set directly by views.

enum DeskState: Equatable {
    case preMarket          // before 9:30 ET
    case betweenWindows     // market open, no active trading window
    case windowOpen(VXXTradingWindow)
    case openPosition(activeCount: Int)
    case closeWarning       // 16:10–16:15 ET
    case hardExit           // ≥ 16:15 ET — session close UI takes over
    case afterHours         // ≥ 16:15 ET

    /// True when the screen should be replaced by the session-close takeover.
    var isTakeover: Bool {
        switch self {
        case .closeWarning, .hardExit: return true
        default: return false
        }
    }

    /// Short label for status footers / debug.
    var label: String {
        switch self {
        case .preMarket:      return "PRE-MARKET"
        case .betweenWindows: return "BETWEEN WINDOWS"
        case .windowOpen:     return "WINDOW OPEN"
        case .openPosition:   return "POSITION OPEN"
        case .closeWarning:   return "CLOSE WARNING"
        case .hardExit:       return "SESSION CLOSE"
        case .afterHours:     return "AFTER HOURS"
        }
    }
}

// MARK: - Derivation

extension DeskState {
    /// Compute the current desk state from clock + open positions.
    /// Session-close / close-warning states take precedence over open position so the
    /// takeover always fires in the correct window.
    ///
    /// `openPositionTimestamps` is retained for older call sites, but the
    /// active quote/alert session now consistently runs through the 16:15 ET
    /// extended close.
    @MainActor
    static func current(
        timeManager: TimeManager,
        openPositions: Int,
        openPositionTimestamps: [Date] = []
    ) -> DeskState {
        let eastern = TimeZone(identifier: "America/New_York")!
        let comps = Calendar.current.dateComponents(in: eastern, from: Date())
        guard let h = comps.hour, let m = comps.minute else { return .betweenWindows }
        let t = h * 60 + m

        if t < StrategySpec.preMarketCutoffMinutes { return .preMarket }
        if t >= StrategySpec.afterHoursMinutes { return .afterHours }

        let hardExit = StrategySpec.hardExitMinutes(forOpenedAt: openPositionTimestamps)
        let closeWarning = hardExit - 5   // 5-minute warning regardless of cutoff
        if t >= hardExit { return .hardExit }
        if t >= closeWarning { return .closeWarning }

        if openPositions > 0 { return .openPosition(activeCount: openPositions) }
        if let window = timeManager.activeWindow { return .windowOpen(window) }
        return .betweenWindows
    }
}
