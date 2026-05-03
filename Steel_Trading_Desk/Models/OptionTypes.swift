import Foundation

enum OptionType: String, Codable {
    case call
    case put
}

struct OptionContract: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let strike: Double
    let expiration: Date
    let type: OptionType
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

    private enum CodingKeys: String, CodingKey {
        case symbol, strike, expiration, type, bid, ask, last, volume, openInterest, delta, gamma, theta, vega, impliedVolatility
    }

    var midPrice: Double {
        (bid + ask) / 2
    }
}

// TD API Response - only what we need
struct OptionsChainResponse: Codable {
    let callExpDateMap: [String: [String: [OptionData]]]
    let putExpDateMap: [String: [String: [OptionData]]]
    
    struct OptionData: Codable {
        let strikePrice: Double
        let bid: Double
        let ask: Double
        let totalVolume: Int
        let delta: Double
    }
} 