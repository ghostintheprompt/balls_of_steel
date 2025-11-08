import Foundation
import Combine
import AppKit  // For macOS

@MainActor
class SignalMonitor: ObservableObject {
    static let shared = SignalMonitor()
    @Published var activeSignals: [Signal] = []
    @Published var activeTrades: [Trade] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let scanner = SignalScanner()
    private let exitService = ExitSignalService()
    private let notificationService = NotificationService()
    private let widgetLifecycle = WidgetLifecycle.shared
    
    init() {
        setupWidgetUpdates()
    }
    
    private func setupWidgetUpdates() {
        // Start widget updates during market hours
        if TimeManager.shared.currentPhase() != .afterHours {
            widgetLifecycle.startUpdates()
        }
        
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
        if phase == .afterHours {
            widgetLifecycle.stopUpdates()
        } else {
            widgetLifecycle.startUpdates()
        }
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
            scanner.signals()
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
        
        // Update widget
        Task { @MainActor in
            WidgetCenter.shared.reloadAllTimelines()
        }
        
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
} 