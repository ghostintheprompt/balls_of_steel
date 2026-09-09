import Foundation
import Combine

// MARK: - SCHWAB MARKET-DATA SERVICE
// Schwab OAuth is used for quote/candle data only. Steel never sends orders,
// reads balances, or manages brokerage positions.

class SchwabService: ObservableObject {
    static let shared = SchwabService()
    @Published var isConnected = false

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func authorizationURL(redirectURI: String = AppConfig.Schwab.oauthCallbackURL) throws -> URL {
        let appKey = AppConfig.Schwab.appKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let redirectURI = AppConfig.Schwab.sanitizedCallbackURL(redirectURI)
        guard !appKey.isEmpty else {
            throw SchwabError.missingDeveloperCredentials
        }

        guard var components = URLComponents(string: AppConfig.Schwab.oauthAuthorizeURL) else {
            throw SchwabError.badURL(AppConfig.Schwab.oauthAuthorizeURL)
        }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: appKey),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
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
            recentCandles: candles,
            bid: quotePayload.bid,
            ask: quotePayload.ask
        )
    }

    /// Market-data-only boundary. Manual execution stays outside Steel.
    func placeOrder(order: Order) async throws -> OrderResponse {
        throw SchwabError.marketDataOnly
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
                    // Deliver on the main actor: downstream subscribers
                    // (MarketDataService, SignalScanner, ExitSignalService)
                    // are all @MainActor and mutate shared dictionaries in
                    // their .sink closures. Combine delivers .send()
                    // synchronously on whatever thread calls it, so without
                    // this hop those closures ran on this background Task's
                    // thread, racing concurrent polling loops for the same
                    // symbol and corrupting the shared dictionaries (the
                    // 2026-09-08 SIGSEGV / uncaught-NSException crash in
                    // MarketDataService.handleQuoteUpdate).
                    await MainActor.run {
                        subject.send(quote)
                    }
                }
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
        return subject.eraseToAnyPublisher()
    }

    @discardableResult
    func exchangeCodeForToken(_ code: String, redirectURI: String = AppConfig.Schwab.oauthCallbackURL) async throws -> String {
        let redirectURI = AppConfig.Schwab.sanitizedCallbackURL(redirectURI)
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

    /// Real Schwab options chain, scoped to roughly the DTE window
    /// OptionSelector actually wants (its own dteMin/dteMax bounds), not the
    /// full chain. UNVERIFIED against live Schwab traffic as of writing --
    /// the callExpDateMap/putExpDateMap shape is the well-documented
    /// TD Ameritrade-heritage chains format Schwab inherited, but per this
    /// project's own hard-earned rule (never trust a Schwab shape without
    /// seeing the real response), the parser below fails loudly with the
    /// raw JSON attached rather than silently guessing wrong on a real
    /// trade suggestion -- exactly the $VIX.X mistake, but for something
    /// that would put a specific contract in front of the user.
    func fetchOptionsChain(_ symbol: String) async throws -> OptionsChain {
        let schwabSymbol = Self.schwabSymbol(for: symbol)
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        let fromDate = calendar.date(byAdding: .day, value: max(OptionSelector.dteMin - 1, 0), to: today) ?? today
        let toDate = calendar.date(byAdding: .day, value: OptionSelector.dteMax + 2, to: today) ?? today
        let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = TimeZone(identifier: "America/New_York")
            return f
        }()

        let data = try await authorizedMarketData(
            path: "chains",
            queryItems: [
                URLQueryItem(name: "symbol", value: schwabSymbol),
                URLQueryItem(name: "contractType", value: "ALL"),
                URLQueryItem(name: "strikeCount", value: "20"),
                URLQueryItem(name: "range", value: "ALL"),
                URLQueryItem(name: "fromDate", value: formatter.string(from: fromDate)),
                URLQueryItem(name: "toDate", value: formatter.string(from: toDate))
            ]
        )

        let object = try Self.jsonObject(from: data)
        guard let root = object as? [String: Any] else {
            throw SchwabError.invalidResponse("Chain response was not a JSON object.")
        }
        guard let callMap = root["callExpDateMap"] as? [String: Any],
              let putMap = root["putExpDateMap"] as? [String: Any] else {
            throw SchwabError.invalidResponse("Chain response did not have the expected shape. Schwab response: \(Self.jsonPreview(root))")
        }

        let underlyingPrice = Self.doubleValue(in: [root], keys: ["underlyingPrice", "last", "mark"]) ?? 0
        let calls = Self.parseExpDateMap(callMap, symbol: schwabSymbol, type: .call)
        let puts = Self.parseExpDateMap(putMap, symbol: schwabSymbol, type: .put)

        guard !calls.isEmpty || !puts.isEmpty else {
            throw SchwabError.invalidResponse("Chain parsed but contained zero contracts. Schwab response: \(Self.jsonPreview(root))")
        }

        return OptionsChain(symbol: symbol, calls: calls, puts: puts, underlyingPrice: underlyingPrice)
    }

    private static func parseExpDateMap(_ map: [String: Any], symbol: String, type: OptionType) -> [OptionContract] {
        var contracts: [OptionContract] = []
        for (expKey, strikesValue) in map {
            // Schwab keys this "yyyy-MM-dd:DTE" -- take the date portion.
            let dateString = expKey.split(separator: ":").first.map(String.init) ?? expKey
            let expFormatter = DateFormatter()
            expFormatter.dateFormat = "yyyy-MM-dd"
            expFormatter.timeZone = TimeZone(identifier: "America/New_York")
            guard let expiration = expFormatter.date(from: dateString),
                  let strikesMap = strikesValue as? [String: Any] else { continue }

            for (_, contractsValue) in strikesMap {
                guard let contractArray = contractsValue as? [[String: Any]] else { continue }
                for raw in contractArray {
                    guard let strike = doubleValue(raw["strikePrice"]) else { continue }
                    let bid = doubleValue(raw["bid"]) ?? 0
                    let ask = doubleValue(raw["ask"]) ?? 0
                    let last = doubleValue(raw["last"]) ?? 0
                    let volume = intValue(raw["totalVolume"]) ?? 0
                    let openInterest = intValue(raw["openInterest"]) ?? 0
                    let delta = doubleValue(raw["delta"]) ?? 0
                    let gamma = doubleValue(raw["gamma"]) ?? 0
                    let theta = doubleValue(raw["theta"]) ?? 0
                    let vega = doubleValue(raw["vega"]) ?? 0
                    let iv = doubleValue(raw["volatility"]) ?? 0

                    contracts.append(OptionContract(
                        symbol: symbol,
                        strike: strike,
                        expiration: expiration,
                        type: type,
                        bid: bid,
                        ask: ask,
                        last: last,
                        volume: volume,
                        openInterest: openInterest,
                        delta: delta,
                        gamma: gamma,
                        theta: theta,
                        vega: vega,
                        impliedVolatility: iv
                    ))
                }
            }
        }
        return contracts
    }

    // MARK: - Error Handling
    enum SchwabError: LocalizedError {
        case marketDataOnly
        case missingDeveloperCredentials
        case missingOAuthTokens
        case badURL(String)
        case httpStatus(Int, String)
        case invalidResponse(String)

        var errorDescription: String? {
            switch self {
            case .marketDataOnly:
                return "Steel only uses Schwab for quote data. Place trades manually in your brokerage app."
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

    static func tokenExchangeFailureMessage(
        _ error: Error,
        redirectURI: String = AppConfig.Schwab.oauthCallbackURL
    ) -> String {
        guard case let SchwabError.httpStatus(status, body) = error else {
            return error.localizedDescription
        }

        let normalizedBody = body.lowercased()
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        // Schwab's literal response body is the only thing that actually
        // tells you which of several similar-looking causes this is — always
        // show it verbatim instead of guessing a category and hiding the
        // real text behind a canned explanation.
        let rawSuffix = trimmedBody.isEmpty ? "" : " Schwab said: \(trimmedBody)"

        if normalizedBody.contains("invalid_client") || normalizedBody.contains("unauthorized") {
            return "Schwab rejected the App Key or App Secret (HTTP \(status)). Replace both with the exact values from the Schwab Developer Portal, save them, then start a fresh sign-in.\(rawSuffix)"
        }
        if normalizedBody.contains("invalid_grant") {
            return "Schwab rejected the one-time authorization code (HTTP \(status)). Confirm \(redirectURI) is registered exactly, then start a fresh sign-in; callback codes cannot be reused.\(rawSuffix)"
        }
        if status == 401 {
            return "Schwab rejected the token request (HTTP 401). Replace the saved App Key and App Secret with the exact portal values, confirm the app is Ready, then start a fresh sign-in.\(rawSuffix)"
        }
        return "\(error.localizedDescription)\(rawSuffix)"
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
        let bid: Double
        let ask: Double
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
            // Show Schwab's actual quote shape instead of just naming the
            // fields we looked for and didn't find — index symbols (e.g.
            // $VIX.X) use a different quote schema than equities/ETFs, and
            // guessing field names blind is how this bug hid for months.
            throw SchwabError.invalidResponse("No last price field found for \(schwabSymbol). Schwab quote object: \(Self.jsonPreview(quoteRoot))")
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
        let bid = Self.doubleValue(in: dictionaries, keys: ["bidPrice", "bid"]) ?? 0
        let ask = Self.doubleValue(in: dictionaries, keys: ["askPrice", "ask"]) ?? 0

        return QuotePayload(
            price: price,
            volume: volume,
            previousClose: previousClose,
            timestamp: timestamp,
            bid: bid,
            ask: ask
        )
    }

    // Confirmed live 2026-09-08 via raw candle diagnostics: `periodType=day,
    // period=1` returns the most recent COMPLETE trading day, not today's
    // in-progress session -- on a day following a market holiday (Monday
    // 9/7 was Labor Day) that resolved to last Friday 9/4's closing candle,
    // frozen there for the rest of the session because there simply were no
    // newer candles in the response, not because of any cache. Pinning
    // startDate/endDate to today's actual ET calendar day (the documented
    // TDA/Schwab pricehistory alternative to period/periodType) and then
    // defensively filtering to today's date client-side, in case Schwab
    // ever pads the response with a stray adjacent-day candle.
    private func fetchRecentCandles(schwabSymbol: String) async throws -> [Candle] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let data = try await authorizedMarketData(
            path: "pricehistory",
            queryItems: [
                URLQueryItem(name: "symbol", value: schwabSymbol),
                URLQueryItem(name: "frequencyType", value: "minute"),
                URLQueryItem(name: "frequency", value: "1"),
                URLQueryItem(name: "startDate", value: "\(Int(startOfDay.timeIntervalSince1970 * 1000))"),
                URLQueryItem(name: "endDate", value: "\(Int(now.timeIntervalSince1970 * 1000))"),
                URLQueryItem(name: "needExtendedHoursData", value: "false")
            ]
        )
        let object = try Self.jsonObject(from: data)
        guard let root = object as? [String: Any],
              let candleObjects = root["candles"] as? [[String: Any]] else {
            return []
        }

        let candles: [Candle] = candleObjects.compactMap { raw in
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

        return candles.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
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
        // Confirmed live 2026-09-08: pricehistory responses were coming back
        // bit-identical across polls minutes apart while quotes visibly moved
        // -- URLSession's default cache (.useProtocolCachePolicy against
        // URLCache.shared) was serving Schwab's own cached response instead
        // of hitting the network. Every call through here backs a "live"
        // feed; none of it should ever be allowed to come from a local cache.
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

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
            // Verified live 2026-09-07: Schwab's quotes endpoint returns
            // invalidSymbols for "$VIX.X" (the old thinkorswim-desktop
            // convention this used to guess). Trying the plain $-prefixed
            // form Schwab's REST API actually documents for indices.
            return "$VIX"
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

    private static func jsonPreview(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object) else {
            return "\(object)"
        }
        return bodyPreview(data)
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
