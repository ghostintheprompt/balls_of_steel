import Foundation

extension Date {
    func isWithin(_ range: ClosedRange<Date>) -> Bool {
        range.contains(self)
    }
    
    func isWithinTradingHours() -> Bool {
        // Check if time is within 9:30 AM - 4:00 PM ET
        return isInWindow("09:30", "16:00")
    }
    
    // Helper for checking specific trading windows
    func isInWindow(_ start: String, _ end: String) -> Bool {
        let calendar = Calendar.current
        let easternTimeZone = TimeZone(identifier: "America/New_York")!
        
        // Get current time components in Eastern Time
        let currentComponents = calendar.dateComponents(in: easternTimeZone, from: self)
        guard let currentHour = currentComponents.hour,
              let currentMinute = currentComponents.minute else {
            return false
        }
        
        // Parse start and end times
        let startComponents = parseTimeString(start)
        let endComponents = parseTimeString(end)
        
        guard let (startHour, startMinute) = startComponents,
              let (endHour, endMinute) = endComponents else {
            return false
        }
        
        // Convert to minutes for easier comparison
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
    
    private func parseTimeString(_ timeString: String) -> (Int, Int)? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return (hour, minute)
    }
    
    // Specific trading windows based on your strategies
    var isGapAndGoWindow: Bool {
        isInWindow("09:30", "10:00")
    }
    
    var isVWAPWindow: Bool {
        isInWindow("11:30", "13:30")
    }
    
    var isPowerHourWindow: Bool {
        isInWindow("15:00", "16:00")
    }
    
    var isPreMarketInstitutionalWindow: Bool {
        isInWindow("08:00", "09:00")
    }
    
    var isPreMarketPeakWindow: Bool {
        isInWindow("08:15", "08:45")
    }

    // VXX-specific trading windows from ThinkOrSwim setup
    var isVXXMorningWindow: Bool {
        isInWindow("09:50", "10:00")  // 5-10 minute window starting at 9:50 AM
    }

    var isVXXLunchWindow: Bool {
        isInWindow("12:20", "12:35")  // 15 minute window starting at 12:20 PM
    }

    var isVXXPowerHourWindow: Bool {
        isInWindow("15:10", "15:25")  // 15 minute window starting at 3:10 PM
    }

    // SPY-specific windows (open/close focus)
    var isSPYOpenWindow: Bool {
        isInWindow("09:35", "10:05")
    }

    var isSPYCloseWindow: Bool {
        isInWindow("15:30", "15:55")
    }

    // Check if any VXX trading window is active
    var isVXXTradingWindow: Bool {
        isVXXMorningWindow || isVXXLunchWindow || isVXXPowerHourWindow
    }

    // Market phase determination
    var tradingPhase: MarketPhase {
        if !isWithinTradingHours() {
            // Check if before 9:30 AM or after 4:00 PM ET
            let calendar = Calendar.current
            let easternTimeZone = TimeZone(identifier: "America/New_York")!
            let components = calendar.dateComponents(in: easternTimeZone, from: self)
            guard let hour = components.hour else { return .afterHours }
            return hour < 9 || (hour == 9 && (components.minute ?? 0) < 30) ? .preMarket : .afterHours
        }
        
        switch self {
        case _ where isGapAndGoWindow:
            return .opening
        case _ where isVWAPWindow:
            return .midday
        case _ where isPowerHourWindow:
            return .powerHour
        default:
            return .regular
        }
    }
    
    // Additional helper methods for better market timing
    var isMarketDay: Bool {
        let calendar = Calendar.current
        let easternTimeZone = TimeZone(identifier: "America/New_York")!
        let weekday = calendar.component(.weekday, from: self)
        // Monday = 2, Friday = 6 in Calendar.weekday
        return weekday >= 2 && weekday <= 6
    }
    
    func isInMarketHours() -> Bool {
        guard isMarketDay else { return false }
        return isWithinTradingHours()
    }
}
