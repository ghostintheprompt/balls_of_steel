import Foundation
import SwiftUI

struct AppConfig {
    // MARK: - Schwab Trader API
    //
    // Steel uses Schwab for market data only. Order/account endpoints remain
    // out of scope for the product, even if the portal displays order-throttle
    // fields during app registration.
    struct Schwab {
        static let apiBaseURL = "https://api.schwabapi.com"
        static let marketDataBaseURL = "\(apiBaseURL)/marketdata/v1"
        static let traderBaseURL = "\(apiBaseURL)/trader/v1"
        static let oauthAuthorizeURL = "\(apiBaseURL)/v1/oauth/authorize"
        static let oauthTokenURL = "\(apiBaseURL)/v1/oauth/token"

        // Schwab requires HTTPS callback URLs. Register exactly this value in
        // the Schwab portal for local Mac/token-helper testing: no path, no
        // trailing slash, and use 127.0.0.1 instead of localhost.
        static let loopbackCallbackURL = "https://127.0.0.1:8182"

        // Internal app return URL. Do not register this with Schwab; the portal
        // rejects non-HTTPS callbacks.
        static let nativeReturnURL = "steeltradingdesk://oauth/callback"

        // The Streamer URL and customer/correlation credentials are returned
        // by Schwab's userPreference endpoint for the authenticated user.
        static let streamerInfoPath = "/userPreference"

        static let appKeyKeychainKey = "app.mdrn.steel.schwabAppKey"
        static let appSecretKeychainKey = "app.mdrn.steel.schwabAppSecret"
        static let accessTokenKeychainKey = "app.mdrn.steel.schwabAccessToken"
        static let refreshTokenKeychainKey = "app.mdrn.steel.schwabRefreshToken"
        static let appKeyStoredKey = "schwabAppKeyStored"
        static let appSecretStoredKey = "schwabAppSecretStored"
        static let accessTokenStoredKey = "schwabAccessTokenStored"
        static let refreshTokenStoredKey = "schwabRefreshTokenStored"
        static let developerCredentialsStoredKey = "schwabDeveloperCredentialsStored"
        static let oauthTokensStoredKey = "schwabOAuthTokensStored"

        static var appKey: String {
            get { KeychainService.load(key: appKeyKeychainKey) ?? "" }
            set {
                AppConfig.storeKeychainValue(newValue, key: appKeyKeychainKey)
                appKeyStored = !newValue.isEmpty
                developerCredentialsStored = appKeyStored && appSecretStored
            }
        }

        static var appSecret: String {
            get { KeychainService.load(key: appSecretKeychainKey) ?? "" }
            set {
                AppConfig.storeKeychainValue(newValue, key: appSecretKeychainKey)
                appSecretStored = !newValue.isEmpty
                developerCredentialsStored = appKeyStored && appSecretStored
            }
        }

        static var hasDeveloperCredentials: Bool {
            developerCredentialsStored || (appKeyStored && appSecretStored)
        }

        static var hasOAuthTokens: Bool {
            oauthTokensStored || (accessTokenStored && refreshTokenStored)
        }

        static var appKeyStored: Bool {
            get { UserDefaults.standard.bool(forKey: appKeyStoredKey) }
            set { UserDefaults.standard.set(newValue, forKey: appKeyStoredKey) }
        }

        static var appSecretStored: Bool {
            get { UserDefaults.standard.bool(forKey: appSecretStoredKey) }
            set { UserDefaults.standard.set(newValue, forKey: appSecretStoredKey) }
        }

        static var accessToken: String {
            get { KeychainService.load(key: accessTokenKeychainKey) ?? "" }
            set {
                AppConfig.storeKeychainValue(newValue, key: accessTokenKeychainKey)
                accessTokenStored = !newValue.isEmpty
                oauthTokensStored = accessTokenStored && refreshTokenStored
            }
        }

        static var refreshToken: String {
            get { KeychainService.load(key: refreshTokenKeychainKey) ?? "" }
            set {
                AppConfig.storeKeychainValue(newValue, key: refreshTokenKeychainKey)
                refreshTokenStored = !newValue.isEmpty
                oauthTokensStored = accessTokenStored && refreshTokenStored
            }
        }

        static var accessTokenStored: Bool {
            get { UserDefaults.standard.bool(forKey: accessTokenStoredKey) }
            set { UserDefaults.standard.set(newValue, forKey: accessTokenStoredKey) }
        }

        static var refreshTokenStored: Bool {
            get { UserDefaults.standard.bool(forKey: refreshTokenStoredKey) }
            set { UserDefaults.standard.set(newValue, forKey: refreshTokenStoredKey) }
        }

        static var developerCredentialsStored: Bool {
            get { UserDefaults.standard.bool(forKey: developerCredentialsStoredKey) }
            set { UserDefaults.standard.set(newValue, forKey: developerCredentialsStoredKey) }
        }

        static var oauthTokensStored: Bool {
            get { UserDefaults.standard.bool(forKey: oauthTokensStoredKey) }
            set { UserDefaults.standard.set(newValue, forKey: oauthTokensStoredKey) }
        }
    }

    // Legacy aliases kept until the Schwab service rewrite removes the old API
    // key shape. New Schwab work should use AppConfig.Schwab.
    static let baseURL = Schwab.apiBaseURL
    static let streamURL = ""
    static let clientId = ""
    
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
        static let nextTradingTestDate = "Field Test"
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
    private static let apiKeyKeychainKey = "app.mdrn.steel.schwabApiKey"

    static var apiKey: String {
        get { KeychainService.load(key: apiKeyKeychainKey) ?? "" }
        set {
            storeKeychainValue(newValue, key: apiKeyKeychainKey)
        }
    }

    private static func storeKeychainValue(_ value: String, key: String) {
        if value.isEmpty {
            KeychainService.delete(key: key)
        } else {
            KeychainService.save(key: key, value: value)
        }
    }
}
