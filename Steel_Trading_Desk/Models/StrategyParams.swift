import Foundation

// New refined strategy parameters from trading document

struct EarningsVolatilityCrushParams {
    let minIVRank: Double
    let optimalIVRank: Double
    let maxDaysToEarnings: Int
    let minDaysToEarnings: Int
    let creditTarget: ClosedRange<Double>
    let maxRisk: Double
    let profitTarget: ClosedRange<Double>
    let stopLoss: Double
}

struct GapFillParams {
    let minGapPercent: Double
    let maxGapPercent: Double
    let optimalGapRange: ClosedRange<Double>
    let fillRateSmallGaps: Double
    let fillRateLargeGaps: Double
    let sameDayFillRate: ClosedRange<Double>
    let timeHorizonDays: Int
    let avoidGapsAbove: Double
}

struct ZDTEIronButterflyParams {
    let entryTime: String
    let maxVIX: Double
    let targetCredit: ClosedRange<Double>
    let wingDistance: Double
    let profitTarget: Double
    let exitTime: String
    let successRate: Double
}

struct VIXSpikePremiumSellingParams {
    let minVIXSpike: Double
    let minVIXLevel: Double
    let minSPYDrop: Double
    let minPutCallRatio: Double
    let targetCredit: ClosedRange<Double>
    let spreadsWidth: Double
    let profitTarget: Double
    let stopLoss: Double
}

struct MomentumBreakoutParams {
    let minVolumeMultiple: Double
    let rsiThreshold: Double
    let callVolumeMultiple: Double
    let targetReturns: ClosedRange<Double>
    let timeHorizonDays: Int
    let entryWindows: [String]
}

struct PreMarketInstitutionalFlowParams {
    let primaryWindow: String
    let peakWindow: String
    let avoidWindow: String
    let minOptionsVolumeMultiple: Double
    let requiredMultipleStrikes: Bool
}

struct WeeklyOptionsExpirationParams {
    let targetDays: [DayOfWeek]
    let maxOTMProbability: Double
    let targetCredit: ClosedRange<Double>
    let avoidEarningsWeeks: Bool
    let avoidFedMeetings: Bool
}

enum DayOfWeek {
    case monday, tuesday, wednesday, thursday, friday
}

// Legacy strategy parameters (updated)

struct GapAndGoParams {
    let minGapPercent: Double  // Updated to 0.5% for gap fill strategy
    let minVolume: Int        // 500k in first 5 min
    let stopLoss: Double      // 1.5% below entry
    let target: Double        // 2.0% above entry
    let timeWindow: String    // "9:30-10:00"
}

struct VWAPParams {
    let minVolume: Int        // 750k minimum
    let vwapDeviation: Double // Must cross VWAP
    let stopLoss: Double      // 1.0% below VWAP
    let target: Double        // 2.0% above VWAP
    let timeWindow: String    // "11:30-13:30"
}

struct PowerHourParams {
    let minVolume: Int        // 1M minimum
    let momentumBars: Int     // 2 consecutive green
    let stopLoss: Double      // 0.75% below entry
    let target: Double        // 1.5% above entry
    let timeWindow: String    // "15:00-16:00"
}

struct PanicParams {
    let minDrop: Double       // 3.0% drop required
    let minVolumeSpike: Int   // 2M spike needed
    let stopLoss: Double      // 1.0% below bounce
    let target: Double        // 3.0% above entry
    // No time window - trade when it presents
} 