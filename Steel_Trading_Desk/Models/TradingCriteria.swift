import Foundation

struct TradeCriteria {
    let volumeThreshold: Int
    let priceAction: PriceAction
    let stopLoss: Double
    let target: Double

    // Legacy init with timeWindow
    init(timeWindow: ClosedRange<Date>, volumeThreshold: Int, priceAction: PriceAction, stopLoss: Double, target: Double) {
        self.volumeThreshold = volumeThreshold
        self.priceAction = priceAction
        self.stopLoss = stopLoss
        self.target = target
    }

    // Simplified init without timeWindow
    init(volumeThreshold: Int, priceAction: PriceAction, stopLoss: Double, target: Double) {
        self.volumeThreshold = volumeThreshold
        self.priceAction = priceAction
        self.stopLoss = stopLoss
        self.target = target
    }
}

struct PatternCriteria {
    let timeWindow: String
    let volumeThreshold: Int
    let priceAction: PriceAction
    let stopLevel: Double
    let targetLevel: Double
}

enum PriceAction {
    case gapUp(Double)
    case vwapCross
    case momentum
    case panicDrop
    
    var threshold: Double {
        switch self {
        case .gapUp(let value): return value
        case .vwapCross: return 0.5 // 0.5% deviation
        case .momentum: return 0.0   // Not used
        case .panicDrop: return 3.0  // 3% drop
        }
    }
} 