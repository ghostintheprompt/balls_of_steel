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
        setupWidgetUpdates()
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
            // Check for new signals
            scanner.signalPublisher
                .sink { [weak self] signal in
                    self?.handleNewSignal(signal)
                }
                .store(in: &cancellables)
                
            // Monitor exits
            activeTrades.forEach { trade in
                exitService.monitorPosition(symbol: trade.symbol, strategy: trade.strategy)
            }
        }
    }
    
    private func handleNewSignal(_ signal: Signal) {
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
            entry: signal.entry,
            stop: signal.stop,
            target: signal.target,
            timestamp: Date(),
            currentPrice: signal.entry,
            priceHistory: [PricePoint(price: signal.entry, timestamp: Date())]
        )
        activeTrades.append(trade)
    }
} 