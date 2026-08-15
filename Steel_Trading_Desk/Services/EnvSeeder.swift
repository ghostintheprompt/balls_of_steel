import Foundation

// MARK: - EnvSeeder (DEBUG only)
//
// Reads Debug-only process environment values and seeds Keychain entries that
// aren't already set. Values can be added to the Xcode scheme or exported by a
// local launch wrapper. They are not copied into the app bundle.
//
// CRITICAL: This loader compiles only in Debug. Release/TestFlight builds
// never call it. Do not add `.env` back to the Xcode resource phase.

enum EnvSeeder {
    static func seedFromDebugEnvironmentIfNeeded() {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        for envKey in ["SCHWAB_APP_KEY", "SCHWAB_APP_SECRET"] {
            guard let value = environment[envKey] else { continue }
            switch envKey {
            case "SCHWAB_APP_KEY":
                if !valueLooksReal(value) { continue }
                let cleaned = AppConfig.Schwab.sanitizedAppKey(value)
                KeychainService.cacheSessionValue(cleaned, for: AppConfig.Schwab.appKeyKeychainKey)
                if !(AppConfig.Schwab.appKeyStored || AppConfig.Schwab.developerCredentialsStored) {
                    AppConfig.Schwab.appKey = cleaned
                }
                AppConfig.Schwab.appKeyStored = true
                print("[EnvSeeder] loaded Schwab app key from process environment for this debug session")
            case "SCHWAB_APP_SECRET":
                if !valueLooksReal(value) { continue }
                let cleaned = AppConfig.Schwab.sanitizedCredential(value)
                KeychainService.cacheSessionValue(cleaned, for: AppConfig.Schwab.appSecretKeychainKey)
                if !(AppConfig.Schwab.appSecretStored || AppConfig.Schwab.developerCredentialsStored) {
                    AppConfig.Schwab.appSecret = cleaned
                }
                AppConfig.Schwab.appSecretStored = true
                print("[EnvSeeder] loaded Schwab app secret from process environment for this debug session")
            default:
                continue
            }
        }
        if let rawCallback = environment["SCHWAB_CALLBACK_URL"],
           valueLooksReal(rawCallback) {
            let sanitized = AppConfig.Schwab.sanitizedCallbackURL(rawCallback)
            let callback = AppConfig.Schwab.isLoopbackCallbackURL(sanitized)
                ? AppConfig.Schwab.appLinkCallbackURL
                : sanitized
            if let url = URL(string: callback),
               url.scheme == "https",
               url.host != nil {
                AppConfig.Schwab.oauthCallbackURL = callback
                print("[EnvSeeder] loaded Schwab callback URL from process environment for this debug session")
            }
        }

        let hasSchwabKey = valueLooksReal(environment["SCHWAB_APP_KEY"] ?? "")
        let hasSchwabSecret = valueLooksReal(environment["SCHWAB_APP_SECRET"] ?? "")
        if hasSchwabKey && hasSchwabSecret {
            AppConfig.Schwab.developerCredentialsStored = true
            AppConfig.Schwab.appKeyStored = true
            AppConfig.Schwab.appSecretStored = true
        }
        #endif
    }

    private static func valueLooksReal(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        let placeholder = ["your_", "YOUR_", "<", "TODO", "xxx", "XXX"]
        return !placeholder.contains(where: { value.hasPrefix($0) })
    }
}
