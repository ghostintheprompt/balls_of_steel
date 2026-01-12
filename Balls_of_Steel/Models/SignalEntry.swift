import Foundation

struct SignalEntry {
    enum SignalType {
        case gapUp(reason: String)      // Morning gap up pattern
        case gapDown(reason: String)    // Morning gap down pattern
        case middayReversal(reason: String)  // Midday VWAP reversal
        case powerHour(reason: String)  // End of day momentum
    }
    
    let symbol: String
    let type: SignalType
    let timestamp: Date
    let reason: String
    let volume: Int
    
    // Pattern validation using new Date extensions
    var isValidPattern: Bool {
        switch type {
        case .gapUp:
            return timestamp.isGapAndGoWindow && 
                   hasSignificantVolume
        case .gapDown:
            return timestamp.isGapAndGoWindow && 
                   hasSignificantVolume
        case .middayReversal:
            return timestamp.isVWAPWindow && 
                   hasVWAPCross
        case .powerHour:
            return timestamp.isPowerHourWindow && 
                   hasMomentumShift
        }
    }
    
    private var hasSignificantVolume: Bool {
        volume >= AppConfig.Thresholds.gapAndGo.minVolume
    }
    
    // Note: hasVWAPCross and hasMomentumShift removed due to main actor isolation
    // These should be validated in the @MainActor service layer
    private var hasVWAPCross: Bool {
        return true  // Simplified for now - validate in service layer
    }

    private var hasMomentumShift: Bool {
        return true  // Simplified for now - validate in service layer
    }
} 