import Foundation

// MARK: - Technical Indicators
// Based on ThinkOrSwim VXX Trading System setup

struct TechnicalIndicators {
    let sma20: Double
    let sma50: Double
    let vwap: Double
    let volumeAverage: Double
    let impliedVolatility: Double
    let rsi: Double
    let currentPrice: Double
    let currentVolume: Int

    // Computed properties for trading signals
    var isPriceAboveSMA20: Bool {
        currentPrice > sma20
    }

    var isPriceAboveSMA50: Bool {
        currentPrice > sma50
    }

    var isPriceAboveVWAP: Bool {
        currentPrice > vwap
    }

    var isVolumeAboveAverage: Bool {
        Double(currentVolume) > volumeAverage
    }

    var volumeMultiple: Double {
        volumeAverage > 0 ? Double(currentVolume) / volumeAverage : 0
    }

    // SMA trend analysis
    var smaSignal: TrendSignal {
        if isPriceAboveSMA20 && isPriceAboveSMA50 && sma20 > sma50 {
            return .bullish
        } else if !isPriceAboveSMA20 && !isPriceAboveSMA50 && sma20 < sma50 {
            return .bearish
        } else {
            return .neutral
        }
    }

    // VWAP deviation (for fade setups)
    var vwapDeviation: Double {
        ((currentPrice - vwap) / vwap) * 100
    }

    // Volume signal
    var volumeSignal: VolumeSignal {
        switch volumeMultiple {
        case 2.0...:
            return .extremelyHigh // 200%+ - major conviction
        case 1.5..<2.0:
            return .high // 150-200% - strong conviction
        case 1.0..<1.5:
            return .aboveAverage // 100-150% - normal
        case 0.5..<1.0:
            return .belowAverage // 50-100% - weak
        default:
            return .veryLow // <50% - very weak
        }
    }

    enum TrendSignal {
        case bullish
        case bearish
        case neutral

        var displayName: String {
            switch self {
            case .bullish: return "Bullish Trend"
            case .bearish: return "Bearish Trend"
            case .neutral: return "Neutral/Mixed"
            }
        }
    }

    enum VolumeSignal {
        case extremelyHigh
        case high
        case aboveAverage
        case belowAverage
        case veryLow

        var displayName: String {
            switch self {
            case .extremelyHigh: return "Extreme Volume (200%+)"
            case .high: return "High Volume (150%+)"
            case .aboveAverage: return "Above Average"
            case .belowAverage: return "Below Average"
            case .veryLow: return "Very Low Volume"
            }
        }

        var isConfirmation: Bool {
            self == .extremelyHigh || self == .high
        }
    }
}

// MARK: - Indicator Calculator
class IndicatorCalculator {

    /// Calculate Simple Moving Average
    static func calculateSMA(candles: [Candle], period: Int) -> Double? {
        guard candles.count >= period else { return nil }

        let recentCandles = Array(candles.suffix(period))
        let sum = recentCandles.map { $0.close }.reduce(0, +)
        return sum / Double(period)
    }

    /// Calculate Volume Weighted Average Price (VWAP)
    /// VWAP resets daily at market open
    static func calculateVWAP(candles: [Candle]) -> Double {
        guard !candles.isEmpty else { return 0 }

        // Filter to today's candles only
        let calendar = Calendar.current
        let today = Date()
        let todayCandles = candles.filter { candle in
            calendar.isDate(candle.timestamp, inSameDayAs: today)
        }

        guard !todayCandles.isEmpty else { return candles.last?.close ?? 0 }

        var totalTPV: Double = 0  // Total (Typical Price × Volume)
        var totalVolume: Int = 0

        for candle in todayCandles {
            let typicalPrice = (candle.high + candle.low + candle.close) / 3.0
            totalTPV += typicalPrice * Double(candle.volume)
            totalVolume += candle.volume
        }

        return totalVolume > 0 ? totalTPV / Double(totalVolume) : todayCandles.last?.close ?? 0
    }

    /// Calculate Volume Average
    static func calculateVolumeAverage(candles: [Candle], period: Int = 30) -> Double {
        guard candles.count >= period else {
            // If not enough candles, use what we have
            let volumes = candles.map { Double($0.volume) }
            return volumes.isEmpty ? 0 : volumes.reduce(0, +) / Double(volumes.count)
        }

        let recentCandles = Array(candles.suffix(period))
        let sum = recentCandles.map { Double($0.volume) }.reduce(0, +)
        return sum / Double(period)
    }

    /// Calculate Relative Strength Index (RSI)
    static func calculateRSI(candles: [Candle], period: Int = 14) -> Double {
        guard candles.count >= period + 1 else { return 50.0 } // Return neutral if not enough data

        let recentCandles = Array(candles.suffix(period + 1))
        var gains: [Double] = []
        var losses: [Double] = []

        for i in 1..<recentCandles.count {
            let change = recentCandles[i].close - recentCandles[i-1].close
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(abs(change))
            }
        }

        let avgGain = gains.reduce(0, +) / Double(period)
        let avgLoss = losses.reduce(0, +) / Double(period)

        guard avgLoss > 0 else { return 100.0 }

        let rs = avgGain / avgLoss
        let rsi = 100 - (100 / (1 + rs))

        return rsi
    }

    /// Calculate all indicators for a given set of candles
    static func calculateAll(candles: [Candle], impliedVolatility: Double = 0) -> TechnicalIndicators? {
        guard let sma20 = calculateSMA(candles: candles, period: 20),
              let sma50 = calculateSMA(candles: candles, period: 50),
              let currentCandle = candles.last else {
            return nil
        }

        let vwap = calculateVWAP(candles: candles)
        let volumeAvg = calculateVolumeAverage(candles: candles, period: 30)
        let rsi = calculateRSI(candles: candles, period: 14)

        return TechnicalIndicators(
            sma20: sma20,
            sma50: sma50,
            vwap: vwap,
            volumeAverage: volumeAvg,
            impliedVolatility: impliedVolatility,
            rsi: rsi,
            currentPrice: currentCandle.close,
            currentVolume: currentCandle.volume
        )
    }
}

// MARK: - Support & Resistance (Dynamic)
struct SupportResistance {
    let support: [Double]
    let resistance: [Double]

    /// Calculate dynamic support and resistance based on recent price action
    static func calculate(candles: [Candle], strength: Strength = .medium) -> SupportResistance {
        guard candles.count >= 20 else {
            return SupportResistance(support: [], resistance: [])
        }

        let lookback = strength == .high ? 50 : strength == .medium ? 30 : 20
        let recentCandles = Array(candles.suffix(min(lookback, candles.count)))

        // Find pivot highs and lows
        var resistanceLevels: [Double] = []
        var supportLevels: [Double] = []

        for i in 2..<(recentCandles.count - 2) {
            let current = recentCandles[i]

            // Check for pivot high (resistance)
            if current.high >= recentCandles[i-1].high &&
               current.high >= recentCandles[i-2].high &&
               current.high >= recentCandles[i+1].high &&
               current.high >= recentCandles[i+2].high {
                resistanceLevels.append(current.high)
            }

            // Check for pivot low (support)
            if current.low <= recentCandles[i-1].low &&
               current.low <= recentCandles[i-2].low &&
               current.low <= recentCandles[i+1].low &&
               current.low <= recentCandles[i+2].low {
                supportLevels.append(current.low)
            }
        }

        // Cluster nearby levels (within 0.5%)
        let clusteredResistance = clusterLevels(resistanceLevels)
        let clusteredSupport = clusterLevels(supportLevels)

        // Return top 3-5 levels
        let topResistance = Array(clusteredResistance.sorted(by: >).prefix(5))
        let topSupport = Array(clusteredSupport.sorted(by: <).prefix(5))

        return SupportResistance(support: topSupport, resistance: topResistance)
    }

    private static func clusterLevels(_ levels: [Double]) -> [Double] {
        guard !levels.isEmpty else { return [] }

        var clustered: [Double] = []
        var sorted = levels.sorted()

        var currentCluster: [Double] = [sorted[0]]

        for i in 1..<sorted.count {
            let diff = abs(sorted[i] - currentCluster.last!) / currentCluster.last!

            if diff < 0.005 { // Within 0.5%
                currentCluster.append(sorted[i])
            } else {
                // Average the cluster
                let avg = currentCluster.reduce(0, +) / Double(currentCluster.count)
                clustered.append(avg)
                currentCluster = [sorted[i]]
            }
        }

        // Add final cluster
        if !currentCluster.isEmpty {
            let avg = currentCluster.reduce(0, +) / Double(currentCluster.count)
            clustered.append(avg)
        }

        return clustered
    }

    enum Strength {
        case low
        case medium
        case high
    }

    /// Check if price is near a level (within 0.5%)
    func isNearSupport(_ price: Double) -> Bool {
        support.contains { level in
            abs(price - level) / level < 0.005
        }
    }

    func isNearResistance(_ price: Double) -> Bool {
        resistance.contains { level in
            abs(price - level) / level < 0.005
        }
    }
}

// MARK: - VXX/VIX Ratio Monitor
// Updated with 2026 strategy thresholds (1.35-1.60 range)
struct VXXVIXRatio {
    let vxx: Double
    let vix: Double
    let ratio: Double
    let timestamp: Date

    init(vxx: Double, vix: Double) {
        self.vxx = vxx
        self.vix = vix
        self.ratio = vix > 0 ? vxx / vix : 0
        self.timestamp = Date()
    }

    // Strategy thresholds from VXX Trading System 2026
    var tier: RatioTier {
        if ratio >= 1.60 {
            return .premiumFade
        } else if ratio >= 1.55 {
            return .strongFade
        } else if ratio >= 1.45 {
            return .normalFade
        } else if ratio >= 1.35 {
            return .weakFade
        } else {
            return .noFade
        }
    }

    var isPremiumFade: Bool {
        ratio >= 1.60
    }

    var isStrongFade: Bool {
        ratio >= 1.55 && ratio < 1.60
    }

    var isNormalFade: Bool {
        ratio >= 1.45 && ratio < 1.55
    }

    var isWeakFade: Bool {
        ratio >= 1.35 && ratio < 1.45
    }

    var isTooCheap: Bool {
        ratio < 1.35
    }

    var shouldTrade: Bool {
        ratio >= 1.45 // Minimum threshold for puts
    }

    // Legacy compatibility
    var isOverextended: Bool {
        ratio >= 1.60 // Premium fade zone
    }

    var isOversold: Bool {
        ratio < 1.35 // Too cheap to fade
    }

    var signal: RatioSignal {
        switch tier {
        case .premiumFade, .strongFade, .normalFade:
            return .fadeSetup
        case .weakFade:
            return .cautionFade
        case .noFade:
            return .noTrade
        }
    }

    // Position size recommendation based on ratio
    var recommendedPositionSize: Double {
        switch tier {
        case .premiumFade:
            return 500.0 // Max position
        case .strongFade:
            return 450.0
        case .normalFade:
            return 350.0
        case .weakFade:
            return 200.0
        case .noFade:
            return 0.0 // Skip trade
        }
    }

    enum RatioTier {
        case premiumFade    // >1.60 - Max aggression
        case strongFade     // 1.55-1.60 - Full position
        case normalFade     // 1.45-1.55 - Standard position
        case weakFade       // 1.35-1.45 - Half size or skip
        case noFade         // <1.35 - Don't trade puts

        var displayName: String {
            switch self {
            case .premiumFade: return "Premium Fade ⭐⭐⭐"
            case .strongFade: return "Strong Fade ⭐⭐"
            case .normalFade: return "Normal Fade ⭐"
            case .weakFade: return "Weak Fade (Caution)"
            case .noFade: return "No Fade ❌"
            }
        }

        var color: String {
            switch self {
            case .premiumFade: return "green"
            case .strongFade: return "yellow"
            case .normalFade: return "cyan"
            case .weakFade: return "orange"
            case .noFade: return "red"
            }
        }

        var thresholdRange: String {
            switch self {
            case .premiumFade: return ">1.60"
            case .strongFade: return "1.55-1.60"
            case .normalFade: return "1.45-1.55"
            case .weakFade: return "1.35-1.45"
            case .noFade: return "<1.35"
            }
        }
    }

    enum RatioSignal {
        case fadeSetup      // VXX overpriced - put entries
        case cautionFade    // Borderline - small position only
        case noTrade        // VXX too cheap - skip puts

        var displayName: String {
            switch self {
            case .fadeSetup: return "Fade Setup (Puts)"
            case .cautionFade: return "Caution (Small Size)"
            case .noTrade: return "No Trade (Too Cheap)"
            }
        }
    }
}
