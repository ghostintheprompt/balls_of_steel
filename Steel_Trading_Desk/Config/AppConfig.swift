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

        // Schwab requires HTTPS callback URLs. The authorization request must
        // send one registered redirect_uri, even when the portal displays a
        // comma-separated callback list.
        static let plainLoopbackCallbackURL = "https://127.0.0.1"
        static let portedLoopbackCallbackURL = "https://127.0.0.1:8182"
        static let loopbackCallbackURL = portedLoopbackCallbackURL
        static let appLinkCallbackURL = "https://mdrn.app/apps/steeltradingdesk/schwab/oauth/callback"

        // Internal app return URL. Do not register this with Schwab; the portal
        // rejects non-HTTPS callbacks.
        static let nativeReturnURL = "steeltradingdesk://oauth/callback"

        static var defaultCallbackURL: String {
            #if os(macOS)
            return portedLoopbackCallbackURL
            #else
            return appLinkCallbackURL
            #endif
        }

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
        static let accessTokenExpiresAtKey = "schwabAccessTokenExpiresAt"
        static let oauthCallbackURLKey = "schwabOAuthCallbackURL"
        static let lastOAuthErrorKey = "schwabLastOAuthError"

        static var appKey: String {
            get { sanitizedAppKey(KeychainService.load(key: appKeyKeychainKey) ?? "") }
            set {
                let cleaned = sanitizedAppKey(newValue)
                AppConfig.storeKeychainValue(cleaned, key: appKeyKeychainKey)
                appKeyStored = !cleaned.isEmpty
                developerCredentialsStored = appKeyStored && appSecretStored
            }
        }

        static var appSecret: String {
            get { sanitizedCredential(KeychainService.load(key: appSecretKeychainKey) ?? "") }
            set {
                let cleaned = sanitizedCredential(newValue)
                AppConfig.storeKeychainValue(cleaned, key: appSecretKeychainKey)
                appSecretStored = !cleaned.isEmpty
                developerCredentialsStored = appKeyStored && appSecretStored
            }
        }

        static var rawAppKeyWithoutPrompt: String {
            KeychainService.cachedSessionValue(for: appKeyKeychainKey) ?? ""
        }

        static var appKeyWithoutPrompt: String {
            sanitizedAppKey(rawAppKeyWithoutPrompt)
        }

        static var appKeyNeedsNormalizationWithoutPrompt: Bool {
            let raw = rawAppKeyWithoutPrompt
            return !raw.isEmpty && sanitizedAppKey(raw) != raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        static func sanitizedAppKey(_ value: String) -> String {
            var cleaned = sanitizedCredential(value)

            if let url = URL(string: cleaned),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let clientID = components.queryItems?.first(where: { $0.name == "client_id" })?.value {
                cleaned = sanitizedCredential(clientID)
            } else if let rawClientRange = cleaned.range(of: "client_id=", options: .caseInsensitive) {
                let tail = cleaned[rawClientRange.upperBound...]
                let rawClientID = tail.split(separator: "&", maxSplits: 1).first.map(String.init) ?? String(tail)
                cleaned = sanitizedCredential(rawClientID.removingPercentEncoding ?? rawClientID)
            }

            if let decoded = cleaned.removingPercentEncoding {
                cleaned = decoded
            }

            if let markerRange = cleaned.range(of: "%7C", options: .caseInsensitive) {
                cleaned = String(cleaned[..<markerRange.lowerBound])
            }
            if let pipe = cleaned.firstIndex(of: "|") {
                cleaned = String(cleaned[..<pipe])
            }
            if let ampersand = cleaned.firstIndex(of: "&") {
                cleaned = String(cleaned[..<ampersand])
            }

            return sanitizedCredential(cleaned)
        }

        static func sanitizedCredential(_ value: String) -> String {
            let surroundingJunk = CharacterSet.whitespacesAndNewlines
                .union(CharacterSet(charactersIn: "|\"'`"))
            return asciiFoldedCredential(value.trimmingCharacters(in: surroundingJunk))
        }

        static func credentialHasNonASCII(_ value: String) -> Bool {
            value.unicodeScalars.contains { $0.value > 0x7F }
        }

        static var appKeyNeedsNormalization: Bool {
            let raw = KeychainService.load(key: appKeyKeychainKey) ?? ""
            return !raw.isEmpty && sanitizedAppKey(raw) != raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        static var appSecretNeedsNormalization: Bool {
            let raw = KeychainService.load(key: appSecretKeychainKey) ?? ""
            return !raw.isEmpty && sanitizedCredential(raw) != raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        @discardableResult
        static func normalizeStoredDeveloperCredentials() -> Bool {
            let appKeyChanged = appKeyNeedsNormalization
            let appSecretChanged = appSecretNeedsNormalization

            if appKeyChanged {
                appKey = appKey
            }
            if appSecretChanged {
                appSecret = appSecret
            }

            return appKeyChanged || appSecretChanged
        }

        private static func asciiFoldedCredential(_ value: String) -> String {
            value.unicodeScalars.map { scalar in
                if let replacement = asciiCredentialReplacement(for: scalar) {
                    return replacement
                }
                return String(scalar)
            }
            .joined()
        }

        private static func asciiCredentialReplacement(for scalar: Unicode.Scalar) -> String? {
            switch scalar.value {
            // Zero-width paste artifacts.
            case 0x200B, 0x200C, 0x200D, 0xFEFF:
                return ""

            // Cyrillic characters that are commonly produced by OCR or rich-text
            // copy/paste but look identical to Latin API-key characters.
            case 0x0410: return "A" // А
            case 0x0412: return "B" // В
            case 0x0421: return "C" // С
            case 0x0415: return "E" // Е
            case 0x041D: return "H" // Н
            case 0x041A: return "K" // К
            case 0x041C: return "M" // М
            case 0x041E: return "O" // О
            case 0x0420: return "P" // Р
            case 0x0422: return "T" // Т
            case 0x0425: return "X" // Х
            case 0x0423: return "Y" // У
            case 0x0430: return "a" // а
            case 0x0441: return "c" // с
            case 0x0435: return "e" // е
            case 0x043E: return "o" // о
            case 0x0440: return "p" // р
            case 0x0445: return "x" // х
            case 0x0443: return "y" // у

            // Greek lookalikes seen in pasted credentials.
            case 0x0391: return "A" // Α
            case 0x0392: return "B" // Β
            case 0x0395: return "E" // Ε
            case 0x0397: return "H" // Η
            case 0x0399: return "I" // Ι
            case 0x039A: return "K" // Κ
            case 0x039C: return "M" // Μ
            case 0x039D: return "N" // Ν
            case 0x039F: return "O" // Ο
            case 0x03A1: return "P" // Ρ
            case 0x03A4: return "T" // Τ
            case 0x03A5: return "Y" // Υ
            case 0x03A7: return "X" // Χ
            case 0x03B1: return "a" // α
            case 0x03BF: return "o" // ο
            case 0x03C1: return "p" // ρ
            case 0x03C7: return "x" // χ

            default:
                return nil
            }
        }

        static func sanitizedCallbackURL(_ value: String) -> String {
            preferredCallbackURL(from: value) ?? sanitizedCredential(value)
        }

        static func callbackURLCandidates(from value: String) -> [String] {
            let folded = sanitizedCredential(value)
            let separators = CharacterSet.whitespacesAndNewlines
                .union(CharacterSet(charactersIn: ",;"))
            var seen = Set<String>()

            return folded
                .components(separatedBy: separators)
                .compactMap { piece -> String? in
                    let candidate = sanitizedCredential(piece)
                    guard let url = URL(string: candidate),
                          url.scheme?.lowercased() == "https",
                          url.host != nil,
                          seen.insert(candidate).inserted else {
                        return nil
                    }
                    return candidate
                }
        }

        static func preferredCallbackURL(from value: String) -> String? {
            let candidates = callbackURLCandidates(from: value)
            guard !candidates.isEmpty else { return nil }

            #if os(macOS)
            if candidates.contains(portedLoopbackCallbackURL) {
                return portedLoopbackCallbackURL
            }
            if let loopbackWithPort = candidates.first(where: { candidate in
                let port = callbackPort(candidate)
                return isLoopbackCallbackURL(candidate) && port != nil && port != 443
            }) {
                return loopbackWithPort
            }
            #endif

            if candidates.contains(appLinkCallbackURL) {
                return appLinkCallbackURL
            }
            if let appLinkCallback = candidates.first(where: { !isLoopbackCallbackURL($0) }) {
                return appLinkCallback
            }

            return candidates.first
        }

        static func isLoopbackCallbackURL(_ value: String) -> Bool {
            guard let url = URL(string: sanitizedCredential(value)),
                  url.scheme?.lowercased() == "https",
                  let host = url.host?.lowercased() else {
                return false
            }
            return isLoopbackHost(host)
        }

        private static func callbackPort(_ value: String) -> Int? {
            URL(string: sanitizedCredential(value))?.port
        }

        private static func isLoopbackHost(_ host: String) -> Bool {
            host == "127.0.0.1" || host == "localhost" || host == "::1"
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

        static var accessTokenExpiresAt: Date? {
            get {
                let rawValue = UserDefaults.standard.double(forKey: accessTokenExpiresAtKey)
                guard rawValue > 0 else { return nil }
                return Date(timeIntervalSince1970: rawValue)
            }
            set {
                if let newValue {
                    UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: accessTokenExpiresAtKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: accessTokenExpiresAtKey)
                }
            }
        }

        static var oauthCallbackURL: String {
            get {
                #if os(macOS)
                // Mac OAuth always stays on-device via the local loopback listener.
                // No stored/pasted value (portal callback lists, an App Link URL,
                // stray website links) may ever redirect the flow through
                // mdrn.app — that dependency is a second system to troubleshoot
                // for no benefit when the loopback listener already works.
                return portedLoopbackCallbackURL
                #else
                let stored = UserDefaults.standard.string(forKey: oauthCallbackURLKey)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let cleaned = sanitizedCallbackURL(stored)
                return cleaned.isEmpty ? defaultCallbackURL : cleaned
                #endif
            }
            set {
                #if os(macOS)
                return
                #else
                let trimmed = sanitizedCallbackURL(newValue)
                if trimmed.isEmpty {
                    UserDefaults.standard.removeObject(forKey: oauthCallbackURLKey)
                } else {
                    UserDefaults.standard.set(trimmed, forKey: oauthCallbackURLKey)
                }
                #endif
            }
        }

        // Keep only a user-facing diagnostic. Authorization codes, tokens, and
        // developer credentials must never be written to UserDefaults.
        static var lastOAuthError: String {
            get { UserDefaults.standard.string(forKey: lastOAuthErrorKey) ?? "" }
            set {
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    UserDefaults.standard.removeObject(forKey: lastOAuthErrorKey)
                } else {
                    UserDefaults.standard.set(String(trimmed.prefix(1_000)), forKey: lastOAuthErrorKey)
                }
            }
        }
    }

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

        static let defaultGeneralWarning = "16:10"
        static let defaultGeneralHardExit = "16:15"
        static let defaultInstitutionalWarning = "16:10"
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
    
    private static func storeKeychainValue(_ value: String, key: String) {
        if value.isEmpty {
            KeychainService.delete(key: key)
        } else {
            KeychainService.save(key: key, value: value)
        }
    }
}
