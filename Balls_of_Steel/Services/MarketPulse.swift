import Foundation
import Combine

@MainActor
class MarketPulse: ObservableObject {
    static let shared = MarketPulse()
    @Published private(set) var currentPhase: MarketPhase = .regular
    private var cancellables = Set<AnyCancellable>()
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init() {
        setupTimer()
        updatePhase()
    }
    
    private func setupTimer() {
        timer
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updatePhase()
            }
            .store(in: &cancellables)
    }
    
    private func updatePhase() {
        currentPhase = TimeManager.shared.currentPhase()
    }
} 