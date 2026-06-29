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
        for envKey in ["FINNHUB_API_KEY", "POLYGON_API_KEY", "SCHWAB_APP_KEY", "SCHWAB_APP_SECRET"] {
            guard let value = environment[envKey] else { continue }
            switch envKey {
            case "FINNHUB_API_KEY":
                if !valueLooksReal(value) { continue }
                if KeychainService.load(key: FinnhubProvider.keychainKey) == nil {
                    KeychainService.save(key: FinnhubProvider.keychainKey, value: value)
                    print("[EnvSeeder] seeded Finnhub key from process environment")
                }
            case "POLYGON_API_KEY":
                if !valueLooksReal(value) { continue }
                if KeychainService.load(key: PolygonProvider.keychainKey) == nil {
                    KeychainService.save(key: PolygonProvider.keychainKey, value: value)
                    print("[EnvSeeder] seeded Polygon key from process environment")
                }
            case "SCHWAB_APP_KEY":
                if !valueLooksReal(value) { continue }
                if AppConfig.Schwab.appKeyStored || AppConfig.Schwab.developerCredentialsStored { continue }
                AppConfig.Schwab.appKey = value
                print("[EnvSeeder] seeded Schwab app key from process environment")
            case "SCHWAB_APP_SECRET":
                if !valueLooksReal(value) { continue }
                if AppConfig.Schwab.appSecretStored || AppConfig.Schwab.developerCredentialsStored { continue }
                AppConfig.Schwab.appSecret = value
                print("[EnvSeeder] seeded Schwab app secret from process environment")
            default:
                continue
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
