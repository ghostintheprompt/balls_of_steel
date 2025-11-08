import WidgetKit
import SwiftUI

struct WidgetConfiguration {
    // MARK: - Refresh Settings
    static let refreshInterval: TimeInterval = 60 // 1 minute base interval
    static let maxSignals = 3
    static let retryInterval: TimeInterval = 300 // 5 minutes on error
    
    // MARK: - Platform Support
    static var supportedFamilies: [WidgetFamily] {
        if #available(macOS 13.0, iOS 16.0, *) {
            return [.systemSmall, .systemMedium, .systemLarge]
        } else {
            return [.systemSmall, .systemMedium]
        }
    }
    
    // MARK: - Intelligent Update Timing
    static func nextUpdateDate() -> Date {
        let now = Date()
        let currentPhase = TimeManager.shared.currentPhase()
        
        // Adjust update frequency based on market phase
        let interval: TimeInterval = switch currentPhase {
        case .opening, .powerHour:
            30 // 30 seconds during high-activity periods
        case .preMarket, .regular, .midday:
            60 // 1 minute during normal trading
        case .afterHours:
            300 // 5 minutes when market is closed
        }
        
        return now.addingTimeInterval(interval)
    }
    
    // MARK: - Widget Content Settings
    static func maxSignalsForFamily(_ family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 3
        case .systemLarge:
            return 5
        @unknown default:
            return 1
        }
    }
    
    // MARK: - Performance Settings
    static let backgroundRefreshThreshold: TimeInterval = 900 // 15 minutes
    static let maxRetryAttempts = 3
    
    // MARK: - Display Settings
    static let animationDuration: Double = 0.3
    static let compactMode = true // Optimized for widget display
    
    // MARK: - Debug Settings
    #if DEBUG
    static let debugMode = true
    static let mockDataEnabled = false
    #else
    static let debugMode = false
    static let mockDataEnabled = false
    #endif
} 