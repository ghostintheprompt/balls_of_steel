import Combine
import Foundation

// MARK: - Exit Signal Service
@MainActor
class ExitSignalService {
    private var cancellables = Set<AnyCancellable>()
    private var tradeCancellables: [UUID: AnyCancellable] = [:]
    private var warningSentTradeIDs = Set<UUID>()
    private let marketData = MarketDataService.shared

    // Publisher for exit signals
    private let exitSignalSubject = PassthroughSubject<ExitSignal, Never>()
    var exitPublisher: AnyPublisher<ExitSignal, Never> {
        exitSignalSubject.eraseToAnyPublisher()
    }

    func monitorPosition(trade: Trade) {
        tradeCancellables[trade.id]?.cancel()

        let cancellable = marketData.subscribeToMarketData(symbol: trade.symbol)
            .compactMap { $0 }
            .sink { [weak self] data in
                guard let self else { return }
                if let exit = self.checkExit(trade: trade, data: data) {
                    self.exitSignalSubject.send(exit)
                    if exit.action == .exit {
                        self.tradeCancellables[trade.id]?.cancel()
                        self.tradeCancellables.removeValue(forKey: trade.id)
                        self.warningSentTradeIDs.remove(trade.id)
                    } else {
                        self.warningSentTradeIDs.insert(trade.id)
                    }
                }
            }
        tradeCancellables[trade.id] = cancellable
        cancellables.insert(cancellable)
    }

    func checkExit(trade: Trade, data: MarketData) -> ExitSignal? {
        let price = data.currentPrice
        let targetHit = trade.direction == .bullish ? price >= trade.target : price <= trade.target
        let stopHit = trade.direction == .bullish ? price <= trade.stop : price >= trade.stop

        if targetHit {
            return ExitSignal(
                symbol: trade.symbol,
                strategy: trade.strategy,
                exitPrice: price,
                exitReason: .targetHit,
                action: .exit,
                timestamp: Date()
            )
        }

        if stopHit {
            return ExitSignal(
                symbol: trade.symbol,
                strategy: trade.strategy,
                exitPrice: price,
                exitReason: .stopLoss,
                action: .exit,
                timestamp: Date()
            )
        }

        if shouldIssueTimeWarning(trade: trade, now: Date()) {
            return ExitSignal(
                symbol: trade.symbol,
                strategy: trade.strategy,
                exitPrice: price,
                exitReason: .timeWarning,
                action: .warning,
                timestamp: Date()
            )
        }

        if shouldTimeExit(strategy: trade.strategy, now: Date()) {
            return ExitSignal(
                symbol: trade.symbol,
                strategy: trade.strategy,
                exitPrice: price,
                exitReason: .timeExit,
                action: .exit,
                timestamp: Date()
            )
        }

        return nil
    }

    private func shouldIssueTimeWarning(trade: Trade, now: Date) -> Bool {
        guard !warningSentTradeIDs.contains(trade.id) else { return false }
        let conditions = ExitRules.ExitConditions.forStrategy(trade.strategy)
        return isAfter(timeString: conditions.warningTime, date: now)
    }

    private func shouldTimeExit(strategy: Strategy, now: Date) -> Bool {
        let conditions = ExitRules.ExitConditions.forStrategy(strategy)
        return isAfter(timeString: conditions.hardExitTime, date: now)
    }

    private func isAfter(timeString: String, date: Date) -> Bool {
        let calendar = Calendar.current
        let easternTimeZone = TimeZone(identifier: "America/New_York")!
        let components = calendar.dateComponents(in: easternTimeZone, from: date)
        guard let hour = components.hour, let minute = components.minute else { return false }

        let currentMinutes = hour * 60 + minute
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let targetHour = Int(parts[0]),
              let targetMinute = Int(parts[1]) else { return false }

        let targetMinutes = targetHour * 60 + targetMinute
        return currentMinutes >= targetMinutes
    }
}
