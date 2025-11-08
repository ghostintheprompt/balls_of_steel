import Foundation
import Combine
import WebKit

class SchwabService: ObservableObject {
    static let shared = SchwabService()
    @Published var isConnected = false
    private var webSocket: URLSessionWebSocketTask?
    private var quoteSubjects: [String: PassthroughSubject<Quote, Never>] = [:]
    
    // Base URL for Schwab's API
    private let baseURL = "https://api.schwab.com/v1"
    
    func fetchQuote(_ symbol: String) async throws -> Quote {
        let endpoint = "\(baseURL)/markets/quotes/\(symbol)"
        let request = authenticatedRequest(for: endpoint)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 429 {
            throw SchwabError.rateLimitExceeded
        }
        
        return try handleResponse(data)
    }
    
    func placeOrder(order: Order) async throws -> OrderResponse {
        let endpoint = "\(baseURL)/trading/orders"
        var request = authenticatedRequest(for: endpoint)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(order)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401 {
            throw SchwabError.authenticationFailed
        }
        
        return try handleResponse(data)
    }
    
    private func authenticatedRequest(for endpoint: String) -> URLRequest {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.setValue("Bearer \(AppConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    func streamQuotes(symbols: [String]) async throws {
        guard !isConnected else { return }
        
        let session = URLSession(configuration: .default)
        let wsURL = "\(AppConfig.streamURL)?symbols=\(symbols.joined(separator: ","))"
        guard let url = URL(string: wsURL) else { throw SchwabError.invalidURL }
        
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        // Add authentication
        let authMessage = ["type": "auth", "token": AppConfig.apiKey]
        try await webSocket?.send(.string(JSONEncoder().encode(authMessage).base64EncodedString()))
        
        // Start receiving messages
        receiveMessages()
        isConnected = true
    }
    
    private func receiveMessages() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = Data(base64Encoded: text),
                       let quote = try? JSONDecoder().decode(Quote.self, from: data) {
                        self.quoteSubjects[quote.symbol]?.send(quote)
                        // Also cache the quote for non-streaming access
                        MarketDataService.shared.updateQuoteCache(quote)
                    }
                default:
                    break
                }
                // Continue receiving
                self.receiveMessages()
                
            case .failure(let error):
                print("WebSocket error: \(error)")
                self.reconnect()
            }
        }
    }
    
    private func reconnect() {
        isConnected = false
        // Try to reconnect after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Task {
                try? await self.streamQuotes(symbols: Array(self.quoteSubjects.keys))
            }
        }
    }
    
    // Subscribe to real-time quotes for a symbol
    func subscribeToQuotes(symbol: String) -> AnyPublisher<Quote, Never> {
        if quoteSubjects[symbol] == nil {
            quoteSubjects[symbol] = PassthroughSubject<Quote, Never>()
            // Add symbol to streaming if we're already connected
            if isConnected {
                Task {
                    try? await streamQuotes(symbols: [symbol])
                }
            }
        }
        return quoteSubjects[symbol]?.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }
    
    // Add proper error handling
    enum SchwabError: Error {
        case invalidResponse
        case authenticationFailed
        case rateLimitExceeded
        case invalidURL
    }
    
    private func handleResponse<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try decoder.decode(APIResponse<T>.self, from: data)
            return response.data
        } catch {
            print("Decode error: \(error)")
            throw SchwabError.invalidResponse
        }
    }
    
    // Missing method for OAuth flow
    func exchangeCodeForToken(_ code: String) async throws -> String {
        let endpoint = "https://api.schwab.com/oauth/token"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=authorization_code&code=\(code)&client_id=\(AppConfig.clientId)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        struct TokenResponse: Codable {
            let access_token: String
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.access_token
    }
    
    // Missing method for streaming connection
    func connectToStream() async throws {
        try await streamQuotes([])
    }

    // MARK: - Options Chain Data
    /// Fetch options chain for VXX (for put/call entries)
    func fetchOptionsChain(symbol: String, daysToExpiration: Int = 4) async throws -> OptionsChain {
        let endpoint = "\(baseURL)/markets/options/\(symbol)?daysToExpiration=\(daysToExpiration)"
        let request = authenticatedRequest(for: endpoint)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 429 {
            throw SchwabError.rateLimitExceeded
        }

        return try handleResponse(data)
    }

    /// Fetch implied volatility for a symbol
    func fetchImpliedVolatility(symbol: String) async throws -> ImpliedVolatilityData {
        let endpoint = "\(baseURL)/markets/\(symbol)/iv"
        let request = authenticatedRequest(for: endpoint)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 429 {
            throw SchwabError.rateLimitExceeded
        }

        return try handleResponse(data)
    }

    /// Get VXX and VIX data for ratio monitoring
    func fetchVXXVIXData() async throws -> (vxx: Quote, vix: Quote) {
        async let vxxQuote = fetchQuote("VXX")
        async let vixQuote = fetchQuote("VIX")

        return try await (vxx: vxxQuote, vix: vixQuote)
    }

    /// Fetch historical candles for pattern recognition and indicators
    func fetchHistoricalCandles(symbol: String, period: CandlePeriod = .fiveMinutes, days: Int = 5) async throws -> [Candle] {
        let endpoint = "\(baseURL)/markets/\(symbol)/candles?period=\(period.rawValue)&days=\(days)"
        let request = authenticatedRequest(for: endpoint)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 429 {
            throw SchwabError.rateLimitExceeded
        }

        let response: CandlesResponse = try handleResponse(data)
        return response.candles
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