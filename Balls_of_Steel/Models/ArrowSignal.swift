import Foundation

// MARK: - Arrow Signal System (v3.0)
// Core signal validation system with volume confirmation requirements

struct ArrowSignal {
    let direction: Direction
    let timestamp: Date
    let volumeConfirmation: VolumeConfirmation
    let technicalConfluence: [TechnicalConfluence]
    let timeWindow: TimeWindow
    let strength: SignalStrength

    enum Direction {
        case bullish  // Arrow up - calls
        case bearish  // Arrow down - puts

        var displayName: String {
            switch self {
            case .bullish: return "Bullish Arrow ↑"
            case .bearish: return "Bearish Arrow ↓"
            }
        }

        var icon: String {
            switch self {
            case .bullish: return "arrow.up.circle.fill"
            case .bearish: return "arrow.down.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .bullish: return "green"
            case .bearish: return "red"
            }
        }
    }

    // MARK: - Volume Confirmation (Gate Keeper - Non-Negotiable)
    enum VolumeConfirmation {
        case none              // Below threshold - IGNORE COMPLETELY
        case standard          // 200%+ average - REQUIRED for any entry
        case institutional     // 300%+ average - Premium setup
        case majorInstitution  // 400%+ average - Highest conviction

        var multiplier: Double {
            switch self {
            case .none: return 0
            case .standard: return 2.0      // 200%
            case .institutional: return 3.0  // 300%
            case .majorInstitution: return 4.0 // 400%
            }
        }

        var isValid: Bool {
            self != .none
        }

        var displayName: String {
            switch self {
            case .none: return "No Confirmation ❌"
            case .standard: return "Standard (200%+) ✅"
            case .institutional: return "Institutional (300%+) ⭐"
            case .majorInstitution: return "Major Institution (400%+) ⭐⭐"
            }
        }
    }

    // MARK: - Technical Confluence (Probability Multiplier)
    enum TechnicalConfluence {
        case maCross          // +20% probability
        case vwapBreak        // +15% probability
        case candlestickPattern // +25% probability
        case supportResistance  // +30% probability

        var probabilityBonus: Double {
            switch self {
            case .maCross: return 0.20
            case .vwapBreak: return 0.15
            case .candlestickPattern: return 0.25
            case .supportResistance: return 0.30
            }
        }

        var displayName: String {
            switch self {
            case .maCross: return "MA Cross (+20%)"
            case .vwapBreak: return "VWAP Break (+15%)"
            case .candlestickPattern: return "Pattern (+25%)"
            case .supportResistance: return "S/R Test (+30%)"
            }
        }
    }

    // MARK: - Time Window Context (Reliability Factor)
    enum TimeWindow {
        case institutionalFlow  // 3:45-4:10 PM - 90% reliability ⭐⭐⭐
        case morningFade        // 9:50-10:15 AM - 85% reliability
        case powerHourCrush     // 3:10-3:25 PM - 80% reliability
        case afternoonFlex      // 1:30-3:45 PM - real tape can build before anchor windows
        case lunchDrift         // 12:20-12:40 PM - 70% reliability
        case other              // Other times - 50% reliability (weak)

        var reliability: Double {
            switch self {
            case .institutionalFlow: return 0.90
            case .morningFade: return 0.85
            case .powerHourCrush: return 0.80
            case .afternoonFlex: return 0.72
            case .lunchDrift: return 0.70
            case .other: return 0.50
            }
        }

        var displayName: String {
            switch self {
            case .institutionalFlow: return "Institutional Flow (3:45-4:10 PM) 90%"
            case .morningFade: return "Morning Fade (9:50-10:15 AM) 85%"
            case .powerHourCrush: return "Power Hour (3:10-3:25 PM) 80%"
            case .afternoonFlex: return "Afternoon Flex (1:30-3:45 PM) 72%"
            case .lunchDrift: return "Lunch Drift (12:20-12:40 PM) 70%"
            case .other: return "Off-Window (50%)"
            }
        }

        var priority: Int {
            switch self {
            case .institutionalFlow: return 1
            case .morningFade: return 2
            case .powerHourCrush: return 3
            case .afternoonFlex: return 4
            case .lunchDrift: return 5
            case .other: return 6
            }
        }

        var timeRange: String {
            switch self {
            case .institutionalFlow: return "3:45-4:10 PM"
            case .morningFade: return "9:50-10:15 AM"
            case .powerHourCrush: return "3:10-3:25 PM"
            case .afternoonFlex: return "1:30-3:45 PM"
            case .lunchDrift: return "12:20-12:40 PM"
            case .other: return "Other"
            }
        }
    }

    // MARK: - Signal Strength Classification
    enum SignalStrength {
        case strong    // Arrow + Volume >200% + Time Window + Technical
        case moderate  // Arrow + Volume >200% only
        case weak      // Arrow alone or low volume - SKIP

        var positionSize: Double {
            switch self {
            case .strong: return 1.0      // Full position
            case .moderate: return 0.5    // Half position
            case .weak: return 0.0        // Paper trade only / skip
            }
        }

        var shouldTrade: Bool {
            self != .weak
        }

        var displayName: String {
            switch self {
            case .strong: return "STRONG ⭐⭐⭐"
            case .moderate: return "MODERATE ⭐⭐"
            case .weak: return "WEAK (Skip) ❌"
            }
        }

        var entryStrategy: String {
            switch self {
            case .strong: return "Enter aggressively at market price"
            case .moderate: return "Wait for better entry on minor pullback"
            case .weak: return "Paper trade only or skip entirely"
            }
        }
    }

    // MARK: - Signal Validation
    var isValid: Bool {
        // Arrow without volume = IGNORE COMPLETELY
        guard volumeConfirmation.isValid else { return false }

        // Must be at least moderate strength
        return strength.shouldTrade
    }

    var totalProbabilityBonus: Double {
        // Base reliability from time window
        var bonus = timeWindow.reliability

        // Add technical confluence bonuses
        for confluence in technicalConfluence {
            bonus += confluence.probabilityBonus
        }

        return min(bonus, 1.0) // Cap at 100%
    }

    var recommendedPositionSize: Double {
        guard isValid else { return 0 }

        // Base position from signal strength
        var size = strength.positionSize

        // Institutional volume bonus (but respect 1 contract max)
        if volumeConfirmation == .institutional || volumeConfirmation == .majorInstitution {
            // Higher conviction but same max size (greed control)
            size = min(size, 1.0)
        }

        return size
    }
}

// MARK: - Arrow Signal Detector
class ArrowSignalDetector {

    /// Detect arrow signal from market data and technical indicators
    static func detectArrowSignal(
        marketData: MarketData,
        technicalIndicators: TechnicalIndicators,
        previousCandle: Candle?,
        supportResistance: SupportResistance
    ) -> ArrowSignal? {

        // Determine arrow direction based on price action and indicators
        guard let direction = determineDirection(
            currentPrice: marketData.currentPrice,
            indicators: technicalIndicators,
            previousCandle: previousCandle
        ) else {
            return nil
        }

        // Calculate volume confirmation (GATE KEEPER)
        let volumeConfirmation = calculateVolumeConfirmation(
            currentVolume: marketData.volume,
            averageVolume: marketData.averageVolume
        )

        // Detect technical confluence
        let confluence = detectTechnicalConfluence(
            marketData: marketData,
            indicators: technicalIndicators,
            supportResistance: supportResistance
        )

        // Determine time window
        let timeWindow = determineTimeWindow(timestamp: marketData.timestamp)

        // Calculate signal strength
        let strength = calculateSignalStrength(
            volumeConfirmation: volumeConfirmation,
            confluence: confluence,
            timeWindow: timeWindow
        )

        return ArrowSignal(
            direction: direction,
            timestamp: marketData.timestamp,
            volumeConfirmation: volumeConfirmation,
            technicalConfluence: confluence,
            timeWindow: timeWindow,
            strength: strength
        )
    }

    // MARK: - Direction Detection
    private static func determineDirection(
        currentPrice: Double,
        indicators: TechnicalIndicators,
        previousCandle: Candle?
    ) -> ArrowSignal.Direction? {

        // Moving Average Cross Detection (Primary Signal)
        if indicators.sma20 > indicators.sma50 && indicators.isPriceAboveSMA20 {
            // 20 SMA crossing above 50 SMA = Bullish arrow
            return .bullish
        } else if indicators.sma20 < indicators.sma50 && !indicators.isPriceAboveSMA20 {
            // 20 SMA crossing below 50 SMA = Bearish arrow
            return .bearish
        }

        // VWAP Break Detection (Secondary Signal)
        if currentPrice > indicators.vwap && abs(indicators.vwapDeviation) > 1.0 {
            return .bullish
        } else if currentPrice < indicators.vwap && abs(indicators.vwapDeviation) > 1.0 {
            return .bearish
        }

        // RSI Extreme Detection (Tertiary Signal)
        if indicators.rsi > 60 && indicators.isVolumeAboveAverage {
            return .bullish
        } else if indicators.rsi < 40 && indicators.isVolumeAboveAverage {
            return .bearish
        }

        return nil
    }

    // MARK: - Volume Confirmation (GATE KEEPER)
    private static func calculateVolumeConfirmation(
        currentVolume: Int,
        averageVolume: Int
    ) -> ArrowSignal.VolumeConfirmation {

        let volumeMultiple = Double(currentVolume) / Double(averageVolume)

        if volumeMultiple >= 4.0 {
            return .majorInstitution  // 400%+
        } else if volumeMultiple >= 3.0 {
            return .institutional     // 300%+
        } else if volumeMultiple >= 2.0 {
            return .standard          // 200%+
        } else {
            return .none              // Below threshold - IGNORE
        }
    }

    // MARK: - Technical Confluence Detection
    private static func detectTechnicalConfluence(
        marketData: MarketData,
        indicators: TechnicalIndicators,
        supportResistance: SupportResistance
    ) -> [ArrowSignal.TechnicalConfluence] {

        var confluence: [ArrowSignal.TechnicalConfluence] = []

        // MA Cross
        if indicators.sma20 > indicators.sma50 || indicators.sma20 < indicators.sma50 {
            confluence.append(.maCross)
        }

        // VWAP Break
        if abs(indicators.vwapDeviation) > 0.5 {
            confluence.append(.vwapBreak)
        }

        // Candlestick Pattern
        if marketData.hasPattern {
            confluence.append(.candlestickPattern)
        }

        // Support/Resistance Test
        let price = marketData.currentPrice
        if supportResistance.isNearSupport(price) || supportResistance.isNearResistance(price) {
            confluence.append(.supportResistance)
        }

        return confluence
    }

    // MARK: - Time Window Determination
    private static func determineTimeWindow(timestamp: Date) -> ArrowSignal.TimeWindow {
        if timestamp.isInstitutionalFlowWindow {
            return .institutionalFlow
        } else if timestamp.isSPYCloseWindow {
            return .powerHourCrush
        } else if timestamp.isSPYOpenWindow {
            return .morningFade
        } else if timestamp.isVXXMorningWindow || timestamp.isInWindow("09:50", "10:15") {
            return .morningFade
        } else if timestamp.isVXXPowerHourWindow {
            return .powerHourCrush
        } else if timestamp.isVXXLunchWindow {
            return .lunchDrift
        } else if timestamp.isAfternoonFlexWindow {
            return .afternoonFlex
        } else {
            return .other
        }
    }

    // MARK: - Signal Strength Calculation
    private static func calculateSignalStrength(
        volumeConfirmation: ArrowSignal.VolumeConfirmation,
        confluence: [ArrowSignal.TechnicalConfluence],
        timeWindow: ArrowSignal.TimeWindow
    ) -> ArrowSignal.SignalStrength {

        // Arrow without volume = WEAK (skip)
        guard volumeConfirmation.isValid else {
            return .weak
        }

        if !confluence.isEmpty {
            switch timeWindow {
            case .institutionalFlow, .morningFade, .powerHourCrush, .lunchDrift:
                return .strong
            case .afternoonFlex:
                if confluence.count >= 2 ||
                    volumeConfirmation == .institutional ||
                    volumeConfirmation == .majorInstitution {
                    return .strong
                }
                return .moderate
            case .other:
                break
            }
        }

        // MODERATE: Arrow + Volume >200% only
        if volumeConfirmation.isValid {
            return .moderate
        }

        return .weak
    }
}

// MARK: - Date Extension for Institutional Flow Window
extension Date {
    /// 3:45-4:10 PM - Institutional Flow Window (90% reliability)
    var isInstitutionalFlowWindow: Bool {
        isInWindow("15:45", "16:10")
    }
}
