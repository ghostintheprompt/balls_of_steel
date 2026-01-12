import Foundation

struct ExitRules {
    struct ExitConditions {
        // Pattern specific thresholds
        let priceThreshold: Double
        let volumeThreshold: Int
        let timeWindowStart: String  // HH:MM format
        let timeWindowEnd: String    // HH:MM format

        static func forStrategy(_ strategy: Strategy) -> ExitConditions {
            switch strategy {
            case .gapAndGo:
                return .init(
                    priceThreshold: 0.985,  // -1.5% from entry
                    volumeThreshold: 100_000,
                    timeWindowStart: "09:30",
                    timeWindowEnd: "10:00"
                )
            case .vwapReversal:
                return .init(
                    priceThreshold: 0.02,   // 2% from VWAP
                    volumeThreshold: 500_000,
                    timeWindowStart: "11:30",
                    timeWindowEnd: "13:30"
                )
            case .powerHour:
                return .init(
                    priceThreshold: 0.01,   // 1% momentum loss
                    volumeThreshold: 750_000,
                    timeWindowStart: "15:00",
                    timeWindowEnd: "16:00"
                )
            case .panicReversal:
                return .init(
                    priceThreshold: 0.03,   // 3% bounce
                    volumeThreshold: 2_000_000,
                    timeWindowStart: "09:30",
                    timeWindowEnd: "16:00"  // All market hours
                )
            // VXX-specific strategies
            case .vxxInstitutionalFlow:
                return .init(
                    priceThreshold: 0.01,
                    volumeThreshold: 1_000_000,
                    timeWindowStart: "15:45",
                    timeWindowEnd: "16:10"
                )
            case .vxxFadeSetup:
                return .init(
                    priceThreshold: 0.015,
                    volumeThreshold: 750_000,
                    timeWindowStart: "09:30",
                    timeWindowEnd: "16:00"
                )
            case .vxxPowerHour:
                return .init(
                    priceThreshold: 0.0075,
                    volumeThreshold: 1_000_000,
                    timeWindowStart: "15:10",
                    timeWindowEnd: "15:25"
                )
            case .vxxMorningWindow:
                return .init(
                    priceThreshold: 0.015,
                    volumeThreshold: 500_000,
                    timeWindowStart: "09:50",
                    timeWindowEnd: "10:00"
                )
            case .vxxVolumeSpike:
                return .init(
                    priceThreshold: 0.02,
                    volumeThreshold: 2_000_000,
                    timeWindowStart: "09:30",
                    timeWindowEnd: "16:00"
                )
            case .vxxLunchWindow:
                return .init(
                    priceThreshold: 0.01,
                    volumeThreshold: 500_000,
                    timeWindowStart: "12:20",
                    timeWindowEnd: "12:35"
                )
            // Additional strategies - default values
            default:
                return .init(
                    priceThreshold: 0.015,
                    volumeThreshold: 500_000,
                    timeWindowStart: "09:30",
                    timeWindowEnd: "16:00"
                )
            }
        }
    }
} 