import Foundation

struct Quote: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let price: Double
    let volume: Int
    let vwap: Double
    let previousClose: Double
    let timestamp: Date
    let recentCandles: [Candle]
    
    // Properties needed by strategies
    var lastSize: Int { volume }
    var gapPercent: Double { 
        ((price - previousClose) / previousClose) * 100 
    }
    var hasMomentum: Bool {
        recentCandles.suffix(2).allSatisfy { $0.close > $0.open }
    }
    
    // VWAP cross detection
    var crossesVWAP: Bool {
        abs((price - vwap) / vwap) <= 0.005 // Within 0.5% of VWAP
    }
    
    // Volume surge detection
    var hasVolumeSurge: Bool {
        guard !recentCandles.isEmpty else { return false }
        let avgVolume = recentCandles.map(\.volume).reduce(0, +) / recentCandles.count
        return volume >= avgVolume * 2 // 200% above average
    }
    
    // Reversal pattern detection
    var showsReversal: Bool {
        guard recentCandles.count >= 3 else { return false }
        let last3 = Array(recentCandles.suffix(3))
        
        // Panic candle (big red) followed by hammer/reversal
        let panicCandle = last3[0].close < last3[0].open &&
                         (last3[0].open - last3[0].close) / last3[0].open > 0.02
        let hammer = last3[1].low < last3[0].low &&
                    last3[1].close > last3[1].open
        let confirmation = last3[2].close > last3[2].open
        
        return panicCandle && hammer && confirmation
    }
    
    enum CodingKeys: String, CodingKey {
        case symbol, price, volume, vwap
        case previousClose = "previous_close"
        case timestamp, recentCandles
    }
}

// Make Candle Codable
struct Candle: Codable, Identifiable {
    let id = UUID()
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
    let timestamp: Date

    private enum CodingKeys: CodingKey {
        case open, high, low, close, volume, timestamp
    }

    // Technical metrics
    var bodySize: Double {
        abs(close - open)
    }

    var upperShadow: Double {
        high - max(open, close)
    }

    var lowerShadow: Double {
        min(open, close) - low
    }

    var totalRange: Double {
        high - low
    }

    var bodyPercent: Double {
        totalRange > 0 ? bodySize / totalRange : 0
    }

    var isBullish: Bool {
        close > open
    }

    var isBearish: Bool {
        close < open
    }
}