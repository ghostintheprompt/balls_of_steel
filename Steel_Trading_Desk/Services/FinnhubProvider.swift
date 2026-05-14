import Foundation

// MARK: - Finnhub Provider (Phase 6, v1.0 default)
//
// Free tier: 60 req/min, real-time US equities via REST + WebSocket.
// Sign up at https://finnhub.io/dashboard to get a key, then paste it into
// Settings → Data Source. Key is stored in the Keychain via KeychainService.
//
// REST: https://finnhub.io/api/v1
//   GET /quote?symbol=VXX&token=KEY                 → current price + previous close
//   GET /stock/candle?symbol=VXX&resolution=1&...   → intraday OHLCV
// WebSocket: wss://ws.finnhub.io?token=KEY
//   send {"type":"subscribe","symbol":"VXX"} per symbol; receive trade ticks.

struct FinnhubProvider: MarketDataProvider {
    let id: MarketDataProviderID = .finnhub
    let displayName = "Finnhub (free tier)"
    let requiresApiKey = true
    let apiKeyHelpURL = URL(string: "https://finnhub.io/dashboard")
    let deliversRealtime = true
    let setupNote = "Free tier: 60 req/min, real-time US equities. Sign up at finnhub.io and paste the key in Settings."

    static let keychainKey = "finnhub.apiKey"
    private static let restBase = URL(string: "https://finnhub.io/api/v1")!
    private static let wsBase = "wss://ws.finnhub.io"

    private var apiKey: String? { KeychainService.load(key: Self.keychainKey) }
    private let session: URLSession = .shared

    // MARK: REST

    func quote(_ symbol: String) async throws -> Quote {
        guard let key = apiKey, !key.isEmpty else {
            throw MarketDataProviderError.notConfigured("Add a Finnhub API key in Settings → Data Source.")
        }
        async let snapshot = fetchQuoteSnapshot(symbol: symbol, key: key)
        async let candles = fetchTodayCandles(symbol: symbol, key: key)
        let (snap, todayCandles) = try await (snapshot, candles)

        let volume = todayCandles.reduce(0) { $0 + $1.volume }
        let vwap = computeVWAP(candles: todayCandles)
        return Quote(
            symbol: symbol,
            price: snap.current,
            volume: volume,
            vwap: vwap > 0 ? vwap : snap.current,
            previousClose: snap.previousClose,
            timestamp: snap.timestamp,
            recentCandles: todayCandles
        )
    }

    func vwap(_ symbol: String) async throws -> Double {
        guard let key = apiKey, !key.isEmpty else {
            throw MarketDataProviderError.notConfigured("Add a Finnhub API key in Settings → Data Source.")
        }
        let candles = try await fetchTodayCandles(symbol: symbol, key: key)
        let v = computeVWAP(candles: candles)
        if v > 0 { return v }
        throw MarketDataProviderError.network("No intraday candles returned to compute VWAP.")
    }

    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double {
        guard let key = apiKey, !key.isEmpty else {
            throw MarketDataProviderError.notConfigured("Add a Finnhub API key in Settings → Data Source.")
        }
        let now = Date()
        let from = now.addingTimeInterval(-Double(period + 2) * 86_400)
        let dailyCandles = try await fetchCandles(
            symbol: symbol,
            resolution: "D",
            from: from,
            to: now,
            key: key
        )
        guard dailyCandles.count >= 2 else {
            throw MarketDataProviderError.network("Need at least 2 daily candles for an average.")
        }
        let history = Array(dailyCandles.dropLast()) // exclude today's partial bar
        let avgVolume = Double(history.suffix(period).reduce(0) { $0 + $1.volume }) / Double(min(period, history.count))
        guard avgVolume > 0, let today = dailyCandles.last else {
            throw MarketDataProviderError.network("Average volume zero; symbol may be illiquid.")
        }
        return Double(today.volume) / avgVolume
    }

    // MARK: WebSocket

    func subscribe(_ symbols: [String]) -> AsyncStream<Quote> {
        AsyncStream { continuation in
            guard let key = apiKey, !key.isEmpty else {
                continuation.finish()
                return
            }
            guard let url = URL(string: "\(Self.wsBase)?token=\(key)") else {
                continuation.finish()
                return
            }

            let task = session.webSocketTask(with: url)
            task.resume()

            // Send subscribe messages for each symbol.
            for symbol in symbols {
                let payload = #"{"type":"subscribe","symbol":"\#(symbol)"}"#
                task.send(.string(payload)) { _ in }
            }

            // Listen loop runs in a Swift Task; emits Quote per trade tick.
            let listener = Task {
                await Self.listen(task: task, continuation: continuation)
            }

            continuation.onTermination = { _ in
                let payload = symbols.map { #"{"type":"unsubscribe","symbol":"\#($0)"}"# }
                for p in payload {
                    task.send(.string(p)) { _ in }
                }
                task.cancel(with: .normalClosure, reason: nil)
                listener.cancel()
            }
        }
    }

    private static func listen(task: URLSessionWebSocketTask, continuation: AsyncStream<Quote>.Continuation) async {
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                let text: String
                switch message {
                case .string(let s): text = s
                case .data(let d):   text = String(data: d, encoding: .utf8) ?? ""
                @unknown default:    continue
                }
                if let trades = parseTradeFrame(text) {
                    for t in trades {
                        let q = Quote(
                            symbol: t.symbol,
                            price: t.price,
                            volume: t.volume,
                            vwap: t.price,
                            previousClose: 0,
                            timestamp: t.timestamp,
                            recentCandles: []
                        )
                        continuation.yield(q)
                    }
                }
            } catch {
                continuation.finish()
                return
            }
        }
        continuation.finish()
    }

    // MARK: REST helpers

    private struct QuoteSnapshot {
        let current: Double
        let previousClose: Double
        let timestamp: Date
    }

    private func fetchQuoteSnapshot(symbol: String, key: String) async throws -> QuoteSnapshot {
        var components = URLComponents(url: Self.restBase.appendingPathComponent("quote"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "token", value: key)
        ]
        guard let url = components.url else {
            throw MarketDataProviderError.network("Bad URL for /quote")
        }
        let (data, response) = try await session.data(from: url)
        try Self.validate(response: response, data: data)

        struct Response: Decodable {
            let c: Double; let pc: Double; let t: Int
        }
        let r = try JSONDecoder().decode(Response.self, from: data)
        if r.c == 0 && r.pc == 0 {
            throw MarketDataProviderError.unsupportedSymbol(symbol)
        }
        return QuoteSnapshot(
            current: r.c,
            previousClose: r.pc,
            timestamp: Date(timeIntervalSince1970: TimeInterval(r.t))
        )
    }

    private func fetchTodayCandles(symbol: String, key: String) async throws -> [Candle] {
        let now = Date()
        let cal = Calendar(identifier: .gregorian)
        let easternMidnight = Self.todayMarketOpen(now: now, cal: cal)
        return try await fetchCandles(
            symbol: symbol,
            resolution: "1",
            from: easternMidnight,
            to: now,
            key: key
        )
    }

    private func fetchCandles(symbol: String, resolution: String, from: Date, to: Date, key: String) async throws -> [Candle] {
        var components = URLComponents(url: Self.restBase.appendingPathComponent("stock/candle"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "resolution", value: resolution),
            URLQueryItem(name: "from", value: String(Int(from.timeIntervalSince1970))),
            URLQueryItem(name: "to", value: String(Int(to.timeIntervalSince1970))),
            URLQueryItem(name: "token", value: key)
        ]
        guard let url = components.url else {
            throw MarketDataProviderError.network("Bad URL for /stock/candle")
        }
        let (data, response) = try await session.data(from: url)
        try Self.validate(response: response, data: data)

        struct Response: Decodable {
            let s: String                // "ok" or "no_data"
            let c: [Double]?; let h: [Double]?; let l: [Double]?
            let o: [Double]?; let v: [Double]?; let t: [Int]?
        }
        let r = try JSONDecoder().decode(Response.self, from: data)
        guard r.s == "ok",
              let opens = r.o, let highs = r.h, let lows = r.l,
              let closes = r.c, let vols = r.v, let times = r.t,
              opens.count == times.count else {
            return []
        }
        return zip(0..<times.count, times).map { i, ts in
            Candle(
                open: opens[i],
                high: highs[i],
                low: lows[i],
                close: closes[i],
                volume: Int(vols[i]),
                timestamp: Date(timeIntervalSince1970: TimeInterval(ts))
            )
        }
    }

    private func computeVWAP(candles: [Candle]) -> Double {
        var num: Double = 0
        var den: Double = 0
        for c in candles {
            let typical = (c.high + c.low + c.close) / 3
            num += typical * Double(c.volume)
            den += Double(c.volume)
        }
        return den > 0 ? num / den : 0
    }

    private static func todayMarketOpen(now: Date, cal: Calendar) -> Date {
        var c = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: now)
        c.hour = 9
        c.minute = 30
        c.second = 0
        return cal.date(from: c) ?? now.addingTimeInterval(-6 * 3600)
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw MarketDataProviderError.notConfigured("Finnhub rejected the API key. Re-paste it in Settings.")
        case 429:
            throw MarketDataProviderError.network("Rate limited (60 req/min on free tier). Slow down.")
        default:
            let body = String(data: data, encoding: .utf8) ?? "no body"
            throw MarketDataProviderError.network("HTTP \(http.statusCode): \(body)")
        }
    }

    // MARK: WebSocket frame parsing

    private struct TradeTick {
        let symbol: String
        let price: Double
        let volume: Int
        let timestamp: Date
    }

    private static func parseTradeFrame(_ text: String) -> [TradeTick]? {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String,
              type == "trade",
              let trades = json["data"] as? [[String: Any]]
        else { return nil }

        return trades.compactMap { entry in
            guard let s = entry["s"] as? String,
                  let p = entry["p"] as? Double,
                  let t = entry["t"] as? Double
            else { return nil }
            let v = (entry["v"] as? Double).map { Int($0) } ?? 0
            return TradeTick(
                symbol: s,
                price: p,
                volume: v,
                timestamp: Date(timeIntervalSince1970: t / 1000)
            )
        }
    }
}
