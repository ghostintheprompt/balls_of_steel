import Foundation

// MARK: - Finnhub Provider (Phase 6, v1.0 default)
//
// Free tier: 60 req/min, real-time US equities via REST + WebSocket.
// Sign-up required at https://finnhub.io/. Stash the key in Keychain via
// the existing `KeychainService`. Methods below are SCAFFOLDED — they construct
// the right URLs but throw `notConfigured` until the key is stored AND the
// network code is wired. Real implementation lands in the next session that
// touches the data feed.

struct FinnhubProvider: MarketDataProvider {
    let id: MarketDataProviderID = .finnhub
    let displayName = "Finnhub (free tier)"
    let requiresApiKey = true
    let apiKeyHelpURL = URL(string: "https://finnhub.io/dashboard")
    let deliversRealtime = true
    let setupNote = "Free tier: 60 req/min, real-time US equities. Sign up at finnhub.io and paste the key in Settings."

    private static let keychainKey = "finnhub.apiKey"
    private static let restBase = URL(string: "https://finnhub.io/api/v1")!

    private var apiKey: String? {
        // Fetch from KeychainService once it exposes a generic getter; for now
        // read from UserDefaults to keep the scaffolding inert.
        UserDefaults.standard.string(forKey: Self.keychainKey)
    }

    func quote(_ symbol: String) async throws -> Quote {
        guard let key = apiKey, !key.isEmpty else {
            throw MarketDataProviderError.notConfigured("Add a Finnhub API key in Settings → Data Source.")
        }
        // URL: GET /quote?symbol=VXX&token=KEY
        // Returns: { c: current, h: high, l: low, o: open, pc: previousClose, t: timestamp }
        throw MarketDataProviderError.notImplemented("Finnhub /quote REST call pending implementation.")
    }

    func vwap(_ symbol: String) async throws -> Double {
        // Finnhub free tier doesn't expose VWAP directly. Compute from /stock/candle resolution=1.
        throw MarketDataProviderError.notImplemented("Finnhub VWAP composition from /stock/candle pending.")
    }

    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double {
        // GET /stock/candle?symbol=X&resolution=D&from=...&to=...
        throw MarketDataProviderError.notImplemented("Finnhub volume-vs-average from /stock/candle pending.")
    }

    func subscribe(_ symbols: [String]) -> AsyncStream<Quote> {
        // wss://ws.finnhub.io?token=KEY
        // Send {"type":"subscribe","symbol":"VXX"} for each symbol.
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
