import Foundation
import Combine

// MARK: - EDUCATIONAL MODE SERVICE
// This app is an educational tool. All data must be entered manually.
// Connect to your own trading platform (ThinkOrSwim, Schwab, etc.) for live execution.

class SchwabService: ObservableObject {
    static let shared = SchwabService()
    @Published var isConnected = false

    private init() {
        // Educational mode - no live connections
        isConnected = false
    }

    // MARK: - Educational Sample Data
    // These methods return example data for learning the VXX system

    /// Returns sample quote data for educational purposes
    /// IMPORTANT: Enter real data manually in the VXX Dashboard
    func fetchQuote(_ symbol: String) async throws -> Quote {
        // Simulate network delay for realistic experience
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        return generateSampleQuote(for: symbol)
    }

    /// Educational mode - No live order execution
    /// Execute trades manually on your own platform
    func placeOrder(order: Order) async throws -> OrderResponse {
        throw SchwabError.educationalModeOnly
    }

    /// Educational mode - No live streaming
    /// Use manual data entry in the dashboard
    func streamQuotes(symbols: [String]) async throws {
        throw SchwabError.educationalModeOnly
    }

    /// Educational mode - No live quote subscriptions
    /// Enter data manually to practice the system
    func subscribeToQuotes(symbol: String) -> AnyPublisher<Quote, Never> {
        // Return empty publisher - use manual data entry instead
        return Empty().eraseToAnyPublisher()
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
                bid: 42.12,
                ask: 42.18,
                volume: 3_400_000, // 340% of typical 1M volume
                averageVolume: 1_000_000,
                change: 1.25,
                changePercent: 3.05,
                timestamp: now
            )
        case "VIX":
            return Quote(
                symbol: "VIX",
                price: 18.50,
                bid: 18.45,
                ask: 18.55,
                volume: 0,
                averageVolume: 0,
                change: 2.10,
                changePercent: 12.80,
                timestamp: now
            )
        default:
            return Quote(
                symbol: symbol,
                price: 100.0,
                bid: 99.95,
                ask: 100.05,
                volume: 100_000,
                averageVolume: 50_000,
                change: 0.50,
                changePercent: 0.50,
                timestamp: now
            )
        }
    }

    // MARK: - Educational Options Data
    /// Returns sample options chain for learning
    /// IMPORTANT: Use real options data from your platform
    func fetchOptionsChain(symbol: String, daysToExpiration: Int = 4) async throws -> OptionsChain {
        try await Task.sleep(nanoseconds: 500_000_000)

        return OptionsChain(
            symbol: symbol,
            calls: generateSampleOptions(type: .call, underlying: 42.15),
            puts: generateSampleOptions(type: .put, underlying: 42.15),
            underlyingPrice: 42.15
        )
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
    private func generateSampleOptions(type: OptionType, underlying: Double) -> [OptionContract] {
        let strikes = stride(from: underlying - 5, through: underlying + 5, by: 1.0)
        let expiration = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

        return strikes.map { strike in
            let distance = abs(strike - underlying)
            let premium = max(0.1, 2.0 - distance * 0.3)

            return OptionContract(
                strike: strike,
                expiration: expiration,
                bid: premium - 0.05,
                ask: premium + 0.05,
                last: premium,
                volume: Int.random(in: 100...1000),
                openInterest: Int.random(in: 500...5000),
                delta: type == .call ? 0.5 : -0.5,
                gamma: 0.05,
                theta: -0.08,
                vega: 0.12,
                impliedVolatility: 85.5
            )
        }
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
                timestamp: now.addingTimeInterval(TimeInterval(-count + i) * 300), // 5 min intervals
                open: open,
                high: high,
                low: low,
                close: close,
                volume: Int.random(in: 50_000...150_000)
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

    enum OptionType {
        case call, put
    }
}

// MARK: - Supporting Data Structures
struct OptionsChain: Codable {
    let symbol: String
    let calls: [OptionContract]
    let puts: [OptionContract]
    let underlyingPrice: Double
}

struct OptionContract: Codable {
    let strike: Double
    let expiration: Date
    let bid: Double
    let ask: Double
    let last: Double
    let volume: Int
    let openInterest: Int
    let delta: Double
    let gamma: Double
    let theta: Double
    let vega: Double
    let impliedVolatility: Double
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