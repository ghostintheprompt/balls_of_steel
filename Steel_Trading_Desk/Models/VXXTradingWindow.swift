import Foundation

// MARK: - VXX Trading Windows
//
// The three doc-published entry windows from `docs/trading docs/`. Lunch is
// retained as a case for display in the manual time-window picker but is NOT
// an entry window per the strategy spec (see `TimeWindowInput.isVXXEntryWindow`
// and StrategySpec drift fix 2026-05-14). Canonical bounds live in
// `StrategySpec.morningWindow` / `powerHourWindow` / `institutionalWindow`.

enum VXXTradingWindow {
    case morning        // 9:50-10:15 AM ET — Morning Fade
    case lunch          // 12:20-12:40 PM ET — NOT an entry window
    case powerHour      // 3:10-3:25 PM ET — Power Hour
    case institutional  // 3:45-4:10 PM ET — Institutional Flow

    var displayName: String {
        switch self {
        case .morning:       return "Morning Window (9:50 AM)"
        case .lunch:         return "Lunch Window (12:20 PM)"
        case .powerHour:     return "Power Hour (3:10 PM)"
        case .institutional: return "Institutional Flow (3:45 PM)"
        }
    }

    var timeRange: String {
        switch self {
        case .morning:       return "9:50-10:15 AM"
        case .lunch:         return "12:20-12:40 PM"
        case .powerHour:     return "3:10-3:25 PM"
        case .institutional: return "3:45-4:10 PM"
        }
    }

    var priority: Int {
        switch self {
        case .institutional: return 1   // Doc's supreme window
        case .morning:       return 2
        case .powerHour:     return 3
        case .lunch:         return 4   // Not an entry window — display only
        }
    }
}
