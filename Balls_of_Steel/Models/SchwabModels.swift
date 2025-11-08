struct OptionsQuote: Codable {
    let symbol: String
    let bid: Double
    let ask: Double
    let last: Double
    let volume: Int
    let openInterest: Int
    
    enum CodingKeys: String, CodingKey {
        case symbol, bid, ask, last, volume
        case openInterest = "open_interest"
    }
}

// APIResponse is already defined in APIResponse.swift - removed duplicate 