import Foundation
import Combine

// MARK: - EDUCATIONAL MODE SERVICE
// This app is an educational tool. All data must be entered manually.
// Connect to your own trading platform (ThinkOrSwim, Schwab, etc.) for live execution.

class SchwabService: ObservableObject {
    static let shared = SchwabService()
    @Published var isConnected = false

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func authorizationURL(state: String = UUID().uuidString, redirectURI: String = AppConfig.Schwab.loopbackCallbackURL) throws -> URL {
        let appKey = AppConfig.Schwab.appKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appKey.isEmpty else {
            throw SchwabError.missingDeveloperCredentials
        }

        guard var components = URLComponents(string: AppConfig.Schwab.oauthAuthorizeURL) else {
            throw SchwabError.badURL(AppConfig.Schwab.oauthAuthorizeURL)
        }
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: appKey),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "api"),
            URLQueryItem(name: "state", value: state)
        ]
        guard let url = components.url else {
            throw SchwabError.badURL(AppConfig.Schwab.oauthAuthorizeURL)
        }
        return url
    }

    func fetchQuote(_ symbol: String) async throws -> Quote {
        let schwabSymbol = Self.schwabSymbol(for: symbol)
        async let payload = fetchQuotePayload(schwabSymbol: schwabSymbol)
        async let recentCandles = fetchRecentCandles(schwabSymbol: schwabSymbol)

        let quotePayload = try await payload
        let candles = (try? await recentCandles) ?? []
        let vwap = computeVWAP(candles: candles)

        return Quote(
            symbol: symbol == "^VIX" ? "VIX" : symbol,
            price: quotePayload.price,
            volume: quotePayload.volume,
            vwap: vwap > 0 ? vwap : quotePayload.price,
            previousClose: quotePayload.previousClose > 0 ? quotePayload.previousClose : quotePayload.price,
            timestamp: quotePayload.timestamp,
            recentCandles: candles
        )
    }

    /// Educational mode - No live order execution
    func placeOrder(order: Order) async throws -> OrderResponse {
        throw SchwabError.educationalModeOnly 
    }

    /// Starts a REST-backed quote pass. Schwab's websocket streamer still needs
    /// a separate command/login implementation, but this verifies auth + quotes.
    func streamQuotes(symbols: [String]) async throws {
        for symbol in symbols {
            _ = try await fetchQuote(symbol)
        }
        await MainActor.run {
            isConnected = true
        }
    }

    func subscribeToQuotes(symbol: String) -> AnyPublisher<Quote, Never> {
        let subject = PassthroughSubject<Quote, Never>()
        Task { [weak self] in
            while !Task.isCancelled {
                if let quote = try? await self?.fetchQuote(symbol) {
                    subject.send(quote)
                }
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
        return subject.eraseToAnyPublisher()
    }

    @discardableResult
    func exchangeCodeForToken(_ code: String, redirectURI: String = AppConfig.Schwab.loopbackCallbackURL) async throws -> String {
        let token = try await requestTokens(
            grantItems: [
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": redirectURI
            ]
        )
        store(tokenResponse: token)
        await MainActor.run {
            isConnected = true
        }
        return token.accessToken
    }

    @discardableResult
    func refreshAccessToken(force: Bool = false) async throws -> String {
        let accessToken = AppConfig.Schwab.accessToken
        let needsRefresh: Bool
        if force {
            needsRefresh = true
        } else if accessToken.isEmpty {
            needsRefresh = true
        } else if let expiresAt = AppConfig.Schwab.accessTokenExpiresAt {
            needsRefresh = expiresAt.timeIntervalSinceNow < 90
        } else {
            needsRefresh = false
        }

        guard needsRefresh else { return accessToken }

        let refreshToken = AppConfig.Schwab.refreshToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !refreshToken.isEmpty else {
            throw SchwabError.missingOAuthTokens
        }

        let token = try await requestTokens(
            grantItems: [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken
            ]
        )
        store(tokenResponse: token)
        await MainActor.run {
            isConnected = true
        }
        return token.accessToken
    }

    func authorizationCode(from text: String) -> String? {
        Self.authorizationCode(from: text)
    }

    static func authorizationCode(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
           !code.isEmpty {
            return code
        }

        if let rawCode = queryValue(named: "code", in: trimmed) {
            return rawCode
        }

        if !trimmed.contains(" "), !trimmed.contains("="), trimmed.count > 12 {
            return trimmed
        }

        return nil
    }

    func vwap(_ symbol: String) async throws -> Double {
        let candles = try await fetchRecentCandles(schwabSymbol: Self.schwabSymbol(for: symbol))
        let vwap = computeVWAP(candles: candles)
        guard vwap > 0 else {
            throw SchwabError.invalidResponse("Schwab returned no intraday candles for \(symbol).")
        }
        return vwap
    }

    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double {
        let candles = try await fetchDailyCandles(schwabSymbol: Self.schwabSymbol(for: symbol))
        guard candles.count >= 2 else {
            throw SchwabError.invalidResponse("Schwab returned too few daily candles for \(symbol).")
        }
        let history = Array(candles.dropLast())
        let averageWindow = Array(history.suffix(period))
        let averageVolume = Double(averageWindow.reduce(0) { $0 + $1.volume }) / Double(max(averageWindow.count, 1))
        guard averageVolume > 0, let today = candles.last else {
            throw SchwabError.invalidResponse("Schwab returned no usable volume history for \(symbol).")
        }
        return Double(today.volume) / averageVolume
    }

    // MARK: - Error Handling
    enum SchwabError: LocalizedError {
        case educationalModeOnly
        case missingDeveloperCredentials
        case missingOAuthTokens
        case badURL(String)
        case httpStatus(Int, String)
        case invalidResponse(String)

        var errorDescription: String? {
            switch self {
            case .educationalModeOnly:
                return "This app is educational only. Execute trades on your own platform (ThinkOrSwim, Schwab, TD Ameritrade, etc.)"
            case .missingDeveloperCredentials:
                return "Add your Schwab app key and app secret first."
            case .missingOAuthTokens:
                return "Schwab OAuth is not connected yet."
            case .badURL(let value):
                return "Could not build Schwab URL: \(value)"
            case .httpStatus(let status, let body):
                return "Schwab returned HTTP \(status). \(body)"
            case .invalidResponse(let detail):
                return "Schwab response could not be read. \(detail)"
            }
        }
    }

    // MARK: - Live Schwab REST

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let tokenType: String?
        let scope: String?
        let expiresIn: TimeInterval?

        private enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case tokenType = "token_type"
            case scope
            case expiresIn = "expires_in"
        }
    }

    private struct QuotePayload {
        let price: Double
        let volume: Int
        let previousClose: Double
        let timestamp: Date
    }

    private func requestTokens(grantItems: [String: String]) async throws -> TokenResponse {
        let appKey = AppConfig.Schwab.appKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let appSecret = AppConfig.Schwab.appSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appKey.isEmpty, !appSecret.isEmpty else {
            throw SchwabError.missingDeveloperCredentials
        }
        guard let url = URL(string: AppConfig.Schwab.oauthTokenURL) else {
            throw SchwabError.badURL(AppConfig.Schwab.oauthTokenURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let basic = Data("\(appKey):\(appSecret)".utf8).base64EncodedString()
        request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        request.httpBody = Self.formEncoded(grantItems)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw SchwabError.invalidResponse("Token JSON did not match the expected OAuth response.")
        }
    }

    private func store(tokenResponse: TokenResponse) {
        AppConfig.Schwab.accessToken = tokenResponse.accessToken
        if let refreshToken = tokenResponse.refreshToken, !refreshToken.isEmpty {
            AppConfig.Schwab.refreshToken = refreshToken
        }
        AppConfig.Schwab.accessTokenExpiresAt = Date().addingTimeInterval(tokenResponse.expiresIn ?? 1_800)
        AppConfig.Schwab.oauthTokensStored = AppConfig.Schwab.accessTokenStored && AppConfig.Schwab.refreshTokenStored
        AppConfig.apiKey = tokenResponse.accessToken
    }

    private func fetchQuotePayload(schwabSymbol: String) async throws -> QuotePayload {
        let data = try await authorizedMarketData(
            path: "quotes",
            queryItems: [
                URLQueryItem(name: "symbols", value: schwabSymbol),
                URLQueryItem(name: "fields", value: "quote,reference,regular")
            ]
        )
        let object = try Self.jsonObject(from: data)
        guard let root = object as? [String: Any],
              let quoteRoot = Self.quoteRoot(in: root, symbol: schwabSymbol) else {
            throw SchwabError.invalidResponse("No quote object found for \(schwabSymbol).")
        }

        let quote = quoteRoot["quote"] as? [String: Any] ?? [:]
        let regular = quoteRoot["regular"] as? [String: Any] ?? [:]
        let reference = quoteRoot["reference"] as? [String: Any] ?? [:]
        let dictionaries = [quote, regular, reference, quoteRoot]

        guard let price = Self.doubleValue(
            in: dictionaries,
            keys: ["lastPrice", "mark", "regularMarketLastPrice", "bidPrice", "askPrice"]
        ) else {
            throw SchwabError.invalidResponse("No last price field found for \(schwabSymbol).")
        }

        let volume = Self.intValue(
            in: dictionaries,
            keys: ["totalVolume", "volume", "regularMarketLastSize"]
        ) ?? 0
        let previousClose = Self.doubleValue(
            in: dictionaries,
            keys: ["closePrice", "previousClose", "regularMarketPreviousClose"]
        ) ?? price
        let timestamp = Self.dateValue(
            in: dictionaries,
            keys: ["tradeTime", "quoteTime", "regularMarketTradeTime"]
        ) ?? Date()

        return QuotePayload(
            price: price,
            volume: volume,
            previousClose: previousClose,
            timestamp: timestamp
        )
    }

    private func fetchRecentCandles(schwabSymbol: String) async throws -> [Candle] {
        try await fetchCandles(
            schwabSymbol: schwabSymbol,
            periodType: "day",
            period: 1,
            frequencyType: "minute",
            frequency: 1
        )
    }

    private func fetchDailyCandles(schwabSymbol: String) async throws -> [Candle] {
        try await fetchCandles(
            schwabSymbol: schwabSymbol,
            periodType: "month",
            period: 1,
            frequencyType: "daily",
            frequency: 1
        )
    }

    private func fetchCandles(
        schwabSymbol: String,
        periodType: String,
        period: Int,
        frequencyType: String,
        frequency: Int
    ) async throws -> [Candle] {
        let data = try await authorizedMarketData(
            path: "pricehistory",
            queryItems: [
                URLQueryItem(name: "symbol", value: schwabSymbol),
                URLQueryItem(name: "periodType", value: periodType),
                URLQueryItem(name: "period", value: "\(period)"),
                URLQueryItem(name: "frequencyType", value: frequencyType),
                URLQueryItem(name: "frequency", value: "\(frequency)"),
                URLQueryItem(name: "needExtendedHoursData", value: "false")
            ]
        )
        let object = try Self.jsonObject(from: data)
        guard let root = object as? [String: Any],
              let candleObjects = root["candles"] as? [[String: Any]] else {
            return []
        }

        return candleObjects.compactMap { raw in
            guard let open = Self.doubleValue(raw["open"]),
                  let high = Self.doubleValue(raw["high"]),
                  let low = Self.doubleValue(raw["low"]),
                  let close = Self.doubleValue(raw["close"]) else {
                return nil
            }
            let volume = Self.intValue(raw["volume"]) ?? 0
            let timestamp = Self.dateValue(raw["datetime"]) ?? Date()
            return Candle(
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume,
                timestamp: timestamp
            )
        }
    }

    private func authorizedMarketData(path: String, queryItems: [URLQueryItem], retriedAfterRefresh: Bool = false) async throws -> Data {
        guard let baseURL = URL(string: AppConfig.Schwab.marketDataBaseURL) else {
            throw SchwabError.badURL(AppConfig.Schwab.marketDataBaseURL)
        }
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        guard let url = components?.url else {
            throw SchwabError.badURL(path)
        }

        let token = try await refreshAccessToken()
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 401, !retriedAfterRefresh {
            _ = try await refreshAccessToken(force: true)
            return try await authorizedMarketData(path: path, queryItems: queryItems, retriedAfterRefresh: true)
        }

        try Self.validate(response: response, data: data)
        return data
    }

    private func computeVWAP(candles: [Candle]) -> Double {
        var volumePriceSum = 0.0
        var totalVolume = 0.0
        for candle in candles {
            let volume = Double(candle.volume)
            guard volume > 0 else { continue }
            let typicalPrice = (candle.high + candle.low + candle.close) / 3
            volumePriceSum += typicalPrice * volume
            totalVolume += volume
        }
        guard totalVolume > 0 else { return 0 }
        return volumePriceSum / totalVolume
    }

    private static func schwabSymbol(for symbol: String) -> String {
        switch symbol.uppercased() {
        case "^VIX", "VIX":
            return "$VIX.X"
        default:
            return symbol.uppercased()
        }
    }

    private static func formEncoded(_ values: [String: String]) -> Data {
        var components = URLComponents()
        components.queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SchwabError.invalidResponse("Missing HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SchwabError.httpStatus(http.statusCode, bodyPreview(data))
        }
    }

    private static func bodyPreview(_ data: Data) -> String {
        let text = String(data: data, encoding: .utf8) ?? ""
        let clean = text.replacingOccurrences(of: "\n", with: " ")
        return String(clean.prefix(240))
    }

    private static func jsonObject(from data: Data) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            throw SchwabError.invalidResponse("JSON decoding failed.")
        }
    }

    private static func quoteRoot(in root: [String: Any], symbol: String) -> [String: Any]? {
        if let exact = root[symbol] as? [String: Any] {
            return exact
        }
        if let caseInsensitive = root.first(where: { $0.key.uppercased() == symbol.uppercased() })?.value as? [String: Any] {
            return caseInsensitive
        }
        return root.values.compactMap { $0 as? [String: Any] }.first
    }

    private static func doubleValue(in dictionaries: [[String: Any]], keys: [String]) -> Double? {
        for dictionary in dictionaries {
            for key in keys {
                if let value = doubleValue(dictionary[key]) {
                    return value
                }
            }
        }
        return nil
    }

    private static func intValue(in dictionaries: [[String: Any]], keys: [String]) -> Int? {
        for dictionary in dictionaries {
            for key in keys {
                if let value = intValue(dictionary[key]) {
                    return value
                }
            }
        }
        return nil
    }

    private static func dateValue(in dictionaries: [[String: Any]], keys: [String]) -> Date? {
        for dictionary in dictionaries {
            for key in keys {
                if let value = dateValue(dictionary[key]) {
                    return value
                }
            }
        }
        return nil
    }

    private static func doubleValue(_ raw: Any?) -> Double? {
        if let value = raw as? Double { return value }
        if let value = raw as? Float { return Double(value) }
        if let value = raw as? Int { return Double(value) }
        if let value = raw as? Int64 { return Double(value) }
        if let value = raw as? String { return Double(value) }
        return nil
    }

    private static func intValue(_ raw: Any?) -> Int? {
        if let value = raw as? Int { return value }
        if let value = raw as? Int64 { return Int(value) }
        if let value = raw as? Double { return Int(value) }
        if let value = raw as? String { return Int(value) }
        return nil
    }

    private static func dateValue(_ raw: Any?) -> Date? {
        guard let value = doubleValue(raw), value > 0 else { return nil }
        let seconds = value > 10_000_000_000 ? value / 1_000 : value
        return Date(timeIntervalSince1970: seconds)
    }

    private static func queryValue(named name: String, in text: String) -> String? {
        guard let range = text.range(of: "\(name)=") else { return nil }
        let tail = text[range.upperBound...]
        let rawValue = tail.split(separator: "&", maxSplits: 1).first.map(String.init) ?? String(tail)
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.removingPercentEncoding ?? trimmed
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
