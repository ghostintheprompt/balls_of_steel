import Foundation

extension Notification.Name {
    static let marketPhaseChanged = Notification.Name("marketPhaseChanged")
}

@MainActor
class TimeManager: ObservableObject {
    static let shared = TimeManager()
    @Published private(set) var currentPhase: MarketPhase = .regular
    @Published private(set) var isTradingWindowOpen: Bool = false
    @Published private(set) var activeWindow: VXXTradingWindow? = nil

    private var windowTimer: Timer?
    
    // Market hours in Eastern Time
    var marketOpen: Date {
        return createTodayDate(hour: 9, minute: 30)
    }
    
    var marketClose: Date {
        return createTodayDate(hour: 16, minute: 15)
    }
    
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = TimeZone(identifier: "America/New_York")!
        df.dateFormat = "HH:mm"
        return df
    }()
    
    // Helper method to create dates for today in Eastern Time
    private func createTodayDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let easternTimeZone = TimeZone(identifier: "America/New_York")!
        
        var components = calendar.dateComponents(in: easternTimeZone, from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.nanosecond = 0
        components.timeZone = easternTimeZone
        
        return calendar.date(from: components) ?? Date()
    }
    
    /// Rewritten 2026-09-09 -- this used raw "HH:mm" string-range comparisons
    /// with its own hardcoded window (`"15:00"..."16:00"` = .powerHour) that
    /// had nothing to do with `StrategySpec`. It predated `StrategySpec`
    /// having an Institutional window at all, so 3:45-4:10 PM (the real
    /// Institutional Flow window) AND the 20-minute dead zone between Power
    /// Hour and Institutional (3:25-3:45) both silently read "Power Hour" on
    /// the top bar -- found live at 3:51 PM ET while the left rail (which
    /// already read `StrategySpec.institutionalWindow` via
    /// `LiveTapeService.currentTimeWindow()`) correctly said Institutional.
    /// Now shares the same StrategySpec boundaries as `currentTradingWindowStatus()`
    /// below, instead of a second, independently-drifting definition.
    func calculateCurrentPhase() -> MarketPhase {
        let eastern = TimeZone(identifier: "America/New_York")!
        let comps = Calendar.current.dateComponents(in: eastern, from: Date())
        guard let h = comps.hour, let m = comps.minute else { return .regular }
        let t = h * 60 + m

        if t < StrategySpec.preMarketCutoffMinutes { return .preMarket }
        if t >= StrategySpec.afterHoursMinutes { return .afterHours }
        if t < 10 * 60 { return .opening }                                  // 9:30-10:00
        if t >= 11 * 60 + 30 && t < 13 * 60 + 30 { return .midday }         // 11:30-1:30
        if t >= StrategySpec.powerHourWindow.startMinutes && t < StrategySpec.powerHourWindow.endMinutes {
            return .powerHour
        }
        if t >= StrategySpec.institutionalWindow.startMinutes && t < StrategySpec.institutionalWindow.endMinutes {
            return .institutional
        }
        return .regular
    }

    // Missing method for MarketData validation
    func isMarketHours() -> Bool {
        let phase = calculateCurrentPhase()
        return ![.preMarket, .afterHours].contains(phase)
    }
    
    func startWindowMonitor() {
        updateWindowState()
        windowTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateWindowState()
            }
        }
    }

    func stopWindowMonitor() {
        windowTimer?.invalidate()
        windowTimer = nil
    }

    private func updateWindowState() {
        let (open, window) = currentTradingWindowStatus()
        isTradingWindowOpen = open
        activeWindow = window
        updatePhase()
    }

    func currentTradingWindowStatus() -> (Bool, VXXTradingWindow?) {
        let eastern = TimeZone(identifier: "America/New_York")!
        let comps = Calendar.current.dateComponents(in: eastern, from: Date())
        guard let h = comps.hour, let m = comps.minute else { return (false, nil) }
        let t = h * 60 + m

        if t >= StrategySpec.morningWindow.startMinutes && t < StrategySpec.morningWindow.endMinutes {
            return (true, .morning)
        }
        if t >= 12 * 60 + 20 && t < 12 * 60 + 40 {
            return (true, .lunch)
        }
        if t >= StrategySpec.powerHourWindow.startMinutes && t < StrategySpec.powerHourWindow.endMinutes {
            return (true, .powerHour)
        }
        if t >= StrategySpec.institutionalWindow.startMinutes && t < StrategySpec.institutionalWindow.endMinutes {
            return (true, .institutional)
        }
        return (false, nil)
    }

    private func updatePhase() {
        let newPhase = calculateCurrentPhase()
        if currentPhase != newPhase {
            currentPhase = newPhase
            NotificationCenter.default.post(
                name: .marketPhaseChanged,
                object: newPhase
            )
        }
    }
}
