import Foundation
import SwiftUI

struct AppConfig {
    // API Configuration
    static let baseURL = "https://api.schwab.com/v1"
    static let streamURL = "wss://api.schwab.com/v1/stream"
    static let clientId = "" // Required for Schwab API connection
    
    // Strategy Parameters
    struct Thresholds {
        // New refined strategies from trading document
        static let earningsVolatilityCrush = EarningsVolatilityCrushParams(
            minIVRank: 75.0,
            optimalIVRank: 85.0,
            maxDaysToEarnings: 3,
            minDaysToEarnings: 2,
            creditTarget: 2.00...2.80,
            maxRisk: 2.60,
            profitTarget: 0.50...0.80,
            stopLoss: 0.50
        )
        
        static let gapFill = GapFillParams(
            minGapPercent: 0.5,
            maxGapPercent: 2.0,
            optimalGapRange: 0.5...2.0,
            fillRateSmallGaps: 0.78,
            fillRateLargeGaps: 0.45,
            sameDayFillRate: 0.45...0.60,
            timeHorizonDays: 14,
            avoidGapsAbove: 2.0
        )
        
        static let zdteIronButterfly = ZDTEIronButterflyParams(
            entryTime: "10:15",
            maxVIX: 25.0,
            targetCredit: 0.40...0.80,
            wingDistance: 2.0,
            profitTarget: 0.50,
            exitTime: "14:00",
            successRate: 0.668
        )
        
        static let vixSpikePremiumSelling = VIXSpikePremiumSellingParams(
            minVIXSpike: 15.0,
            minVIXLevel: 30.0,
            minSPYDrop: 1.5,
            minPutCallRatio: 1.2,
            targetCredit: 1.50...2.50,
            spreadsWidth: 5.0,
            profitTarget: 0.75,
            stopLoss: 2.00
        )
        
        static let momentumBreakout = MomentumBreakoutParams(
            minVolumeMultiple: 2.0,
            rsiThreshold: 60.0,
            callVolumeMultiple: 3.0,
            targetReturns: 1.0...2.0,
            timeHorizonDays: 3,
            entryWindows: ["9:30-10:30", "10:15", "14:00-15:00"]
        )
        
        static let preMarketInstitutionalFlow = PreMarketInstitutionalFlowParams(
            primaryWindow: "08:00-09:00",
            peakWindow: "08:15-08:45",
            avoidWindow: "06:00-07:30",
            minOptionsVolumeMultiple: 3.0,
            requiredMultipleStrikes: true
        )
        
        static let weeklyOptionsExpiration = WeeklyOptionsExpirationParams(
            targetDays: [.monday, .wednesday, .friday],
            maxOTMProbability: 0.20,
            targetCredit: 0.25...0.40,
            avoidEarningsWeeks: true,
            avoidFedMeetings: true
        )
        
        // Updated legacy strategies with refined criteria
        static let gapAndGo = GapAndGoParams(
            minGapPercent: 0.5,  // Updated from 2.0 to match gap fill strategy
            minVolume: 500_000,
            stopLoss: 1.5,
            target: 2.0,
            timeWindow: "9:30-10:00"
        )
        
        static let vwapReversal = VWAPParams(
            minVolume: 750_000,
            vwapDeviation: 0.5,
            stopLoss: 1.0,
            target: 2.0,
            timeWindow: "11:30-13:30"
        )
        
        static let powerHour = PowerHourParams(
            minVolume: 1_000_000,
            momentumBars: 2,
            stopLoss: 0.75,
            target: 1.5,
            timeWindow: "15:00-16:00"
        )
        
        static let panicReversal = PanicParams(
            minDrop: 3.0,
            minVolumeSpike: 2_000_000,
            stopLoss: 1.0,
            target: 3.0
        )
    }

    struct Testing {
        static let nextTradingTestDate = "v1.0.0 Release"
    }

    struct CloseManagement {
        static let generalWarningKey = "closeManagement.generalWarning"
        static let generalHardExitKey = "closeManagement.generalHardExit"
        static let institutionalWarningKey = "closeManagement.institutionalWarning"
        static let institutionalHardExitKey = "closeManagement.institutionalHardExit"

        static let defaultGeneralWarning = "15:55"
        static let defaultGeneralHardExit = "16:10"
        static let defaultInstitutionalWarning = "16:05"
        static let defaultInstitutionalHardExit = "16:15"

        private static let easternTimeZone = TimeZone(identifier: "America/New_York")!
        private static let storageFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeZone = easternTimeZone
            formatter.dateFormat = "HH:mm"
            return formatter
        }()

        private static let displayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeZone = easternTimeZone
            formatter.dateFormat = "h:mm a"
            return formatter
        }()

        static var generalWarningTime: String {
            UserDefaults.standard.string(forKey: generalWarningKey) ?? defaultGeneralWarning
        }

        static var generalHardExitTime: String {
            UserDefaults.standard.string(forKey: generalHardExitKey) ?? defaultGeneralHardExit
        }

        static var institutionalWarningTime: String {
            UserDefaults.standard.string(forKey: institutionalWarningKey) ?? defaultInstitutionalWarning
        }

        static var institutionalHardExitTime: String {
            UserDefaults.standard.string(forKey: institutionalHardExitKey) ?? defaultInstitutionalHardExit
        }

        static func warningTime(for strategy: Strategy) -> String {
            usesInstitutionalTiming(for: strategy) ? institutionalWarningTime : generalWarningTime
        }

        static func hardExitTime(for strategy: Strategy) -> String {
            usesInstitutionalTiming(for: strategy) ? institutionalHardExitTime : generalHardExitTime
        }

        static func displayTime(_ timeString: String) -> String {
            guard let date = date(from: timeString) else { return timeString }
            return displayFormatter.string(from: date)
        }

        static func date(from timeString: String) -> Date? {
            let parts = timeString.split(separator: ":")
            guard parts.count == 2,
                  let hour = Int(parts[0]),
                  let minute = Int(parts[1]) else {
                return nil
            }

            let calendar = Calendar.current
            var components = calendar.dateComponents(in: easternTimeZone, from: Date())
            components.hour = hour
            components.minute = minute
            components.second = 0
            components.nanosecond = 0
            components.timeZone = easternTimeZone
            return calendar.date(from: components)
        }

        static func storageTime(from date: Date) -> String {
            storageFormatter.string(from: date)
        }

        private static func usesInstitutionalTiming(for strategy: Strategy) -> Bool {
            strategy == .vxxInstitutionalFlow
        }
    }
    
    // API key stored in Keychain, not UserDefaults
    private static let apiKeyKeychainKey = "com.ballsofsteel.schwabApiKey"

    static var apiKey: String {
        get { KeychainService.load(key: apiKeyKeychainKey) ?? "" }
        set {
            if newValue.isEmpty {
                KeychainService.delete(key: apiKeyKeychainKey)
            } else {
                KeychainService.save(key: apiKeyKeychainKey, value: newValue)
            }
        }
    }
}
