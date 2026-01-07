import Foundation

enum Strategy: String, CaseIterable {
    // v3.0: Institutional Flow Edition (FREE)
    case vxxInstitutionalFlow = "VXX Institutional Flow (3:45 PM)" // 90% reliability ⭐⭐⭐

    // VXX-specific strategies (5 core VXX strategies)
    case vxxFadeSetup = "VXX Fade Setup"
    case vxxPowerHour = "VXX Power Hour (3:10 PM)"
    case vxxMorningWindow = "VXX Morning Window (9:50 AM)"
    case vxxVolumeSpike = "VXX Volume Spike"
    case vxxLunchWindow = "VXX Lunch Window (12:20 PM)"

    // Additional strategies (11 more for 16 total)
    case consolidationBreakout = "Consolidation Breakout"
    case movingAverageCross = "Moving Average Cross"
    case earningsPlay = "Earnings Play"
    case vixSpike = "VIX Spike"
    case zeroDTE = "0DTE Options"
    case momentumReversal = "Momentum Reversal"
    case gapAndGo = "Gap and Go"
    case vwapReversal = "VWAP Reversal"
    case powerHour = "Power Hour"
    case panicReversal = "Panic Reversal"
    case weeklyOptionsExpiration = "Weekly Options Expiration"
    
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
        // v3.0: Institutional Flow (FREE strategy)
        case .vxxInstitutionalFlow:
            // 3:45-4:10 PM Institutional Flow Window - 90% reliability
            // Portfolio rebalancing, mutual fund flows, index fund rebalancing
            // Volume explosion >300% = Institutional threshold
            return data.symbol == "VXX" &&
                   data.timestamp.isInstitutionalFlowWindow &&
                   data.volume >= Int(Double(data.averageVolume) * 3.0) && // 300%+ institutional threshold
                   data.hasArrowSignal // Arrow signal confirmation required

        // VXX-specific strategies
        case .vxxFadeSetup:
            // VXX fade: Above resistance, bearish pattern (Shooting Star/Hanging Man), volume 150%+
            return data.symbol == "VXX" &&
                   data.hasPattern &&
                   data.patternType == .bearish &&
                   data.volume >= Int(Double(data.averageVolume) * 1.5)

        case .vxxPowerHour:
            // 3:10-3:25 PM window: Pattern + volume + reversal setup
            return data.symbol == "VXX" &&
                   data.timestamp.isVXXPowerHourWindow &&
                   data.hasPattern &&
                   data.volume >= Int(Double(data.averageVolume) * 1.5)

        case .vxxMorningWindow:
            // 9:50-10:00 AM window: Pattern + volume confirmation
            return data.symbol == "VXX" &&
                   data.timestamp.isVXXMorningWindow &&
                   data.hasPattern &&
                   data.volume >= Int(Double(data.averageVolume) * 1.5)

        case .vxxVolumeSpike:
            // Volume surge (200%+) + any pattern
            return data.symbol == "VXX" &&
                   data.volume >= Int(Double(data.averageVolume) * 2.0) &&
                   data.hasPattern

        case .vxxLunchWindow:
            // 12:20-12:35 PM window: Pattern + volume + VIX context
            return data.symbol == "VXX" &&
                   data.timestamp.isVXXLunchWindow &&
                   data.hasPattern &&
                   data.volume >= data.averageVolume

        // Additional strategies
        case .consolidationBreakout:
            // Breakout from consolidation with volume confirmation
            return data.volume >= Int(Double(data.averageVolume) * 2.0) &&
                   abs(data.gapPercent) >= 1.0

        case .movingAverageCross:
            // Moving average crossover with momentum
            return data.emaBreakout && data.volume >= Int(Double(data.averageVolume) * 1.5)

        case .earningsPlay:
            // Earnings play with high IV
            return data.ivRank > 60 && data.daysToEarnings <= 5

        case .vixSpike:
            // VIX spike play
            return data.vixDailyChange > 10 && data.vix > 25

        case .zeroDTE:
            // 0DTE options strategy
            return data.hasZDTEOptions && data.vix < 30

        case .momentumReversal:
            // Momentum reversal setup
            return data.rsi > 70 && data.volumeSpike >= data.averageVolume * 2

        case .gapAndGo:
            return abs(data.gapPercent) >= 0.5 && abs(data.gapPercent) <= 2.0 &&
                   data.volume >= 500_000

        case .vwapReversal:
            return data.volume >= 750_000 && abs(data.vwapDeviation) >= 0.5

        case .powerHour:
            return data.volume >= 1_000_000 && data.consecutiveGreenBars >= 2

        case .panicReversal:
            return data.dropPercent >= 3.0 && data.volumeSpike >= 2_000_000

        case .weeklyOptionsExpiration:
            return data.isWeeklyExpiration && data.otmProbability < 0.20
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
        // v3.0: Institutional Flow
        case .vxxInstitutionalFlow:
            // Very high confidence - 90% win rate strategy
            let volumeScore = min(Double(data.volume) / Double(data.averageVolume * 4), 1.0)
            let windowScore = data.timestamp.isInstitutionalFlowWindow ? 1.0 : 0.3
            let arrowScore = data.hasArrowSignal ? 1.0 : 0.0
            return (volumeScore + windowScore + arrowScore) / 3.0

        // VXX strategies
        case .vxxFadeSetup, .vxxPowerHour, .vxxMorningWindow, .vxxVolumeSpike, .vxxLunchWindow:
            let volumeScore = min(Double(data.volume) / Double(data.averageVolume * 2), 1.0)
            let patternScore = data.hasPattern ? 1.0 : 0.3
            return (volumeScore + patternScore) / 2.0

        // Additional strategies
        case .earningsPlay:
            let ivScore = min(data.ivRank / 100.0, 1.0)
            let timeScore = data.daysToEarnings <= 3 ? 1.0 : 0.6
            return (ivScore + timeScore) / 2.0

        case .vixSpike:
            let spikeScore = min(data.vixDailyChange / 20.0, 1.0)
            let levelScore = min((data.vix - 25) / 25.0, 1.0)
            return (spikeScore + levelScore) / 2.0

        case .zeroDTE:
            let vixScore = data.vix < 25 ? 1.0 : max(0.3, 1.0 - (data.vix - 25) / 20)
            return vixScore

        case .momentumReversal:
            let rsiScore = data.rsi > 70 ? 1.0 : data.rsi / 70.0
            let volumeScore = min(Double(data.volume) / Double(data.averageVolume * 2), 1.0)
            return (rsiScore + volumeScore) / 2.0

        default:
            // General confidence calculation
            let volumeScore = min(Double(data.volume) / Double(data.averageVolume * 2), 1.0)
            let priceScore = min(abs(data.gapPercent) / 3.0, 1.0)
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
        // v3.0: Institutional Flow (FREE) - The Supreme Window
        case .vxxInstitutionalFlow: return 0.90      // 90% reliability ⭐⭐⭐

        // VXX strategies (core 5)
        case .vxxFadeSetup: return 0.75              // Strong pattern-based fade
        case .vxxPowerHour: return 0.73              // Power hour window
        case .vxxMorningWindow: return 0.72          // Morning setup window
        case .vxxVolumeSpike: return 0.70            // Volume + pattern combination
        case .vxxLunchWindow: return 0.68            // Lunch window

        // Additional strategies (11 more)
        case .consolidationBreakout: return 0.68     // Consolidation breakout
        case .movingAverageCross: return 0.65        // Moving average cross
        case .earningsPlay: return 0.62              // Earnings play
        case .vixSpike: return 0.60                  // VIX spike
        case .zeroDTE: return 0.58                   // 0DTE options
        case .momentumReversal: return 0.55          // Momentum reversal
        case .gapAndGo: return 0.70                  // Gap and go
        case .vwapReversal: return 0.68              // VWAP reversal
        case .powerHour: return 0.65                 // Power hour
        case .panicReversal: return 0.72             // Panic reversal
        case .weeklyOptionsExpiration: return 0.75   // Weekly options expiration
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