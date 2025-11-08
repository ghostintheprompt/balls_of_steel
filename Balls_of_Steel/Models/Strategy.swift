enum Strategy: String, CaseIterable {
    case earningsVolatilityCrush = "Earnings Volatility Crush"
    case gapFill = "Gap Fill Trading"
    case zdteIronButterfly = "0DTE Iron Butterfly"
    case vixSpikePremiumSelling = "VIX Spike Premium Selling"
    case momentumBreakout = "Momentum Breakout"
    case preMarketInstitutionalFlow = "Pre-Market Institutional Flow"
    case weeklyOptionsExpiration = "Weekly Options Expiration"
    
    // Legacy strategies (updated with refined criteria)
    case gapAndGo = "Gap and Go"
    case vwapReversal = "VWAP Reversal"
    case powerHour = "Power Hour"
    case panicReversal = "Panic Reversal"
    
    struct Criteria {
        let timeWindow: ClosedRange<Date>
        let volumeThreshold: Int
        let priceAction: PriceAction
        let stopLoss: Double
        let target: Double
    }
    
    enum PriceAction {
        case gapUp(percent: Double)
        case vwapCross(deviation: Double)
        case momentum(bars: Int)
        case panicDrop(percent: Double)
        
        var threshold: Double {
            switch self {
            case .gapUp(let percent): return percent
            case .vwapCross(let dev): return dev
            case .momentum: return 0 // Not used
            case .panicDrop(let percent): return percent
            }
        }
    }
    
    // Missing methods referenced in SignalScanner
    static func validateBaseCriteria(_ data: MarketData) -> Bool {
        // Basic validation - market hours, minimum volume, etc.
        return data.isMarketHours && data.volume > 100_000
    }
    
    func validateCriteria(_ data: MarketData) -> Bool {
        switch self {
        case .earningsVolatilityCrush:
            // IV Rank > 75%, 2-3 days before earnings
            return data.ivRank > 75 && data.daysToEarnings <= 3
            
        case .gapFill:
            // Gap size 0.5-2%, no fundamental news, volume declining
            return abs(data.gapPercent) >= 0.5 && abs(data.gapPercent) <= 2.0 && 
                   !data.hasFundamentalNews && data.isVolumeDecline
            
        case .zdteIronButterfly:
            // Same day expiry, VIX < 25, low volatility, after 10:15 AM
            return data.hasZDTEOptions && data.vix < 25 && 
                   data.timestamp.timeIntervalSince1970 > data.marketOpen + (45 * 60) // After 10:15
            
        case .vixSpikePremiumSelling:
            // VIX spike > 15%, VIX > 30, SPY down > 1.5%
            return data.vixDailyChange > 15 && data.vix > 30 && data.spyDailyChange < -1.5
            
        case .momentumBreakout:
            // VWAP break, volume > 2x average, RSI > 60, EMA crossover
            return data.vwapBreakout && data.volume >= data.averageVolume * 2 && 
                   data.rsi > 60 && data.emaBreakout
            
        case .preMarketInstitutionalFlow:
            // 8:00-9:00 AM, options volume > 3x normal
            return data.timestamp.isPreMarketInstitutionalWindow && 
                   data.optionsVolume >= data.averageOptionsVolume * 3
            
        case .weeklyOptionsExpiration:
            // Friday expiration, OTM options with < 20% probability
            return data.isWeeklyExpiration && data.otmProbability < 0.20
            
        // Updated legacy strategies with refined criteria
        case .gapAndGo:
            return abs(data.gapPercent) >= 0.5 && abs(data.gapPercent) <= 2.0 && 
                   data.volume >= 500_000 // Gap fill strategy criteria
        case .vwapReversal:
            return data.volume >= 750_000 && abs(data.vwapDeviation) >= 0.5
        case .powerHour:
            return data.volume >= 1_000_000 && data.consecutiveGreenBars >= 2
        case .panicReversal:
            return data.dropPercent >= 3.0 && data.volumeSpike >= 2_000_000
        }
    }
    
    func createSignal(_ data: MarketData) -> Signal {
        let confidence = calculateConfidence(data)
        let setupQuality = determineSetupQuality(data, confidence: confidence)
        
        // Calculate entry, stop, and target based on strategy
        let entry = data.currentPrice
        let stop: Double
        let target: Double
        
        switch self {
        case .gapAndGo, .gapFill:
            stop = entry * 0.985   // 1.5% stop loss
            target = entry * 1.02  // 2% target
        case .vwapReversal:
            stop = entry * 0.9925  // 0.75% stop loss
            target = entry * 1.015 // 1.5% target
        case .powerHour:
            stop = entry * 0.9925  // 0.75% stop loss
            target = entry * 1.015 // 1.5% target
        case .panicReversal:
            stop = entry * 0.99    // 1% stop loss
            target = entry * 1.03  // 3% target
        default:
            stop = entry * 0.99    // 1% default stop loss
            target = entry * 1.02  // 2% default target
        }
        
        return Signal(
            symbol: data.symbol,
            strategy: self,
            entry: entry,
            stop: stop,
            target: target,
            timestamp: Date(),
            confidence: confidence,
            setupQuality: setupQuality,
            positionSizePercent: getPositionSize(vix: data.vix, setupQuality: setupQuality)
        )
    }
    
    private func calculateConfidence(_ data: MarketData) -> Double {
        switch self {
        case .earningsVolatilityCrush:
            let ivScore = min(data.ivRank / 100.0, 1.0)
            let timeScore = data.daysToEarnings <= 2 ? 1.0 : 0.7
            return (ivScore + timeScore) / 2.0
            
        case .gapFill:
            let gapScore = 1.0 - (abs(abs(data.gapPercent) - 1.25) / 1.25) // Optimal at 1.25%
            let volumeScore = data.isVolumeDecline ? 1.0 : 0.5
            return max(0.3, (gapScore + volumeScore) / 2.0)
            
        case .zdteIronButterfly:
            let vixScore = data.vix < 20 ? 1.0 : max(0.3, 1.0 - (data.vix - 20) / 30)
            let timeScore = data.minutesSinceMarketOpen > 45 ? 1.0 : 0.6
            return (vixScore + timeScore) / 2.0
            
        case .vixSpikePremiumSelling:
            let spikeScore = min(data.vixDailyChange / 30.0, 1.0) // Max at 30% spike
            let levelScore = min((data.vix - 30) / 20.0, 1.0) // Max at VIX 50
            return (spikeScore + levelScore) / 2.0
            
        case .momentumBreakout:
            let volumeScore = min(Double(data.volume) / Double(data.averageVolume * 3), 1.0)
            let technicalScore = (data.rsi - 60) / 40.0 // 0 at RSI 60, 1 at RSI 100
            return (volumeScore + technicalScore) / 2.0
            
        default:
            // Legacy confidence calculation
            let volumeScore = min(Double(data.volume) / 1_000_000, 1.0)
            let priceScore = min(abs(data.gapPercent) / 5.0, 1.0)
            return (volumeScore + priceScore) / 2.0
        }
    }
    
    private func determineSetupQuality(_ data: MarketData, confidence: Double) -> SetupQuality {
        switch confidence {
        case 0.8...: return .perfect
        case 0.6..<0.8: return .good
        default: return .marginal
        }
    }
    
    // Historical success rates from your trading document
    var historicalWinRate: Double {
        switch self {
        case .earningsVolatilityCrush: return 0.727  // 72.7%
        case .gapFill: return 0.78                   // 78% for small gaps
        case .zdteIronButterfly: return 0.668        // 66.8%
        case .vixSpikePremiumSelling: return 0.68    // 68%
        case .momentumBreakout: return 0.65          // 65%
        case .preMarketInstitutionalFlow: return 0.70 // Estimated
        case .weeklyOptionsExpiration: return 0.75   // Estimated
        case .gapAndGo: return 0.70                  // Updated
        case .vwapReversal: return 0.68              // Updated  
        case .powerHour: return 0.65                 // Updated
        case .panicReversal: return 0.72             // Updated
        }
    }
    
    // Position sizing based on VIX and setup quality
    func getPositionSize(vix: Double, setupQuality: SetupQuality) -> Double {
        let baseSize = switch setupQuality {
        case .perfect: 2.0
        case .good: 1.0
        case .marginal: 0.5
        }
        
        // VIX-based adjustment from your risk management rules
        let vixMultiplier = switch vix {
        case 0..<20: 1.0
        case 20..<30: 0.75  // Reduce to 1.5% max
        case 30..<40: 0.5   // Reduce to 1% max
        case 40...: 0.25    // Reduce to 0.5% max
        default: 0.5
        }
        
        return baseSize * vixMultiplier
    }
    
    enum SetupQuality {
        case perfect  // All conditions met, high conviction
        case good     // Most conditions met, moderate conviction
        case marginal // Few conditions met, low conviction
    }
}