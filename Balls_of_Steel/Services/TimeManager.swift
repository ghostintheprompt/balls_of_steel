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
        return createTodayDate(hour: 16, minute: 0)
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
    
    func calculateCurrentPhase() -> MarketPhase {
        let now = Date()
        let timeStr = formatter.string(from: now)

        switch timeStr {
        case ..<"09:30": return .preMarket
        case "09:30"..."10:00": return .opening
        case "11:30"..."13:30": return .midday
        case "15:00"..."16:00": return .powerHour
        case "16:00"...: return .afterHours
        default: return .regular
        }
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

        if t >= 9*60+50 && t < 10*60+0  { return (true, .morning) }
        if t >= 12*60+20 && t < 12*60+35 { return (true, .lunch) }
        if t >= 15*60+10 && t < 15*60+25 { return (true, .powerHour) }
        if t >= 15*60+45 && t < 16*60+10 { return (true, .institutional) }
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