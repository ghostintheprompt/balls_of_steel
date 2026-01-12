class OptionsCalculator {
    static let shared = OptionsCalculator()
    
    func calculateOptionsEntry(stockPrice: Double, strategy: Strategy) -> OptionsEntry {
        let params = getParams(for: strategy)
        let strike = roundToNearestStrike(stockPrice, strategy: strategy)
        
        return OptionsEntry(
            strike: strike,
            stopPrice: calculateStopPrice(stockPrice, params: params),
            targetPrice: calculateTargetPrice(stockPrice, params: params),
            type: getOptionType(strategy)
        )
    }
    
    // Select options based purely on the signal
    func selectBestOption(chain: [OptionContract], signal: Signal) -> OptionContract? {
        // Filter by basic liquidity only
        let liquid = chain.filter { $0.volume > 0 && $0.openInterest > 0 }
        
        // Target delta around 0.40 for leverage
        return liquid
            .filter { $0.delta >= 0.35 && $0.delta <= 0.45 }
            .first
    }
    
    private func getOptionType(_ strategy: Strategy) -> OptionType {
        switch strategy {
        case .gapAndGo: return .call     // Gap up = calls
        case .vwapReversal: return .call // VWAP bounce = calls
        case .powerHour: return .call    // Power hour momentum = calls
        case .panicReversal: return .put // Panic = puts
        default: return .call // Default for other strategies
        }
    }
    
    private func roundToNearestStrike(_ price: Double, strategy: Strategy) -> Double {
        let strikeInterval = price < 50 ? 0.5 : 1.0
        let baseStrike = (price / strikeInterval).rounded() * strikeInterval
        
        switch getOptionType(strategy) {
        case .call: return baseStrike + strikeInterval
        case .put: return baseStrike - strikeInterval
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
            fatalError("Unknown strategy parameters")
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
            fatalError("Unknown strategy parameters")
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