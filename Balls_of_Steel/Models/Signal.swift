import Foundation

struct Signal {
    let id = UUID()
    let symbol: String
    let strategy: Strategy
    let entry: Double
    let stop: Double
    let target: Double
    let timestamp: Date
    let confidence: Double
    let setupQuality: Strategy.SetupQuality
    let positionSizePercent: Double
    
    var winRate: Double {
        strategy.historicalWinRate
    }
    
    var isValid: Bool {
        guard let marketData = try? MarketDataService.shared.latestQuote(symbol: symbol) else {
            return false
        }
        
        let validation = ValidationResult.validate(
            quote: marketData,
            strategy: strategy,
            volumeProfile: VolumeProfile(
                averageVolume: Double(marketData.volume),
                currentVolume: Double(marketData.volume)
            )
        )
        
        return validation.isValid
    }
    
    // Risk-reward ratio
    var riskRewardRatio: Double {
        let risk = abs(entry - stop)
        let reward = abs(target - entry)
        return risk > 0 ? reward / risk : 0
    }
    
    // Expected value based on win rate and risk/reward
    var expectedValue: Double {
        let risk = abs(entry - stop)
        let reward = abs(target - entry)
        return (winRate * reward) - ((1 - winRate) * risk)
    }
}

extension Strategy {
    var criteria: TradeCriteria {
        let tm = TimeManager.shared
        
        switch self {
        case .gapAndGo:
            return .init(
                timeWindow: tm.gapAndGoWindow,
                volumeThreshold: 500_000,
                priceAction: .gapUp(percent: 2.0),
                stopLoss: 0.5,
                target: 2.0
            )
        case .vwapReversal:
            return .init(
                timeWindow: tm.vwapReversalWindow,
                volumeThreshold: 750_000,
                priceAction: .vwapCross,
                stopLoss: 0.75,
                target: 1.5
            )
        case .powerHour:
            return .init(
                timeWindow: tm.powerHourWindow,
                volumeThreshold: 750_000,
                priceAction: .vwapCross,
                stopLoss: 0.75,
                target: 1.5
            )
        case .panicReversal:
            return .init(
                timeWindow: tm.marketOpen...tm.marketClose,
                volumeThreshold: 2_000_000,
                priceAction: .panicDrop,
                stopLoss: 1.0,
                target: 3.0
            )
        }
    }
    
    func matches(_ data: MarketData) -> Signal? {
        let criteria = self.criteria
        
        // First check if we're in the right trading window
        guard data.quote.timestamp.isWithinTradingHours() else { return nil }
        
        switch self {
        case .gapAndGo:
            guard data.quote.timestamp.isGapAndGoWindow,
                  data.quote.gapPercent >= criteria.priceAction.threshold,
                  data.hasSignificantVolume else {
                return nil
            }
            
            return Signal(
                symbol: data.quote.symbol,
                strategy: self,
                entry: data.quote.price,
                stop: data.quote.price * (1 - AppConfig.Thresholds.gapAndGo.stopLoss/100),
                target: data.quote.price * (1 + AppConfig.Thresholds.gapAndGo.target/100),
                timestamp: data.quote.timestamp
            )
            
        case .vwapReversal:
            guard data.quote.timestamp.isVWAPWindow,
                  data.hasVWAPDeviation,
                  data.hasSignificantVolume else {
                return nil
            }
            
            return Signal(
                symbol: data.quote.symbol,
                strategy: self,
                entry: data.quote.price,
                stop: data.quote.price * (1 - AppConfig.Thresholds.vwapReversal.stopLoss/100),
                target: data.quote.price * (1 + AppConfig.Thresholds.vwapReversal.target/100),
                timestamp: data.quote.timestamp
            )
            
        case .powerHour:
            guard data.quote.timestamp.isPowerHourWindow,
                  data.quote.hasMomentum,
                  data.hasSignificantVolume else {
                return nil
            }
            
            return Signal(
                symbol: data.quote.symbol,
                strategy: self,
                entry: data.quote.price,
                stop: data.quote.price * (1 - AppConfig.Thresholds.powerHour.stopLoss/100),
                target: data.quote.price * (1 + AppConfig.Thresholds.powerHour.target/100),
                timestamp: data.quote.timestamp
            )
            
        case .panicReversal:
            // Panic plays can happen anytime during market hours
            guard data.quote.timestamp.isWithinTradingHours(),
                  data.quote.showsReversal,
                  data.hasSignificantVolume else {
                return nil
            }
            
            return Signal(
                symbol: data.quote.symbol,
                strategy: self,
                entry: data.quote.price,
                stop: data.quote.price * (1 - AppConfig.Thresholds.panicReversal.stopLoss/100),
                target: data.quote.price * (1 + AppConfig.Thresholds.panicReversal.target/100),
                timestamp: data.quote.timestamp
            )
        }
    }
}

// Keep the Pattern enum as is
enum Pattern {
    case gapAndGo
    case vwapReversal  
    case powerHour
    case panicReversal
    
    var criteria: PatternCriteria {
        switch self {
        case .gapAndGo:
            return .init(
                timeWindow: "9:30-10:00",
                volumeThreshold: 500_000,  // Your exact volume requirement
                priceAction: .gapUp(2.0),  // Your exact gap % requirement
                stopLevel: 0.5,            // Your exact stop
                targetLevel: 2.0           // Your exact target
            )
        // Other patterns with your exact numbers
        }
    }
} 