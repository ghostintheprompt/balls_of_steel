import Foundation
import Combine

// MARK: - EDUCATIONAL MODE SIGNAL SCANNER
// This scanner displays example signals to teach the VXX system
// No real-time scanning - manual data entry drives signal generation

@MainActor
class SignalScanner: ObservableObject {
    @Published var activeSignals: [Signal] = []
    @Published var exampleSignals: [SignalExample] = []
    @Published var isScanning: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let marketData = MarketDataService.shared
    private let signalSubject = PassthroughSubject<Signal, Never>()

    var signalPublisher: AnyPublisher<Signal, Never> {
        signalSubject.eraseToAnyPublisher()
    }

    init() {
        // Load educational examples
        loadExampleSignals()

        // Subscribe to manual data entries
        setupManualDataListener()
    }

    // MARK: - Educational Mode
    /// This app doesn't scan automatically - it teaches you the system
    /// Use manual data entry to see how signals are validated
    func startScanning() {
        // Educational mode - no live scanning
        isScanning = false
        #if DEBUG
        print("Educational Mode: Use Manual Data Entry to generate signals")
        #endif
    }

    func stopScanning() {
        isScanning = false
        cancellables.removeAll()
    }

    // MARK: - Manual Data Entry Integration
    /// When user enters manual data, validate and show signals
    private func setupManualDataListener() {
        marketData.subscribeToMarketData(symbol: "VXX")
            .compactMap { $0 }
            .sink { [weak self] data in
                Task { @MainActor in
                    await self?.validateManualEntry(data)
                }
            }
            .store(in: &cancellables)
    }

    private func validateManualEntry(_ data: MarketData) async {
        // Clear old signals
        activeSignals.removeAll()

        // Validate strategies with manual data
        for strategy in Strategy.allCases where strategy.isVXXStrategy {
            if strategy.validateCriteria(data) {
                let signal = strategy.createSignal(data)
                activeSignals.append(signal)
                signalSubject.send(signal)
            }
        }
    }

    // MARK: - Educational Examples
    /// Load example signals showing how the system works
    func loadExampleSignals() {
        exampleSignals = [
            SignalExample(
                title: "Institutional Flow - STRONG",
                description: "VXX $42.15 | 340% Volume | Arrow Confirmed | 3:47 PM",
                strategy: .vxxInstitutionalFlow,
                outcome: "90% Win Rate Window",
                entrySetup: "Buy $41 puts at 3:47 PM when you see this setup on your platform",
                volumeLevel: 340,
                timeWindow: "3:45-4:10 PM",
                reliability: "90%",
                signalStrength: .strong
            ),
            SignalExample(
                title: "Morning Fade - STRONG",
                description: "VXX $43.80 | 280% Volume | Arrow + MA Cross | 9:52 AM",
                strategy: .vxxMorningWindow,
                outcome: "85% Win Rate Window",
                entrySetup: "Sell $44 calls when VXX breaks below 20 SMA with volume",
                volumeLevel: 280,
                timeWindow: "9:50-10:15 AM",
                reliability: "85%",
                signalStrength: .strong
            ),
            SignalExample(
                title: "Power Hour Crush - MODERATE",
                description: "VXX $42.90 | 220% Volume | Arrow Only | 3:12 PM",
                strategy: .vxxPowerHour,
                outcome: "80% Win Rate Window",
                entrySetup: "Half position - wait for VWAP break confirmation",
                volumeLevel: 220,
                timeWindow: "3:10-3:25 PM",
                reliability: "80%",
                signalStrength: .moderate
            ),
            SignalExample(
                title: "Volume Spike - WEAK (SKIP)",
                description: "VXX $41.50 | 180% Volume | No Arrow | 2:30 PM",
                strategy: .vxxVolumeSpike,
                outcome: "Below 200% threshold - IGNORE",
                entrySetup: "DO NOT TRADE - Volume below required 200%",
                volumeLevel: 180,
                timeWindow: "Non-priority window",
                reliability: "N/A",
                signalStrength: .weak
            ),
            SignalExample(
                title: "Lunch Window - MODERATE",
                description: "VXX $42.20 | 240% Volume | Arrow + Pattern | 12:25 PM",
                strategy: .vxxLunchWindow,
                outcome: "70% Win Rate Window",
                entrySetup: "Consider if no better windows available later",
                volumeLevel: 240,
                timeWindow: "12:20-12:40 PM",
                reliability: "70%",
                signalStrength: .moderate
            )
        ]
    }

    /// Get example signal for a specific strategy
    func getExampleFor(strategy: Strategy) -> SignalExample? {
        exampleSignals.first { $0.strategy == strategy }
    }

    /// Show all example signals (educational display)
    func showAllExamples() -> [SignalExample] {
        exampleSignals
    }

    func removeSignal(_ signal: Signal) {
        activeSignals.removeAll { $0.id == signal.id }
    }

    deinit {
        // Cleanup happens automatically via cancellables
    }
}

// MARK: - Educational Signal Example
struct SignalExample: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let strategy: Strategy
    let outcome: String
    let entrySetup: String
    let volumeLevel: Int
    let timeWindow: String
    let reliability: String
    let signalStrength: SignalStrength

    enum SignalStrength {
        case strong, moderate, weak

        var color: String {
            switch self {
            case .strong: return "green"
            case .moderate: return "orange"
            case .weak: return "red"
            }
        }

        var displayName: String {
            switch self {
            case .strong: return "STRONG - Full Position"
            case .moderate: return "MODERATE - Half Position"
            case .weak: return "WEAK - Skip Trade"
            }
        }
    }
}

// Strategy extension to identify VXX strategies
extension Strategy {
    var isVXXStrategy: Bool {
        switch self {
        case .vxxInstitutionalFlow,
             .vxxFadeSetup,
             .vxxPowerHour,
             .vxxMorningWindow,
             .vxxVolumeSpike,
             .vxxLunchWindow:
            return true
        default:
            return false
        }
    }
} 