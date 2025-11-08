import Foundation

struct MarketData {
    let quote: Quote
    let vwap: Double
    let volume: Int
    let trades: Int
    
    // New properties for refined strategies
    let ivRank: Double                    // Implied Volatility Rank
    let daysToEarnings: Int              // Days until earnings announcement
    let hasFundamentalNews: Bool         // Whether there's fundamental news
    let vix: Double                      // VIX level
    let vixDailyChange: Double           // VIX daily percentage change
    let spyDailyChange: Double           // SPY daily percentage change
    let hasZDTEOptions: Bool             // Whether 0DTE options are available
    let averageVolume: Int               // Average volume for comparison
    let averageOptionsVolume: Int        // Average options volume
    let optionsVolume: Int               // Current options volume
    let rsi: Double                      // RSI indicator
    let emaBreakout: Bool                // 8 EMA crossed above 21 EMA
    let vwapBreakout: Bool               // Price broke VWAP with conviction
    let isWeeklyExpiration: Bool         // Is it weekly expiration day
    let otmProbability: Double           // Out-of-the-money probability
    let minutesSinceMarketOpen: Int      // Minutes since market open
    let marketOpen: TimeInterval         // Market open timestamp
    
    // Additional computed properties needed by Strategy validation
    var symbol: String { quote.symbol }
    var currentPrice: Double { quote.price }
    var isMarketHours: Bool { TimeManager.shared.isMarketHours() }
    var gapPercent: Double { 
        ((quote.price - quote.previousClose) / quote.previousClose) * 100 
    }
    var vwapDeviation: Double { 
        ((quote.price - vwap) / vwap) * 100 
    }
    var consecutiveGreenBars: Int {
        quote.recentCandles.suffix(3).reduce(0) { count, candle in
            candle.close > candle.open ? count + 1 : 0
        }
    }
    var dropPercent: Double {
        guard let high = quote.recentCandles.last?.high else { return 0 }
        return ((high - quote.price) / high) * 100
    }
    var volumeSpike: Int {
        // Primary volume spike calculation using historical average
        volume - averageVolume
    }
    var isVolumeDecline: Bool {
        volume < averageVolume * 0.8  // Volume 20% below average indicates decline
    }
    var timestamp: Date {
        quote.timestamp
    }
    var volumeSpike: Int {
        // Comprehensive volume spike calculation using both metrics
        let recentAvg = quote.recentCandles.map(\.volume).reduce(0, +) / max(quote.recentCandles.count, 1)
        let historicalSpike = volume - averageVolume
        let recentSpike = volume - recentAvg
        return max(historicalSpike, recentSpike) // Use the larger spike value
    }
    
    // VWAP deviation check using your exact criteria
    var hasVWAPDeviation: Bool {
        let deviation = abs((quote.price - vwap) / vwap)
        switch quote.timestamp.marketPhase {
        case .opening:
            // Gap and Go: Price must be above VWAP
            return quote.price > vwap && quote.gapPercent >= AppConfig.Thresholds.gapAndGo.minGapPercent
        case .midday:
            // VWAP Reversal: Check for your specific deviation threshold
            return deviation >= AppConfig.Thresholds.vwapReversal.vwapDeviation
        case .powerHour:
            // Power Hour: Price must cross and hold above VWAP
            return quote.price > vwap && quote.hasMomentum
        default:
            return false
        }
    }
    
    var hasSignificantVolume: Bool {
        let threshold = switch quote.timestamp.marketPhase {
        case .opening: AppConfig.Thresholds.gapAndGo.minVolume
        case .midday: AppConfig.Thresholds.vwapReversal.minVolume
        case .powerHour: AppConfig.Thresholds.powerHour.minVolume
        case .preMarket, .afterHours: Int.max // Prevent trading outside hours
        }
        
        return volume >= threshold
    }
}

// Helper for market phase determination
private extension Date {
    var marketPhase: MarketPhase {
        TimeManager.shared.currentPhase()
    }
}