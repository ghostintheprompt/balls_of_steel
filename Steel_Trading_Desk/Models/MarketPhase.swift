import Foundation
import SwiftUI

enum MarketPhase: String, CaseIterable {
    case preMarket = "Pre-Market"
    case opening = "Market Open"
    case midday = "Midday"
    case powerHour = "Power Hour"
    case afterHours = "After Hours"
    case regular = "Regular Hours"
    
    var color: Color {
        switch self {
        case .preMarket: return DesignSystem.amber
        case .opening: return DesignSystem.long
        case .midday: return DesignSystem.steel
        case .powerHour: return DesignSystem.amber
        case .afterHours: return DesignSystem.short
        case .regular: return DesignSystem.steel
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
    
    var isMarketOpen: Bool {
        switch self {
        case .opening, .midday, .powerHour, .regular:
            return true
        case .preMarket, .afterHours:
            return false
        }
    }
} 