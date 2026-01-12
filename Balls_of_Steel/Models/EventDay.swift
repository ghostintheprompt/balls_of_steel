import Foundation

// MARK: - Event Day Detection & Strategy
// FOMC/Fed Event Day modifications for position sizing and timing

struct EventDay {
    let date: Date
    let type: EventType
    let announcementTime: Date
    let impactLevel: ImpactLevel

    enum EventType {
        case fomcMeeting      // Federal Open Market Committee
        case fedSpeech        // Fed Chair/Governor speech
        case cpiRelease       // Consumer Price Index
        case jobsReport       // Non-Farm Payrolls
        case earnings         // Major earnings (AAPL, MSFT, etc.)
        case other            // Other market-moving events

        var displayName: String {
            switch self {
            case .fomcMeeting: return "FOMC Meeting"
            case .fedSpeech: return "Fed Speech"
            case .cpiRelease: return "CPI Release"
            case .jobsReport: return "Jobs Report"
            case .earnings: return "Major Earnings"
            case .other: return "Market Event"
            }
        }

        var icon: String {
            switch self {
            case .fomcMeeting, .fedSpeech: return "building.columns.fill"
            case .cpiRelease, .jobsReport: return "chart.bar.fill"
            case .earnings: return "dollarsign.circle.fill"
            case .other: return "exclamationmark.triangle.fill"
            }
        }
    }

    enum ImpactLevel {
        case high      // Major market mover (FOMC, CPI, NFP)
        case medium    // Moderate impact (Fed speech, minor data)
        case low       // Low impact (regional Fed, minor earnings)

        var displayName: String {
            switch self {
            case .high: return "High Impact"
            case .medium: return "Medium Impact"
            case .low: return "Low Impact"
            }
        }

        var positionSizeAdjustment: Double {
            switch self {
            case .high: return 0.5   // 50% of normal
            case .medium: return 0.75 // 75% of normal
            case .low: return 1.0    // Normal sizing
            }
        }

        var requiresExit: Bool {
            self == .high // Exit positions 15 min before high impact events
        }
    }

    // MARK: - Event Day Strategy
    var strategy: EventStrategy {
        if isPreEvent {
            return .preEvent
        } else if isPostEvent {
            return .postEvent
        } else {
            return .normal
        }
    }

    enum EventStrategy {
        case preEvent   // Before announcement
        case postEvent  // After announcement
        case normal     // No event

        var displayName: String {
            switch self {
            case .preEvent: return "Pre-Event (Reduced Size)"
            case .postEvent: return "Post-Event (Prime Fade)"
            case .normal: return "Normal Trading"
            }
        }

        var positionSizing: String {
            switch self {
            case .preEvent: return "Small positions for volatility run-up"
            case .postEvent: return "Standard sizing if IV normalizes"
            case .normal: return "Standard position sizing"
            }
        }
    }

    // MARK: - Timing Analysis
    var isPreEvent: Bool {
        let now = Date()
        let timeUntilEvent = announcementTime.timeIntervalSince(now)
        return timeUntilEvent > 0 && timeUntilEvent < 3600 * 2 // Within 2 hours before
    }

    var isPostEvent: Bool {
        let now = Date()
        let timeSinceEvent = now.timeIntervalSince(announcementTime)
        return timeSinceEvent > 0 && timeSinceEvent < 3600 * 4 // Within 4 hours after
    }

    var minutesUntilEvent: Int {
        let timeUntil = announcementTime.timeIntervalSince(Date())
        return max(0, Int(timeUntil / 60))
    }

    var shouldExitPositions: Bool {
        impactLevel.requiresExit && minutesUntilEvent <= 15
    }

    // MARK: - Political Factor Assessment
    var politicalContext: PoliticalContext {
        // Assess current political environment
        // Trump administration pressure = Dovish bias likely
        // This would be updated based on current administration
        return .neutral
    }

    enum PoliticalContext {
        case dovishPressure    // Political pressure for rate cuts
        case hawkishPressure   // Political pressure for rate hikes
        case neutral          // No significant political pressure

        var expectedBias: String {
            switch self {
            case .dovishPressure: return "Market rallies on dovish surprises = VXX fade"
            case .hawkishPressure: return "Market sells on hawkish surprises = VXX spike"
            case .neutral: return "No clear bias - trade the reaction"
            }
        }
    }
}

// MARK: - Event Day Manager
class EventDayManager {
    static let shared = EventDayManager()

    private var upcomingEvents: [EventDay] = []

    // MARK: - Event Detection
    func checkForEventDay(date: Date = Date()) -> EventDay? {
        return upcomingEvents.first { event in
            Calendar.current.isDate(event.date, inSameDayAs: date)
        }
    }

    func isEventDay(date: Date = Date()) -> Bool {
        checkForEventDay(date: date) != nil
    }

    // MARK: - Position Sizing Adjustment
    func adjustedPositionSize(baseSize: Double, date: Date = Date()) -> Double {
        guard let event = checkForEventDay(date: date) else {
            return baseSize
        }

        return baseSize * event.impactLevel.positionSizeAdjustment
    }

    // MARK: - Should Exit Before Event
    func shouldExitBeforeEvent(date: Date = Date()) -> Bool {
        guard let event = checkForEventDay(date: date) else {
            return false
        }

        return event.shouldExitPositions
    }

    // MARK: - Event Calendar (Pre-populated with known events)
    func loadUpcomingEvents() {
        // This would typically be loaded from an API or calendar
        // For now, we'll use a manual list

        let calendar = Calendar.current
        let now = Date()

        // Example: FOMC meetings typically 8 times per year
        // These would be updated with actual FOMC schedule

        // For demonstration, let's add some sample events
        upcomingEvents = [
            // FOMC meetings
            EventDay(
                date: calendar.date(byAdding: .day, value: 14, to: now)!,
                type: .fomcMeeting,
                announcementTime: calendar.date(byAdding: .day, value: 14, to: now)!.addingTimeInterval(14 * 3600), // 2 PM
                impactLevel: .high
            ),
            // CPI Release
            EventDay(
                date: calendar.date(byAdding: .day, value: 7, to: now)!,
                type: .cpiRelease,
                announcementTime: calendar.date(byAdding: .day, value: 7, to: now)!.addingTimeInterval(8.5 * 3600), // 8:30 AM
                impactLevel: .high
            ),
            // Jobs Report
            EventDay(
                date: calendar.date(byAdding: .day, value: 3, to: now)!,
                type: .jobsReport,
                announcementTime: calendar.date(byAdding: .day, value: 3, to: now)!.addingTimeInterval(8.5 * 3600), // 8:30 AM
                impactLevel: .high
            )
        ]
    }

    // MARK: - Event Strategy Recommendation
    func getEventStrategy(date: Date = Date()) -> String {
        guard let event = checkForEventDay(date: date) else {
            return "Normal trading - no events scheduled"
        }

        if event.isPreEvent {
            return """
            PRE-EVENT STRATEGY:
            - IV typically elevated (>80%)
            - Small positions for volatility run-up
            - Exit all positions 15 minutes before announcement
            - Position size: \(Int(event.impactLevel.positionSizeAdjustment * 100))% of normal
            """
        } else if event.isPostEvent {
            return """
            POST-EVENT STRATEGY:
            - Prime fade opportunities when IV crushes
            - Wait for institutional reaction at 3:45 PM
            - Standard sizing if IV normalizes
            - Watch for \(event.politicalContext.expectedBias)
            """
        } else {
            return "Event later today - trade with caution"
        }
    }

    // MARK: - IV Level Detection
    func isHighIVEnvironment(currentIV: Double) -> Bool {
        currentIV > 80.0
    }

    func ivAdjustedStrategy(currentIV: Double) -> IVStrategy {
        if currentIV > 85 {
            return .extreme
        } else if currentIV > 80 {
            return .high
        } else if currentIV >= 60 {
            return .normal
        } else {
            return .low
        }
    }

    enum IVStrategy {
        case extreme   // >85% IV
        case high      // 80-85% IV
        case normal    // 60-80% IV
        case low       // <60% IV

        var positionSizeAdjustment: Double {
            switch self {
            case .extreme: return 0.5   // 50% reduction
            case .high: return 0.75     // 25% reduction
            case .normal: return 1.0    // Standard
            case .low: return 1.0       // Standard
            }
        }

        var profitTarget: Double {
            switch self {
            case .extreme: return 0.20  // 20% quick scalp
            case .high: return 0.25     // 25% faster exit
            case .normal: return 0.30   // 30% standard
            case .low: return 0.30      // 30% standard
            }
        }

        var displayName: String {
            switch self {
            case .extreme: return "EXTREME IV (>85%) - Quick scalp only"
            case .high: return "HIGH IV (80-85%) - Faster exits"
            case .normal: return "NORMAL IV (60-80%) - Standard strategy"
            case .low: return "LOW IV (<60%) - Standard strategy"
            }
        }
    }
}

// MARK: - Dynamic Position Sizing with Event & IV Adjustments
struct DynamicPositionSizer {

    static func calculatePositionSize(
        baseSize: Double,
        arrowSignal: ArrowSignal,
        currentIV: Double,
        eventDay: EventDay?
    ) -> PositionSizingResult {

        var adjustedSize = baseSize

        // 1. Arrow signal strength adjustment
        adjustedSize *= arrowSignal.strength.positionSize

        // 2. Volume-based adjustment (institutional flow)
        switch arrowSignal.volumeConfirmation {
        case .majorInstitution:
            // Higher conviction but respect 1 contract max
            adjustedSize = min(adjustedSize, 1.0)
        case .institutional:
            adjustedSize = min(adjustedSize, 1.0)
        case .standard:
            // No adjustment needed for standard confirmation
            break
        case .none:
            adjustedSize = 0 // Skip trade
        }

        // 3. Event day adjustment
        if let event = eventDay {
            adjustedSize *= event.impactLevel.positionSizeAdjustment
        }

        // 4. IV adjustment
        let ivStrategy = EventDayManager.shared.ivAdjustedStrategy(currentIV: currentIV)
        adjustedSize *= ivStrategy.positionSizeAdjustment

        // 5. Apply greed control (1 contract maximum)
        let finalSize = min(adjustedSize, 1.0)

        return PositionSizingResult(
            size: finalSize,
            reasoning: generateReasoning(
                signal: arrowSignal,
                iv: currentIV,
                event: eventDay
            )
        )
    }

    private static func generateReasoning(
        signal: ArrowSignal,
        iv: Double,
        event: EventDay?
    ) -> [String] {
        var reasons: [String] = []

        // Signal strength
        reasons.append("Signal: \(signal.strength.displayName)")

        // Volume confirmation
        reasons.append("Volume: \(signal.volumeConfirmation.displayName)")

        // Time window
        reasons.append("Window: \(signal.timeWindow.displayName)")

        // Event day
        if let event = event {
            reasons.append("Event: \(event.type.displayName) - \(event.strategy.displayName)")
        }

        // IV level
        let ivStrategy = EventDayManager.shared.ivAdjustedStrategy(currentIV: iv)
        reasons.append("IV: \(ivStrategy.displayName)")

        return reasons
    }

    struct PositionSizingResult {
        let size: Double
        let reasoning: [String]

        var displaySize: String {
            if size >= 1.0 {
                return "1 contract (Full)"
            } else if size >= 0.5 {
                return "0.5 contract (Half)"
            } else if size > 0 {
                return "\(String(format: "%.2f", size)) contract"
            } else {
                return "Skip trade"
            }
        }
    }
}
