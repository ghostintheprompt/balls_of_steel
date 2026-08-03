import Foundation
import SwiftUI

// MARK: - Market Data Provider Protocol (Phase 6)
//
// One protocol, multiple backends. Default at v1.0 ship: Finnhub free tier.
// Schwab demoted from default to power-user opt-in. Yahoo as silent fallback.
// Each provider conforms by implementing quote/vwap/volume/subscribe.

protocol MarketDataProvider {
    var id: MarketDataProviderID { get }
    var displayName: String { get }
    var requiresApiKey: Bool { get }
    var apiKeyHelpURL: URL? { get }
    var deliversRealtime: Bool { get }
    var setupNote: String { get }

    func quote(_ symbol: String) async throws -> Quote
    func vwap(_ symbol: String) async throws -> Double
    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double
    func subscribe(_ symbols: [String]) -> AsyncStream<Quote>
}

enum MarketDataProviderID: String, CaseIterable, Identifiable {
    case finnhub
    case polygon
    case schwab
    case yahoo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .finnhub: return "Finnhub"
        case .polygon: return "Polygon"
        case .schwab:  return "Schwab"
        case .yahoo:   return "Yahoo"
        }
    }
}

enum MarketDataProviderError: LocalizedError {
    case notConfigured(String)
    case notImplemented(String)
    case network(String)
    case unsupportedSymbol(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let detail): return "Provider not configured. \(detail)"
        case .notImplemented(let detail): return "Provider not yet implemented. \(detail)"
        case .network(let detail): return "Network error: \(detail)"
        case .unsupportedSymbol(let s): return "Unsupported symbol: \(s)"
        }
    }
}

// MARK: - Registry
//
// Single source of truth for which provider is active. Persisted via @AppStorage
// in the host view; this class just holds the resolved provider so callers don't
// have to know the wiring.

@MainActor
final class MarketDataRegistry: ObservableObject {
    static let shared = MarketDataRegistry()

    @Published private(set) var active: MarketDataProvider

    private init() {
        let stored = UserDefaults.standard.string(forKey: "marketDataProviderID") ?? MarketDataProviderID.finnhub.rawValue
        let id = MarketDataProviderID(rawValue: stored) ?? .finnhub
        self.active = Self.makeProvider(for: id)
    }

    func use(_ id: MarketDataProviderID) {
        active = Self.makeProvider(for: id)
        UserDefaults.standard.set(id.rawValue, forKey: "marketDataProviderID")
    }

    private static func makeProvider(for id: MarketDataProviderID) -> MarketDataProvider {
        switch id {
        case .finnhub: return FinnhubProvider()
        case .polygon: return PolygonProvider()
        case .schwab:  return SchwabProviderAdapter()
        case .yahoo:   return YahooProvider()
        }
    }
}

// MARK: - Schwab adapter
//
// Wraps the existing SchwabService so it conforms to MarketDataProvider without
// changing SchwabService itself. Methods route through the existing service.

struct SchwabProviderAdapter: MarketDataProvider {
    let id: MarketDataProviderID = .schwab
    let displayName = "Schwab (brokerage)"
    let requiresApiKey = true
    let apiKeyHelpURL = URL(string: "https://developer.schwab.com")
    let deliversRealtime = true
    let setupNote = "Requires a Schwab developer account, app key, app secret, and OAuth connection."

    func quote(_ symbol: String) async throws -> Quote {
        try await SchwabService.shared.fetchQuote(symbol)
    }

    func vwap(_ symbol: String) async throws -> Double {
        try await SchwabService.shared.vwap(symbol)
    }

    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double {
        try await SchwabService.shared.volumeVsAvg(symbol, period: period)
    }

    func subscribe(_ symbols: [String]) -> AsyncStream<Quote> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    for symbol in symbols {
                        guard !Task.isCancelled else { break }
                        if let quote = try? await SchwabService.shared.fetchQuote(symbol) {
                            continuation.yield(quote)
                        }
                    }
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
