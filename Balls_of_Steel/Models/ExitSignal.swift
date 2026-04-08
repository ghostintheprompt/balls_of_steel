import Foundation

struct ExitSignal {
    let symbol: String
    let strategy: Strategy
    let exitPrice: Double
    let exitReason: ExitReason
    let action: Action
    let timestamp: Date

    enum Action {
        case warning
        case exit

        var displayName: String {
            switch self {
            case .warning: return "Warning"
            case .exit: return "Exit"
            }
        }
    }

    enum ExitReason {
        case targetHit
        case stopLoss
        case timeExit
        case timeWarning
        case vwapBreakdown
        case momentumLoss
        case trailingStop

        var displayName: String {
            switch self {
            case .targetHit: return "Target Hit"
            case .stopLoss: return "Stop Loss"
            case .timeExit: return "Time Exit"
            case .timeWarning: return "First Close Warning"
            case .vwapBreakdown: return "VWAP Breakdown"
            case .momentumLoss: return "Momentum Loss"
            case .trailingStop: return "Trailing Stop"
            }
        }
    }
}
