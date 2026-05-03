import Foundation

struct Order {
    let symbol: String
    let quantity: Int
    let orderType: OrderType
    let price: Double?
    let strategy: Strategy
    let timestamp: Date

    enum OrderType {
        case market
        case limit
        case stop
        case stopLimit
    }
}

struct OrderResponse {
    let orderId: String
    let status: OrderStatus
    let filledPrice: Double?
    let timestamp: Date

    enum OrderStatus {
        case pending
        case filled
        case partiallyFilled
        case cancelled
        case rejected
    }
}
