import Foundation

// MARK: - Candlestick Pattern Recognition
// Based on ThinkOrSwim VXX Trading System setup

struct CandlestickPattern {
    let type: PatternType
    let candles: [Candle]
    let timestamp: Date
    let signal: PatternSignal
    let strength: Double // 0.0 to 1.0

    enum PatternType: String, CaseIterable {
        case shootingStar = "Shooting Star"
        case doji = "Doji"
        case hammer = "Hammer"
        case hangingMan = "Hanging Man"

        var description: String {
            switch self {
            case .shootingStar:
                return "Bearish reversal at resistance - fade setup for puts"
            case .doji:
                return "Indecision at key levels - wait for confirmation"
            case .hammer:
                return "Bullish reversal at support - potential call entry"
            case .hangingMan:
                return "Bearish reversal at tops - put entry signal"
            }
        }

        var tradingBias: TradingBias {
            switch self {
            case .shootingStar, .hangingMan:
                return .bearish // Put entries
            case .hammer:
                return .bullish // Call entries
            case .doji:
                return .neutral // Wait for confirmation
            }
        }
    }

    enum PatternSignal {
        case strong      // High probability setup
        case moderate    // Good setup with confirmation needed
        case weak        // Marginal setup
    }

    enum TradingBias {
        case bullish
        case bearish
        case neutral
    }
}

// MARK: - Pattern Recognition Engine
class PatternRecognizer {

    // Pattern detection parameters from ThinkOrSwim setup
    private let lookbackPeriod = 20
    private let volumeFactorThreshold = 2.0 // 200% of average
    private let bodyFactorThreshold = 0.1   // 10% body size for Doji

    /// Detect all patterns in recent candles
    func detectPatterns(candles: [Candle], averageVolume: Int) -> [CandlestickPattern] {
        guard candles.count >= 3 else { return [] }

        var patterns: [CandlestickPattern] = []

        // Check most recent candle for patterns
        let currentCandle = candles[candles.count - 1]
        let previousCandles = Array(candles.dropLast())

        // Shooting Star detection
        if let pattern = detectShootingStar(current: currentCandle, previous: previousCandles, avgVolume: averageVolume) {
            patterns.append(pattern)
        }

        // Doji detection
        if let pattern = detectDoji(current: currentCandle, previous: previousCandles, avgVolume: averageVolume) {
            patterns.append(pattern)
        }

        // Hammer detection
        if let pattern = detectHammer(current: currentCandle, previous: previousCandles, avgVolume: averageVolume) {
            patterns.append(pattern)
        }

        // Hanging Man detection
        if let pattern = detectHangingMan(current: currentCandle, previous: previousCandles, avgVolume: averageVolume) {
            patterns.append(pattern)
        }

        return patterns
    }

    // MARK: - Shooting Star Detection
    private func detectShootingStar(current: Candle, previous: [Candle], avgVolume: Int) -> CandlestickPattern? {
        // Shooting Star criteria:
        // 1. Small body (< 30% of total range)
        // 2. Long upper shadow (> 2x body size)
        // 3. Little to no lower shadow
        // 4. Appears after uptrend
        // 5. Volume confirmation (> 200% average)

        let bodyPercent = current.bodyPercent
        let upperShadowRatio = current.bodySize > 0 ? current.upperShadow / current.bodySize : 0
        let lowerShadowRatio = current.totalRange > 0 ? current.lowerShadow / current.totalRange : 0

        // Check if we're in an uptrend (last 3 candles mostly green)
        let recentTrend = previous.suffix(3)
        let bullishCount = recentTrend.filter { $0.isBullish }.count
        let isUptrend = bullishCount >= 2

        guard bodyPercent < 0.3,
              upperShadowRatio >= 2.0,
              lowerShadowRatio < 0.1,
              isUptrend,
              current.volume >= Int(Double(avgVolume) * volumeFactorThreshold) else {
            return nil
        }

        // Calculate strength based on criteria match
        let strength = calculateStrength(
            bodyPercent: bodyPercent,
            shadowRatio: upperShadowRatio,
            volumeRatio: Double(current.volume) / Double(avgVolume)
        )

        let signal: CandlestickPattern.PatternSignal = strength >= 0.8 ? .strong : strength >= 0.6 ? .moderate : .weak

        return CandlestickPattern(
            type: .shootingStar,
            candles: Array(previous.suffix(2)) + [current],
            timestamp: current.timestamp,
            signal: signal,
            strength: strength
        )
    }

    // MARK: - Doji Detection
    private func detectDoji(current: Candle, previous: [Candle], avgVolume: Int) -> CandlestickPattern? {
        // Doji criteria:
        // 1. Very small body (< 10% of total range)
        // 2. Upper and lower shadows present
        // 3. Indecision at key levels
        // 4. Volume confirmation

        let bodyPercent = current.bodyPercent

        guard bodyPercent <= bodyFactorThreshold,
              current.upperShadow > 0,
              current.lowerShadow > 0,
              current.volume >= avgVolume else {
            return nil
        }

        // Check if at key level (near recent high/low)
        let recentHigh = previous.suffix(5).map { $0.high }.max() ?? 0
        let recentLow = previous.suffix(5).map { $0.low }.min() ?? 0
        let isAtKeyLevel = abs(current.close - recentHigh) / recentHigh < 0.01 ||
                          abs(current.close - recentLow) / recentLow < 0.01

        let strength = bodyPercent < 0.05 ? 1.0 : 0.7
        let signal: CandlestickPattern.PatternSignal = isAtKeyLevel ? .strong : .moderate

        return CandlestickPattern(
            type: .doji,
            candles: Array(previous.suffix(2)) + [current],
            timestamp: current.timestamp,
            signal: signal,
            strength: strength
        )
    }

    // MARK: - Hammer Detection
    private func detectHammer(current: Candle, previous: [Candle], avgVolume: Int) -> CandlestickPattern? {
        // Hammer criteria:
        // 1. Small body (< 30% of total range)
        // 2. Long lower shadow (> 2x body size)
        // 3. Little to no upper shadow
        // 4. Appears after downtrend
        // 5. Volume confirmation

        let bodyPercent = current.bodyPercent
        let lowerShadowRatio = current.bodySize > 0 ? current.lowerShadow / current.bodySize : 0
        let upperShadowRatio = current.totalRange > 0 ? current.upperShadow / current.totalRange : 0

        // Check if we're in a downtrend
        let recentTrend = previous.suffix(3)
        let bearishCount = recentTrend.filter { $0.isBearish }.count
        let isDowntrend = bearishCount >= 2

        guard bodyPercent < 0.3,
              lowerShadowRatio >= 2.0,
              upperShadowRatio < 0.1,
              isDowntrend,
              current.volume >= Int(Double(avgVolume) * volumeFactorThreshold) else {
            return nil
        }

        let strength = calculateStrength(
            bodyPercent: bodyPercent,
            shadowRatio: lowerShadowRatio,
            volumeRatio: Double(current.volume) / Double(avgVolume)
        )

        let signal: CandlestickPattern.PatternSignal = strength >= 0.8 ? .strong : strength >= 0.6 ? .moderate : .weak

        return CandlestickPattern(
            type: .hammer,
            candles: Array(previous.suffix(2)) + [current],
            timestamp: current.timestamp,
            signal: signal,
            strength: strength
        )
    }

    // MARK: - Hanging Man Detection
    private func detectHangingMan(current: Candle, previous: [Candle], avgVolume: Int) -> CandlestickPattern? {
        // Hanging Man criteria (similar to Hammer but after uptrend):
        // 1. Small body (< 30% of total range)
        // 2. Long lower shadow (> 2x body size)
        // 3. Little to no upper shadow
        // 4. Appears after uptrend (key difference from Hammer)
        // 5. Volume confirmation

        let bodyPercent = current.bodyPercent
        let lowerShadowRatio = current.bodySize > 0 ? current.lowerShadow / current.bodySize : 0
        let upperShadowRatio = current.totalRange > 0 ? current.upperShadow / current.totalRange : 0

        // Check if we're in an uptrend
        let recentTrend = previous.suffix(3)
        let bullishCount = recentTrend.filter { $0.isBullish }.count
        let isUptrend = bullishCount >= 2

        guard bodyPercent < 0.3,
              lowerShadowRatio >= 2.0,
              upperShadowRatio < 0.1,
              isUptrend,
              current.volume >= Int(Double(avgVolume) * volumeFactorThreshold) else {
            return nil
        }

        let strength = calculateStrength(
            bodyPercent: bodyPercent,
            shadowRatio: lowerShadowRatio,
            volumeRatio: Double(current.volume) / Double(avgVolume)
        )

        let signal: CandlestickPattern.PatternSignal = strength >= 0.8 ? .strong : strength >= 0.6 ? .moderate : .weak

        return CandlestickPattern(
            type: .hangingMan,
            candles: Array(previous.suffix(2)) + [current],
            timestamp: current.timestamp,
            signal: signal,
            strength: strength
        )
    }

    // MARK: - Helper Methods
    private func calculateStrength(bodyPercent: Double, shadowRatio: Double, volumeRatio: Double) -> Double {
        // Weighted scoring: body size (30%), shadow ratio (40%), volume (30%)
        let bodyScore = max(0, 1.0 - (bodyPercent / 0.3)) * 0.3
        let shadowScore = min(1.0, shadowRatio / 3.0) * 0.4
        let volumeScore = min(1.0, volumeRatio / volumeFactorThreshold) * 0.3

        return bodyScore + shadowScore + volumeScore
    }
}
