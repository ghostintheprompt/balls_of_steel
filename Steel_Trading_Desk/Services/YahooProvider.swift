import Foundation

// MARK: - Yahoo Finance Unofficial Provider (Phase 6, fallback)
//
// query1.finance.yahoo.com/v8/finance/chart/<SYMBOL> — no key, returns OHLCV.
// 15-min delayed for cash equities. Use when nothing else is configured.
// Status footer in the host view shows "DELAYED" so the trader is never
// confused about freshness.

struct YahooProvider: MarketDataProvider {
    let id: MarketDataProviderID = .yahoo
    let displayName = "Yahoo (delayed, no key)"
    let requiresApiKey = false
    let apiKeyHelpURL: URL? = nil
    let deliversRealtime = false
    let setupNote = "No signup. 15-minute delayed. Fine for after-hours review, never for entries."

    private static let chartBase = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart")!

    func quote(_ symbol: String) async throws -> Quote {
        // GET /v8/finance/chart/VXX?range=1d&interval=5m
        throw MarketDataProviderError.notImplemented("Yahoo unofficial /chart REST pending.")
    }

    func vwap(_ symbol: String) async throws -> Double {
        throw MarketDataProviderError.notImplemented("Yahoo VWAP composition pending.")
    }

    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double {
        throw MarketDataProviderError.notImplemented("Yahoo volume-vs-average pending.")
    }

    func subscribe(_ symbols: [String]) -> AsyncStream<Quote> {
        // Yahoo unofficial has no streaming WS. Polling-only path.
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
