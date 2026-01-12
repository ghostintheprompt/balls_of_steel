import Foundation

struct ExitSignal {
    let symbol: String
    let strategy: Strategy
    let exitPrice: Double
    let exitReason: ExitReason
    let timestamp: Date

    enum ExitReason {
        case targetHit
        case stopLoss
        case timeExit
        case vwapBreakdown
        case momentumLoss
        case trailingStop
    }
}
