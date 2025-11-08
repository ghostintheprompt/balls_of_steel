import Foundation

// Add TimeManager for market time definitions
struct ExitRules {
    enum ExitType {
        case gapAndGo
        case vwapReversal
        case powerHour
        case panicReversal
    }
    
    struct ExitConditions {
        // Pattern specific thresholds
        let priceThreshold: Double
        let volumeThreshold: Int
        let timeWindow: ClosedRange<Date>
        
        static func forStrategy(_ strategy: Strategy) -> ExitConditions {
            let tm = TimeManager.shared
            
            switch strategy {
            case .gapAndGo:
                return .init(
                    priceThreshold: 0.985,  // -1.5% from entry
                    volumeThreshold: 100_000,
                    timeWindow: tm.gapAndGoWindow
                )
            case .vwapReversal:
                return .init(
                    priceThreshold: 0.02,   // 2% from VWAP
                    volumeThreshold: 500_000,
                    timeWindow: tm.vwapReversalWindow
                )
            case .powerHour:
                return .init(
                    priceThreshold: 0.01,   // 1% momentum loss
                    volumeThreshold: 750_000,
                    timeWindow: tm.powerHourWindow
                )
            case .panicReversal:
                return .init(
                    priceThreshold: 0.03,   // 3% bounce
                    volumeThreshold: 2_000_000,
                    // Panic plays can happen anytime during market hours
                    timeWindow: tm.marketOpen...tm.marketClose
                )
            }
        }
    }
} 