class OptionsCalculator {
    static let shared = OptionsCalculator()
    
    func calculateOptionsEntry(stockPrice: Double, strategy: Strategy, direction: TradeDirection) -> OptionsEntry {
        let params = getParams(for: strategy)
        let type = optionType(for: direction)
        let strike = roundToNearestStrike(stockPrice, type: type)

        return OptionsEntry(
            strike: strike,
            stopPrice: calculateStopPrice(stockPrice, params: params),
            targetPrice: calculateTargetPrice(stockPrice, params: params),
            type: type
        )
    }

    private func optionType(for direction: TradeDirection) -> OptionType {
        direction == .bullish ? .call : .put
    }

    private func roundToNearestStrike(_ price: Double, type: OptionType) -> Double {
        let strikeInterval = price < 50 ? 0.5 : 1.0
        let baseStrike = (price / strikeInterval).rounded() * strikeInterval

        switch type {
        case .call: return baseStrike + strikeInterval
        case .put:  return baseStrike - strikeInterval
        }
    }
    
    private func getParams(for strategy: Strategy) -> any StrategyParameters {
        switch strategy {
        case .gapAndGo: return AppConfig.Thresholds.gapAndGo
        case .vwapReversal: return AppConfig.Thresholds.vwapReversal
        case .powerHour: return AppConfig.Thresholds.powerHour
        case .panicReversal: return AppConfig.Thresholds.panicReversal
        default: return AppConfig.Thresholds.gapAndGo // Default fallback
        }
    }
    
    private func calculateStopPrice(_ stockPrice: Double, params: any StrategyParameters) -> Double {
        switch params {
        case let gap as GapAndGoParams:
            return stockPrice * (1 - gap.stopLoss/100)
        case let vwap as VWAPParams:
            return stockPrice * (1 - vwap.stopLoss/100)
        case let power as PowerHourParams:
            return stockPrice * (1 - power.stopLoss/100)
        case let panic as PanicParams:
            return stockPrice * (1 + panic.stopLoss/100)
        default:
            // Elite Fallback: Use standard 1% stop if strategy is unknown
            return stockPrice * 0.99
        }
    }

    private func calculateTargetPrice(_ stockPrice: Double, params: any StrategyParameters) -> Double {
        switch params {
        case let gap as GapAndGoParams:
            return stockPrice * (1 + gap.target/100)
        case let vwap as VWAPParams:
            return stockPrice * (1 + vwap.target/100)
        case let power as PowerHourParams:
            return stockPrice * (1 + power.target/100)
        case let panic as PanicParams:
            return stockPrice * (1 - panic.target/100)
        default:
            // Elite Fallback: Use standard 2% target if strategy is unknown
            return stockPrice * 1.02
        }
    }

}

struct OptionsEntry {
    let strike: Double
    let stopPrice: Double    // Stock price where we exit
    let targetPrice: Double  // Stock price where we take profit
    let type: OptionType
}

// Add protocol to make params type-safe
protocol StrategyParameters {
    var stopLoss: Double { get }
    var target: Double { get }
}

// Make our param structs conform
extension GapAndGoParams: StrategyParameters {}
extension VWAPParams: StrategyParameters {}
extension PowerHourParams: StrategyParameters {}
extension PanicParams: StrategyParameters {} 