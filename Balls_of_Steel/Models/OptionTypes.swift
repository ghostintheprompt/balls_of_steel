import Foundation

enum OptionType: String, Codable {
    case call
    case put
}

struct OptionContract: Identifiable {
    let id = UUID()
    let symbol: String
    let strike: Double
    let expiration: Date
    let type: OptionType
    let bid: Double
    let ask: Double
    
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