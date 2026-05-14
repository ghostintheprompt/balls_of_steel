import Foundation

// MARK: - Polygon.io Provider (Phase 6, paid tier)
//
// Stocks Starter: $29/mo, real-time NBBO, REST + WebSocket. Recommended when
// the trader is past the free-tier rate limits or needs options chains.
// Scaffolded; real REST + WS code lands when an API key is provisioned.

struct PolygonProvider: MarketDataProvider {
    let id: MarketDataProviderID = .polygon
    let displayName = "Polygon.io (paid)"
    let requiresApiKey = true
    let apiKeyHelpURL = URL(string: "https://polygon.io/dashboard")
    let deliversRealtime = true
    let setupNote = "Stocks Starter ($29/mo): real-time NBBO + options. Best when serious."

    private static let keychainKey = "polygon.apiKey"
    private static let restBase = URL(string: "https://api.polygon.io")!

    private var apiKey: String? {
        UserDefaults.standard.string(forKey: Self.keychainKey)
    }

    func quote(_ symbol: String) async throws -> Quote {
        guard let key = apiKey, !key.isEmpty else {
            throw MarketDataProviderError.notConfigured("Add a Polygon.io API key in Settings → Data Source.")
        }
        // GET /v2/snapshot/locale/us/markets/stocks/tickers/VXX?apiKey=KEY
        throw MarketDataProviderError.notImplemented("Polygon /v2/snapshot pending implementation.")
    }

    func vwap(_ symbol: String) async throws -> Double {
        // GET /v2/aggs/ticker/VXX/range/1/minute/<from>/<to>?apiKey=KEY → vw field per bar.
        throw MarketDataProviderError.notImplemented("Polygon /v2/aggs VWAP pending.")
    }

    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double {
        throw MarketDataProviderError.notImplemented("Polygon /v2/aggs daily volume average pending.")
    }

    func subscribe(_ symbols: [String]) -> AsyncStream<Quote> {
        // wss://socket.polygon.io/stocks
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
