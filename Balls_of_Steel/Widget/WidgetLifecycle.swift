import WidgetKit
import SwiftUI

class WidgetLifecycle: ObservableObject {
    static let shared = WidgetLifecycle()
    
    private var updateTimer: Timer?
    private var isMonitoring = false
    
    private init() {
        setupNotificationObservers()
    }
    
    // MARK: - Public Interface
    
    func startUpdates() {
        guard !isMonitoring else { return }
        
        stopUpdates()
        isMonitoring = true
        
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: WidgetConfiguration.refreshInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateWidgetsIfNeeded()
        }
        
        // Initial update
        updateWidgetsIfNeeded()
    }
    
    func stopUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        isMonitoring = false
    }
    
    func forceUpdate() {
        updateWidgets()
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .marketPhaseChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMarketPhaseChange()
        }
        
        // Update when signals change
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SignalsUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateWidgets()
        }
    }
    
    private func updateWidgetsIfNeeded() {
        let currentPhase = TimeManager.shared.currentPhase()
        
        // Don't update during off-hours unless there's an important change
        guard shouldUpdateForPhase(currentPhase) else { return }
        
        updateWidgets()
    }
    
    private func updateWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func handleMarketPhaseChange() {
        // Always update on phase change for proper status display
        updateWidgets()
    }
    
    private func shouldUpdateForPhase(_ phase: MarketPhase) -> Bool {
        switch phase {
        case .preMarket:
            return Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 300) < 60 // Every 5 minutes
        case .opening, .powerHour:
            return true // Update frequently during high-activity periods
        case .midday, .regular:
            return Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 120) < 60 // Every 2 minutes
        case .afterHours:
            return Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 600) < 60 // Every 10 minutes
        }
    }
    
    deinit {
        stopUpdates()
        NotificationCenter.default.removeObserver(self)
    }
} 