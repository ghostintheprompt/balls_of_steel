import Foundation
import Combine
import SwiftUI
import AppKit  // For macOS

@MainActor
class SignalMonitor: ObservableObject {
    static let shared = SignalMonitor()
    @Published var activeSignals: [Signal] = []
    @Published var activeTrades: [Trade] = []
    @Published var highlightedSignalID: UUID?
    private var cancellables = Set<AnyCancellable>()
    
    private let scanner = SignalScanner()
    private let exitService = ExitSignalService()
    private let notificationService = NotificationService()

    init() {
        setupSignalStream()
        setupWidgetUpdates()
        setupExitMonitoring()
    }

    private func setupSignalStream() {
        scanner.signalPublisher
            .sink { [weak self] signal in
                self?.handleNewSignal(signal)
            }
            .store(in: &cancellables)
    }

    private func setupWidgetUpdates() {
        // Widget updates removed for v3.0 - will add back in v3.1
        // Listen for market phase changes
        NotificationCenter.default.publisher(for: .marketPhaseChanged)
            .sink { [weak self] notification in
                if let phase = notification.object as? MarketPhase {
                    self?.handleMarketPhaseChange(phase)
                }
            }
            .store(in: &cancellables)
    }

    private func handleMarketPhaseChange(_ phase: MarketPhase) {
        // Widget lifecycle removed for v3.0
    }

    private func setupExitMonitoring() {
        exitService.exitPublisher
            .sink { [weak self] exitSignal in
                self?.handleExitSignal(exitSignal)
            }
            .store(in: &cancellables)
    }
    
    func startBackgroundMonitoring() {
        // Use macOS background task alternative
        let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        timer.sink { [weak self] _ in
            self?.refreshSignals()
        }
        .store(in: &cancellables)
    }
    
    private func refreshSignals() {
        Task {
            // Monitor exits
            for index in activeTrades.indices {
                let trade = activeTrades[index]
                exitService.monitorPosition(trade: trade)
                if let quote = MarketDataService.shared.latestQuote(symbol: trade.symbol) {
                    activeTrades[index].currentPrice = quote.price
                    activeTrades[index].priceHistory.append(PricePoint(price: quote.price, timestamp: quote.timestamp))
                }
            }
        }
    }
    
    private func handleNewSignal(_ signal: Signal) {
        activeSignals.removeAll {
            $0.symbol == signal.symbol &&
            $0.strategy == signal.strategy &&
            $0.kind == signal.kind
        }
        activeSignals.append(signal)
        SignalNotification.shared.signalDetected(signal)
        
        // Widgets removed for v3.0

        // Update UI
        withAnimation {
            // Highlight the new signal in TradingDashboard
            highlightedSignalID = signal.id
            
            // Auto-scroll to new signal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    self.scrollToSignal(signal.id)
                }
            }
        }
    }
    
    func scrollToSignal(_ id: UUID) {
        highlightedSignalID = id
    }

    func stopBackgroundMonitoring() {
        cancellables.removeAll()
    }

    func startTrade(_ signal: Signal) {
        let trade = Trade(
            symbol: signal.symbol,
            strategy: signal.strategy,
            direction: signal.direction,
            entry: signal.entry,
            stop: signal.stop,
            target: signal.target,
            timestamp: Date(),
            currentPrice: signal.entry,
            priceHistory: [PricePoint(price: signal.entry, timestamp: Date())]
        )
        activeTrades.append(trade)
        exitService.monitorPosition(trade: trade)
    }

    private func handleExitSignal(_ exitSignal: ExitSignal) {
        if exitSignal.action == .exit {
            activeTrades.removeAll { $0.symbol == exitSignal.symbol && $0.strategy == exitSignal.strategy }
        }
        SignalNotification.shared.exitDetected(exitSignal)
    }
}
