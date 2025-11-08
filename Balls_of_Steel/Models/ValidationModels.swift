import Foundation
import SwiftUI

struct ValidationResult {
    let volumeValid: Bool
    let priceValid: Bool
    let timeValid: Bool
    
    var isValid: Bool {
        volumeValid && priceValid && timeValid
    }
    
    var strength: SignalStrength {
        let validCount = [volumeValid, priceValid, timeValid]
            .filter { $0 }
            .count
        
        switch validCount {
        case 3: return .strong
        case 2: return .medium
        default: return .weak
        }
    }
    
    static func validate(quote: Quote, 
                        strategy: Strategy,
                        volumeProfile: VolumeProfile) -> ValidationResult {
        
        let tm = TimeManager.shared
        let timeValid = strategy.timeWindow.isActive
        
        let volumeValid = volumeProfile.isHighVolume
        
        let priceValid = switch strategy {
        case .gapUp:
            quote.gapPercentage >= MarketRules.gapThreshold * 100
        case .gapDown:
            quote.gapPercentage <= -MarketRules.gapThreshold * 100
        case .middayReversal:
            abs(quote.gapPercentage) >= MarketRules.vwapDeviation * 100
        case .powerHour:
            true // Price validation handled by options flow
        }
        
        return ValidationResult(
            volumeValid: volumeValid,
            priceValid: priceValid,
            timeValid: timeValid
        )
    }
}

enum SignalStrength {
    case strong
    case medium
    case weak
    
    var color: Color {
        switch self {
        case .strong: return .green
        case .medium: return .yellow
        case .weak: return .red
        }
    }
} 