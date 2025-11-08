import Foundation
import Combine

@MainActor
class SignalScanner: ObservableObject {
    @Published var activeSignals: [Signal] = []
    @Published var isScanning: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let marketData = MarketDataService.shared
    private let signalSubject = PassthroughSubject<Signal, Never>()
    private var scanTimer: Timer?
    
    var signalPublisher: AnyPublisher<Signal, Never> {
        signalSubject.eraseToAnyPublisher()
    }
    
    func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        
        // Start continuous scanning every 30 seconds during market hours
        scanTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performScan()
            }
        }
        
        // Initial scan
        Task {
            await performScan()
        }
    }
    
    func stopScanning() {
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        cancellables.removeAll()
    }
    
    private func performScan() async {
        guard TimeManager.shared.isMarketHours() else { return }
        
        do {
            let marketData = try await marketData.getCurrentMarketData()
            await validateStrategies(marketData)
        } catch {
            print("Error scanning market data: \(error)")
        }
    }
    
    private func validateStrategies(_ data: MarketData) async {
        guard Strategy.validateBaseCriteria(data) else { return }
        
        for strategy in Strategy.allCases {
            if strategy.validateCriteria(data) {
                let signal = strategy.createSignal(data)
                
                // Avoid duplicate signals
                if !activeSignals.contains(where: { $0.symbol == signal.symbol && $0.strategy == signal.strategy }) {
                    activeSignals.append(signal)
                    signalSubject.send(signal)
                    
                    // Send notification
                    await NotificationService.shared.sendSignalAlert(signal)
                }
            }
        }
        
        // Clean up old signals (older than 1 hour)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        activeSignals.removeAll { $0.timestamp < oneHourAgo }
    }
    
    func removeSignal(_ signal: Signal) {
        activeSignals.removeAll { $0.id == signal.id }
    }
    
    deinit {
        stopScanning()
    }
} 