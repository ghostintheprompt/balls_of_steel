import Foundation

// MARK: - VXX Trading Windows
// High-probability trading windows based on institutional flow patterns

enum VXXTradingWindow {
    case morning        // 9:50-10:00 AM - Morning fade window
    case lunch          // 12:20-12:35 PM - Lunch window
    case powerHour      // 3:10-3:25 PM - Power hour window
    case institutional  // 3:45-4:10 PM - Institutional flow window (90% win rate)

    var displayName: String {
        switch self {
        case .morning:
            return "Morning Window (9:50 AM)"
        case .lunch:
            return "Lunch Window (12:20 PM)"
        case .powerHour:
            return "Power Hour (3:10 PM)"
        case .institutional:
            return "Institutional Flow (3:45 PM)"
        }
    }

    var timeRange: String {
        switch self {
        case .morning:
            return "9:50-10:00 AM"
        case .lunch:
            return "12:20-12:35 PM"
        case .powerHour:
            return "3:10-3:25 PM"
        case .institutional:
            return "3:45-4:10 PM"
        }
    }

    var winRate: Double {
        switch self {
        case .institutional:
            return 0.90  // 90% win rate - highest probability
        case .morning:
            return 0.85
        case .powerHour:
            return 0.80
        case .lunch:
            return 0.70
        }
    }

    var priority: Int {
        switch self {
        case .institutional:
            return 1  // Highest priority
        case .morning:
            return 2
        case .powerHour:
            return 3
        case .lunch:
            return 4
        }
    }
}
