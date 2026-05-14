import Foundation

// MARK: - EnvSeeder (DEBUG only)
//
// Reads `.env` from the app bundle on launch and seeds Keychain entries that
// aren't already set. Lets a developer drop API keys into a single file
// instead of pasting into Settings every time the simulator gets reset.
//
// CRITICAL: This loader compiles only in Debug. Release/TestFlight builds
// never call it. But the .env file itself IS bundled in any build that
// includes it as a resource — so leave the file empty before archiving.

enum EnvSeeder {
    static func seedFromBundleEnvIfNeeded() {
        #if DEBUG
        guard let url = Bundle.main.url(forResource: ".env", withExtension: nil),
              let raw = try? String(contentsOf: url, encoding: .utf8)
        else { return }

        let pairs = parse(raw)
        for (envKey, value) in pairs {
            switch envKey {
            case "FINNHUB_API_KEY":
                if !valueLooksReal(value) { continue }
                if KeychainService.load(key: FinnhubProvider.keychainKey) == nil {
                    KeychainService.save(key: FinnhubProvider.keychainKey, value: value)
                    print("[EnvSeeder] seeded Finnhub key from .env")
                }
            case "POLYGON_API_KEY":
                if !valueLooksReal(value) { continue }
                if KeychainService.load(key: PolygonProvider.keychainKey) == nil {
                    KeychainService.save(key: PolygonProvider.keychainKey, value: value)
                    print("[EnvSeeder] seeded Polygon key from .env")
                }
            default:
                continue
            }
        }
        #endif
    }

    private static func parse(_ raw: String) -> [(String, String)] {
        var out: [(String, String)] = []
        for rawLine in raw.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            var value = parts[1].trimmingCharacters(in: .whitespaces)
            // strip optional surrounding quotes
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            out.append((key, value))
        }
        return out
    }

    private static func valueLooksReal(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        let placeholder = ["your_", "YOUR_", "<", "TODO", "xxx", "XXX"]
        return !placeholder.contains(where: { value.hasPrefix($0) })
    }
}
