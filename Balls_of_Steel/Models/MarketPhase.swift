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
        case .preMarket: return .orange
        case .opening: return .green
        case .midday: return .blue
        case .powerHour: return .purple
        case .afterHours: return .red
        case .regular: return .blue
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