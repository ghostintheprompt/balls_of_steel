import Foundation

struct ExitRules {
    struct ExitConditions {
        // Pattern specific thresholds
        let priceThreshold: Double
        let volumeThreshold: Int
        let timeWindowStart: String  // HH:MM format
        let warningTime: String      // HH:MM format
        let hardExitTime: String     // HH:MM format

        static func forStrategy(_ strategy: Strategy) -> ExitConditions {
            let warningTime = AppConfig.CloseManagement.warningTime(for: strategy)
            let hardExitTime = AppConfig.CloseManagement.hardExitTime(for: strategy)

            switch strategy {
            case .gapAndGo:
                return .init(
                    priceThreshold: 0.985,  // -1.5% from entry
                    volumeThreshold: 100_000,
                    timeWindowStart: "09:30",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .vwapReversal:
                return .init(
                    priceThreshold: 0.02,   // 2% from VWAP
                    volumeThreshold: 500_000,
                    timeWindowStart: "11:30",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .powerHour:
                return .init(
                    priceThreshold: 0.01,   // 1% momentum loss
                    volumeThreshold: 750_000,
                    timeWindowStart: "15:00",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .panicReversal:
                return .init(
                    priceThreshold: 0.03,   // 3% bounce
                    volumeThreshold: 2_000_000,
                    timeWindowStart: "09:30",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            // VXX-specific strategies
            case .vxxInstitutionalFlow:
                return .init(
                    priceThreshold: 0.01,
                    volumeThreshold: 1_000_000,
                    timeWindowStart: "15:45",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .vxxFadeSetup:
                return .init(
                    priceThreshold: 0.015,
                    volumeThreshold: 750_000,
                    timeWindowStart: "09:30",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .vxxPowerHour:
                return .init(
                    priceThreshold: 0.0075,
                    volumeThreshold: 1_000_000,
                    timeWindowStart: "15:10",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .vxxMorningWindow:
                return .init(
                    priceThreshold: 0.015,
                    volumeThreshold: 500_000,
                    timeWindowStart: "09:50",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .vxxVolumeSpike:
                return .init(
                    priceThreshold: 0.02,
                    volumeThreshold: 2_000_000,
                    timeWindowStart: "09:30",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .vxxLunchWindow:
                return .init(
                    priceThreshold: 0.01,
                    volumeThreshold: 500_000,
                    timeWindowStart: "12:20",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .spyOpenDrive:
                return .init(
                    priceThreshold: 0.0075,
                    volumeThreshold: 750_000,
                    timeWindowStart: "09:35",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            case .spyCloseDrive:
                return .init(
                    priceThreshold: 0.0075,
                    volumeThreshold: 750_000,
                    timeWindowStart: "15:30",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            // Additional strategies - default values
            default:
                return .init(
                    priceThreshold: 0.015,
                    volumeThreshold: 500_000,
                    timeWindowStart: "09:30",
                    warningTime: warningTime,
                    hardExitTime: hardExitTime
                )
            }
        }
    }
} 
