import Foundation

struct Signal: Identifiable {
    let id = UUID()
    let symbol: String
    let strategy: Strategy
    let direction: TradeDirection
    let entry: Double
    let stop: Double
    let target: Double
    let timestamp: Date
    let confidence: Double
    let setupQuality: Strategy.SetupQuality
    let positionSizePercent: Double
    let kind: SignalKind
    
    var winRate: Double {
        strategy.historicalWinRate
    }

    // Note: isValid removed due to main actor isolation issues
    // Use SignalMonitor to validate signals instead
    
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

enum TradeDirection {
    case bullish
    case bearish

    var displayName: String {
        switch self {
        case .bullish: return "Bullish"
        case .bearish: return "Bearish"
        }
    }

    var optionLabel: String {
        switch self {
        case .bullish: return "Calls"
        case .bearish: return "Puts"
        }
    }

    var colorName: String {
        switch self {
        case .bullish: return "green"
        case .bearish: return "red"
        }
    }
}

enum SignalKind {
    case entry
    case watch
    case exit

    var displayName: String {
        switch self {
        case .entry: return "ENTRY"
        case .watch: return "WATCH"
        case .exit: return "EXIT"
        }
    }
}

extension Strategy {
    var criteria: TradeCriteria {
        // Default criteria - customize for each strategy
        switch self {
        case .gapAndGo:
            return .init(
                volumeThreshold: 500_000,
                priceAction: .gapUp(2.0),
                stopLoss: 0.5,
                target: 2.0
            )
        case .vwapReversal:
            return .init(
                volumeThreshold: 750_000,
                priceAction: .vwapCross,
                stopLoss: 0.75,
                target: 1.5
            )
        case .powerHour:
            return .init(
                volumeThreshold: 750_000,
                priceAction: .momentum,
                stopLoss: 0.75,
                target: 1.5
            )
        case .panicReversal:
            return .init(
                volumeThreshold: 2_000_000,
                priceAction: .panicDrop,
                stopLoss: 1.0,
                target: 3.0
            )
        default:
            return .init(
                volumeThreshold: 500_000,
                priceAction: .momentum,
                stopLoss: 0.5,
                target: 1.5
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
                direction: .bullish,
                entry: data.quote.price,
                stop: data.quote.price * (1 - AppConfig.Thresholds.gapAndGo.stopLoss/100),
                target: data.quote.price * (1 + AppConfig.Thresholds.gapAndGo.target/100),
                timestamp: data.quote.timestamp,
                confidence: 0.75,
                setupQuality: .good,
                positionSizePercent: 2.0,
                kind: .entry
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
                direction: .bullish,
                entry: data.quote.price,
                stop: data.quote.price * (1 - AppConfig.Thresholds.vwapReversal.stopLoss/100),
                target: data.quote.price * (1 + AppConfig.Thresholds.vwapReversal.target/100),
                timestamp: data.quote.timestamp,
                confidence: 0.70,
                setupQuality: .good,
                positionSizePercent: 2.0,
                kind: .entry
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
                direction: .bullish,
                entry: data.quote.price,
                stop: data.quote.price * (1 - AppConfig.Thresholds.powerHour.stopLoss/100),
                target: data.quote.price * (1 + AppConfig.Thresholds.powerHour.target/100),
                timestamp: data.quote.timestamp,
                confidence: 0.80,
                setupQuality: .perfect,
                positionSizePercent: 2.5,
                kind: .entry
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
                direction: .bullish,
                entry: data.quote.price,
                stop: data.quote.price * (1 - AppConfig.Thresholds.panicReversal.stopLoss/100),
                target: data.quote.price * (1 + AppConfig.Thresholds.panicReversal.target/100),
                timestamp: data.quote.timestamp,
                confidence: 0.65,
                setupQuality: .good,
                positionSizePercent: 1.5,
                kind: .entry
            )
        default:
            // Handle all other strategies with default values
            return nil
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
                volumeThreshold: 500_000,
                priceAction: .gapUp(2.0),
                stopLevel: 0.5,
                targetLevel: 2.0
            )
        case .vwapReversal:
            return .init(
                timeWindow: "11:30-13:30",
                volumeThreshold: 750_000,
                priceAction: .vwapCross,
                stopLevel: 1.0,
                targetLevel: 2.0
            )
        case .powerHour:
            return .init(
                timeWindow: "15:00-16:00",
                volumeThreshold: 1_000_000,
                priceAction: .momentum,
                stopLevel: 0.75,
                targetLevel: 1.5
            )
        case .panicReversal:
            return .init(
                timeWindow: "Any",
                volumeThreshold: 2_000_000,
                priceAction: .panicDrop,
                stopLevel: 1.0,
                targetLevel: 3.0
            )
        }
    }
} 
