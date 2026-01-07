import Foundation

struct Order: Codable {
    let symbol: String
    let quantity: Int
    let orderType: OrderType
    let price: Double?
    let stopPrice: Double?

    enum OrderType: String, Codable {
        case market
        case limit
        case stopLoss
        case stopLimit
    }
}

struct OrderResponse: Codable {
    let orderId: String
    let status: OrderStatus
    let filledQuantity: Int
    let averagePrice: Double?
    let timestamp: Date

    enum OrderStatus: String, Codable {
        case pending
        case filled
        case partiallyFilled
        case cancelled
        case rejected
    }
}

struct VolumeProfile: Codable {
    let avgVolume: Double
    let currentVolume: Double
    let volumeRatio: Double
    let isAboveAverage: Bool
}
