import Foundation

// MARK: - Market Data Provider Protocol
//
// Schwab is the only live market-data provider. The app can still accept manual
// tape entries, but no delayed/stub provider is allowed to masquerade as live.

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
    case schwab

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .schwab: return "Schwab"
        }
    }
}

enum MarketDataProviderError: LocalizedError {
    case notConfigured(String)
    case network(String)
    case unsupportedSymbol(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let detail): return "Provider not configured. \(detail)"
        case .network(let detail): return "Network error: \(detail)"
        case .unsupportedSymbol(let s): return "Unsupported symbol: \(s)"
        }
    }
}

// MARK: - Registry

@MainActor
final class MarketDataRegistry: ObservableObject {
    static let shared = MarketDataRegistry()

    @Published private(set) var active: MarketDataProvider

    private init() {
        self.active = SchwabProviderAdapter()
        UserDefaults.standard.set(MarketDataProviderID.schwab.rawValue, forKey: "marketDataProviderID")
    }

    func use(_ id: MarketDataProviderID) {
        active = SchwabProviderAdapter()
        UserDefaults.standard.set(MarketDataProviderID.schwab.rawValue, forKey: "marketDataProviderID")
    }
}

// MARK: - Schwab adapter

struct SchwabProviderAdapter: MarketDataProvider {
    let id: MarketDataProviderID = .schwab
    let displayName = "Schwab"
    let requiresApiKey = true
    let apiKeyHelpURL = URL(string: "https://developer.schwab.com")
    let deliversRealtime = true
    let setupNote = "Requires Schwab app key, app secret, and OAuth connection."

    func quote(_ symbol: String) async throws -> Quote {
        guard AppConfig.Schwab.hasOAuthTokens else {
            throw MarketDataProviderError.notConfigured("Connect Schwab OAuth first.")
        }
        return try await SchwabService.shared.fetchQuote(symbol)
    }

    func vwap(_ symbol: String) async throws -> Double {
        guard AppConfig.Schwab.hasOAuthTokens else {
            throw MarketDataProviderError.notConfigured("Connect Schwab OAuth first.")
        }
        return try await SchwabService.shared.vwap(symbol)
    }

    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double {
        guard AppConfig.Schwab.hasOAuthTokens else {
            throw MarketDataProviderError.notConfigured("Connect Schwab OAuth first.")
        }
        return try await SchwabService.shared.volumeVsAvg(symbol, period: period)
    }

    func subscribe(_ symbols: [String]) -> AsyncStream<Quote> {
        AsyncStream { continuation in
            guard AppConfig.Schwab.hasOAuthTokens else {
                continuation.finish()
                return
            }

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
