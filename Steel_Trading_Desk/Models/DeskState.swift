import Foundation

// MARK: - DeskState (Phase 7)
//
// Single piece of state that drives what the desk screen actually shows.
// Every visual transition in the app keys off this — pre-market quiet,
// active window, open position, close warning, hard exit, after-hours.
//
// Derived from TimeManager + SignalMonitor; never set directly by views.

enum DeskState: Equatable {
    case preMarket          // before 9:30 ET
    case betweenWindows     // market open, no active trading window
    case windowOpen(VXXTradingWindow)
    case openPosition(activeCount: Int)
    case closeWarning       // 15:50–15:55 ET
    case hardExit           // 15:55–16:10 ET — UI takes over
    case afterHours         // ≥ 16:10 ET

    /// True when the screen should be replaced by the hard-exit takeover.
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
        case .hardExit:       return "HARD EXIT"
        case .afterHours:     return "AFTER HOURS"
        }
    }
}

// MARK: - Derivation

extension DeskState {
    /// Compute the current desk state from clock + open positions.
    /// Hard-exit / close-warning take precedence over open position so the
    /// takeover always fires in the correct window.
    @MainActor
    static func current(timeManager: TimeManager, openPositions: Int) -> DeskState {
        let eastern = TimeZone(identifier: "America/New_York")!
        let comps = Calendar.current.dateComponents(in: eastern, from: Date())
        guard let h = comps.hour, let m = comps.minute else { return .betweenWindows }
        let t = h * 60 + m

        if t < 9 * 60 + 30 { return .preMarket }
        if t >= 16 * 60 + 10 { return .afterHours }
        if t >= 15 * 60 + 55 { return .hardExit }
        if t >= 15 * 60 + 50 { return .closeWarning }

        if openPositions > 0 { return .openPosition(activeCount: openPositions) }
        if let window = timeManager.activeWindow { return .windowOpen(window) }
        return .betweenWindows
    }
}
