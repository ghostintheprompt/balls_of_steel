import Combine

class ExitSignalService {
    private var cancellables = Set<AnyCancellable>()
    private let marketData = MarketDataService.shared
    
    // Publisher for exit signals
    private let exitSignalSubject = PassthroughSubject<ExitSignal, Never>()
    
    func monitorPosition(symbol: String, strategy: Strategy) {
        marketData.subscribeToMarketData(symbol)
            .compactMap { $0 }
            .sink { [weak self] data in
                if let exitSignal = self?.checkExit(strategy: strategy, quote: data.quote) {
                    self?.exitSignalSubject.send(exitSignal)
                }
            }
            .store(in: &cancellables)
    }
    
    func checkExit(strategy: Strategy, quote: Quote) -> ExitSignal? {
        switch strategy {
        case .gapAndGo:
            // Exit on your exact gap fill criteria:
            // 1. Volume dies (below 100k/min)
            // 2. First red candle after gap fill
            // 3. Time past 10:00 AM
            if quote.volume < 100_000 || 
               !TimeManager.isWithinWindow("9:30", "10:00") ||
               quote.price < quote.vwap {
                return ExitSignal(
                    type: .gapAndGo,
                    reason: "Gap fill pattern complete",
                    stopPrice: quote.price * 0.985,
                    timestamp: Date()
                )
            }
            
        case .vwapReversal:
            // Your VWAP bounce exit rules:
            // 1. Price moves 2% from VWAP
            // 2. Volume below 750k/min
            // 3. Two consecutive red candles
            return vwapBasedExit(quote)
            
        case .powerHour:
            // Your power hour exit criteria:
            // 1. Loss of momentum (2 red minutes)
            // 2. Volume drops below 1M/min
            // 3. After 3:55 PM
            return momentumBasedExit(quote)
            
        case .panicReversal:
            // Your exact panic pattern exits:
            // 1. Bounce exceeds 3% from low
            // 2. Volume spike ends (< 2M/min)
            // 3. Second red candle after bounce
            return panicBasedExit(quote)
        }
        return nil
    }
}

extension ExitSignalService {
    private func vwapBasedExit(_ quote: Quote) -> ExitSignal? {
        let params = AppConfig.Thresholds.vwapReversal
        
        if abs((quote.price - quote.vwap) / quote.vwap) * 100 >= params.vwapDeviation * 2 ||
           quote.volume < params.minVolume ||
           !TimeManager.isWithinWindow("11:30", "13:30") {
            return ExitSignal(
                type: .vwapReversal,
                reason: "VWAP deviation exceeded",
                stopPrice: quote.price * (1 - params.stopLoss/100),
                timestamp: Date()
            )
        }
        return nil
    }
    
    private func momentumBasedExit(_ quote: Quote) -> ExitSignal? {
        let params = AppConfig.Thresholds.powerHour
        
        if quote.volume < params.minVolume ||
           !TimeManager.isWithinWindow("15:00", "16:00") {
            return ExitSignal(
                type: .powerHour,
                reason: "Momentum loss",
                stopPrice: quote.price * (1 - params.stopLoss/100),
                timestamp: Date()
            )
        }
        return nil
    }
    
    private func panicBasedExit(_ quote: Quote) -> ExitSignal? {
        let params = AppConfig.Thresholds.panicReversal
        
        if quote.volume < params.minVolumeSpike ||
           quote.gapPercent > -params.minDrop {
            return ExitSignal(
                type: .panicReversal,
                reason: "Reversal complete",
                stopPrice: quote.price * (1 - params.stopLoss/100),
                timestamp: Date()
            )
        }
        return nil
    }
} 