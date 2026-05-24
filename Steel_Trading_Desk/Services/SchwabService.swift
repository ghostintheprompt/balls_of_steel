import Foundation
import Combine

// MARK: - EDUCATIONAL MODE SERVICE
// This app is an educational tool. All data must be entered manually.
// Connect to your own trading platform (ThinkOrSwim, Schwab, etc.) for live execution.

class SchwabService: ObservableObject {
    static let shared = SchwabService()
    @Published var isConnected = false

    private init() {}
    func fetchQuote(_ symbol: String) async throws -> Quote {
        try await Task.sleep(nanoseconds: 800_000_000)
        return generateSampleQuote(for: symbol)
    }

    /// Educational mode - No live order execution
    func placeOrder(order: Order) async throws -> OrderResponse {
        throw SchwabError.educationalModeOnly 
    }

    /// Educational mode - No live streaming
    /// Use manual data entry in the dashboard
    func streamQuotes(symbols: [String]) async throws {
        throw SchwabError.educationalModeOnly
    }

    /// Educational mode - No live quote subscriptions
    /// Enter data manually to practice the desk read
    func subscribeToQuotes(symbol: String) -> AnyPublisher<Quote, Never> {
        // Return empty publisher - use manual data entry instead
        return Empty().eraseToAnyPublisher()
    }

    /// Educational mode - OAuth not required
    /// This app is for manual data entry only
    func exchangeCodeForToken(_ code: String) async throws -> String {
        throw SchwabError.educationalModeOnly
    }

    // MARK: - Error Handling
    enum SchwabError: Error {
        case educationalModeOnly
        case invalidResponse

        var localizedDescription: String {
            switch self {
            case .educationalModeOnly:
                return "This app is educational only. Execute trades on your own platform (ThinkOrSwim, Schwab, TD Ameritrade, etc.)"
            case .invalidResponse:
                return "Invalid sample data format"
            }
        }
    }

    // MARK: - Sample Data Generation
    /// Generate realistic sample quote for educational purposes
    private func generateSampleQuote(for symbol: String) -> Quote {
        let now = Date()

        switch symbol {
        case "VXX":
            return Quote(
                symbol: "VXX",
                price: 42.15,
                volume: 3_400_000, // 340% of typical 1M volume
                vwap: 41.80,
                previousClose: 40.90,
                timestamp: now,
                recentCandles: []
            )
        case "VIX":
            return Quote(
                symbol: "VIX",
                price: 18.50,
                volume: 0,
                vwap: 18.40,
                previousClose: 16.40,
                timestamp: now,
                recentCandles: []
            )
        default:
            return Quote(
                symbol: symbol,
                price: 100.0,
                volume: 100_000,
                vwap: 99.50,
                previousClose: 99.50,
                timestamp: now,
                recentCandles: []
            )
        }
    }

    // MARK: - Educational Options Data
    /// Returns sample options chain for learning
    /// IMPORTANT: Use real options data from your platform
    func fetchOptionsChain(symbol: String, daysToExpiration: Int = 4) async throws -> OptionsChain {
        try await Task.sleep(nanoseconds: 500_000_000)
        return sampleChain(symbol: symbol)
    }

    /// Synchronous educational chain — used by the entry card's suggestion
    /// strip so it can render without async plumbing. Live wire-up will
    /// replace this with a cached chain from the live Schwab feed.
    func sampleChain(symbol: String) -> OptionsChain {
        let underlying = sampleUnderlyingPrice(for: symbol)
        return OptionsChain(
            symbol: symbol,
            calls: generateSampleOptions(symbol: symbol, type: .call, underlying: underlying),
            puts: generateSampleOptions(symbol: symbol, type: .put, underlying: underlying),
            underlyingPrice: underlying
        )
    }

    private func sampleUnderlyingPrice(for symbol: String) -> Double {
        switch symbol {
        case "VXX": return 42.15
        case "SPY": return 450.00
        case "VIX": return 18.50
        default:    return 100.00
        }
    }

    /// Returns sample IV data for learning
    func fetchImpliedVolatility(symbol: String) async throws -> ImpliedVolatilityData {
        try await Task.sleep(nanoseconds: 500_000_000)

        return ImpliedVolatilityData(
            symbol: symbol,
            iv: 85.5,
            ivRank: 72.0,
            ivPercentile: 68.0,
            timestamp: Date()
        )
    }

    /// Returns sample VXX/VIX data for learning
    func fetchVXXVIXData() async throws -> (vxx: Quote, vix: Quote) {
        try await Task.sleep(nanoseconds: 500_000_000)

        return (
            vxx: generateSampleQuote(for: "VXX"),
            vix: generateSampleQuote(for: "VIX")
        )
    }

    /// Returns sample candles for learning pattern recognition
    func fetchHistoricalCandles(symbol: String, period: CandlePeriod = .fiveMinutes, days: Int = 5) async throws -> [Candle] {
        try await Task.sleep(nanoseconds: 500_000_000)

        return generateSampleCandles(symbol: symbol, count: 50)
    }

    // MARK: - Helper Methods
    private func generateSampleOptions(symbol: String, type: OptionType, underlying: Double) -> [OptionContract] {
        // Multiple expirations across the DTE band (1, 4, 7) so the
        // tightened-suggestion path can find a candidate in 3–7.
        let dteValues = [1, 4, 7]
        let strikeStep = underlying < 50 ? 0.5 : 1.0
        let strikeRange = strikeStep * 6   // ±6 strikes from spot
        let strikes = stride(from: underlying - strikeRange, through: underlying + strikeRange, by: strikeStep)

        var contracts: [OptionContract] = []
        for dte in dteValues {
            guard let expiration = Calendar.current.date(byAdding: .day, value: dte, to: Date()) else { continue }
            for strike in strikes {
                contracts.append(syntheticContract(
                    symbol: symbol,
                    type: type,
                    underlying: underlying,
                    strike: strike,
                    expiration: expiration
                ))
            }
        }
        return contracts
    }

    /// One contract worth of sample data with a realistic delta gradient and
    /// premium curve. Calls: higher Δ when strike < underlying. Puts: higher
    /// |Δ| when strike > underlying. Spread tightens near ATM.
    private func syntheticContract(
        symbol: String,
        type: OptionType,
        underlying: Double,
        strike: Double,
        expiration: Date
    ) -> OptionContract {
        let moneyness = (strike - underlying) / underlying    // <0 = ITM call / OTM put
        // Linear-ish delta proxy clamped to (0.02, 0.98). Slope tuned so ATM
        // sits near 0.50 and one-strike-OTM lands in the 0.40–0.45 band.
        let rawCallDelta = 0.50 - moneyness * 8.0
        let callDelta = min(0.98, max(0.02, rawCallDelta))
        let putDelta  = callDelta - 1.0                       // put-call parity proxy
        let delta = type == .call ? callDelta : putDelta

        // Premium curve: peak at ATM, decays with |moneyness|.
        let basePremium = underlying * 0.03
        let premium = max(0.10, basePremium * (1 - min(0.85, abs(moneyness) * 8)))
        // Spread tighter when |Δ| is near 0.5 (most liquid strikes).
        let spread = max(0.03, 0.10 * (1 - (1 - abs(abs(delta) - 0.5) * 2)))

        return OptionContract(
            symbol: "\(symbol)\(type == .call ? "C" : "P")\(Int(strike * 100))",
            strike: strike,
            expiration: expiration,
            type: type,
            bid: max(0.01, premium - spread / 2),
            ask: premium + spread / 2,
            last: premium,
            volume: Int.random(in: 100...1000),
            openInterest: Int.random(in: 500...5000),
            delta: delta,
            gamma: 0.05,
            theta: -0.08,
            vega: 0.12,
            impliedVolatility: 85.5
        )
    }

    private func generateSampleCandles(symbol: String, count: Int) -> [Candle] {
        var candles: [Candle] = []
        var currentPrice = 42.0
        let now = Date()

        for i in 0..<count {
            let change = Double.random(in: -0.3...0.3)
            currentPrice += change

            let high = currentPrice + Double.random(in: 0...0.2)
            let low = currentPrice - Double.random(in: 0...0.2)
            let open = currentPrice - change / 2
            let close = currentPrice

            let candle = Candle(
                open: open,
                high: high,
                low: low,
                close: close,
                volume: Int.random(in: 50_000...150_000),
                timestamp: now.addingTimeInterval(TimeInterval(-count + i) * 300) // 5 min intervals
            )
            candles.append(candle)
        }

        return candles
    }

    enum CandlePeriod: String {
        case oneMinute = "1m"
        case fiveMinutes = "5m"
        case fifteenMinutes = "15m"
        case thirtyMinutes = "30m"
        case oneHour = "1h"
        case daily = "1d"
    }

}

// MARK: - Supporting Data Structures
struct OptionsChain: Codable {
    let symbol: String
    let calls: [OptionContract]
    let puts: [OptionContract]
    let underlyingPrice: Double
}

struct ImpliedVolatilityData: Codable {
    let symbol: String
    let iv: Double
    let ivRank: Double
    let ivPercentile: Double
    let timestamp: Date
}

struct CandlesResponse: Codable {
    let symbol: String
    let candles: [Candle]
} 
