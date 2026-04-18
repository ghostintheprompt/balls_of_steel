import Foundation

// MARK: - Trading Prompt System
// Delivers the right analysis prompt at the right time with live data pre-filled
// No paid APIs - just smart scheduling + clipboard integration

struct TradingPrompt {
    let id = UUID()
    let type: PromptType
    let scheduledTime: PromptSchedule
    let template: String
    let dataFields: [DataField]

    enum PromptType {
        case preMarketAnalysis      // 8:30-9:25 AM
        case morningWindow          // 9:45 AM
        case lunchWindow            // 12:15 PM
        case powerHourAnalysis      // 3:05 PM
        case institutionalFlowAlert // 3:40 PM (New)
        case exitReminder           // 3:50 PM (5 min warning)
        case postTradeAnalysis      // 3:55 PM
        case weeklyReview           // Friday evening
        case monthlyReview          // Last trading day
        case crisisMode             // VIX >30
        case losingStreak           // 3+ losses

        var displayName: String {
            switch self {
            case .preMarketAnalysis: return "Pre-Market Analysis"
            case .morningWindow: return "Morning Window Check"
            case .lunchWindow: return "Lunch Window Check"
            case .powerHourAnalysis: return "Power Hour Analysis"
            case .institutionalFlowAlert: return "Institutional Flow Alert"
            case .exitReminder: return "Exit Time Reminder"
            case .postTradeAnalysis: return "Post-Trade Review"
            case .weeklyReview: return "Weekly Review"
            case .monthlyReview: return "Monthly Review"
            case .crisisMode: return "Crisis Mode"
            case .losingStreak: return "Losing Streak Check"
            }
        }

        var icon: String {
            switch self {
            case .preMarketAnalysis: return "sunrise.fill"
            case .morningWindow: return "clock.fill"
            case .lunchWindow: return "fork.knife"
            case .powerHourAnalysis: return "bolt.fill"
            case .institutionalFlowAlert: return "star.circle.fill"
            case .exitReminder: return "clock.badge.exclamationmark"
            case .postTradeAnalysis: return "checkmark.circle.fill"
            case .weeklyReview: return "calendar"
            case .monthlyReview: return "calendar.badge.clock"
            case .crisisMode: return "exclamationmark.triangle.fill"
            case .losingStreak: return "hand.raised.fill"
            }
        }

        var priority: Int {
            switch self {
            case .crisisMode: return 1               // Highest priority
            case .losingStreak: return 2
            case .institutionalFlowAlert: return 3   // 90% reliability window (Rating: 3)
            case .exitReminder: return 4             // Critical for discipline
            case .powerHourAnalysis: return 5
            case .morningWindow: return 6
            case .lunchWindow: return 7
            case .preMarketAnalysis: return 8
            case .postTradeAnalysis: return 9
            case .weeklyReview: return 10
            case .monthlyReview: return 11
            }
        }
    }

    enum PromptSchedule {
        case time(hour: Int, minute: Int)     // Fixed time daily
        case weekly(day: Int, hour: Int)      // Weekly on specific day
        case monthly(day: Int, hour: Int)     // Monthly on specific day
        case condition(Condition)             // Conditional trigger

        enum Condition {
            case vixAbove(Double)
            case losingStreakCount(Int)
            case tradingWindowApproaching(TimeWindow, minutes: Int)
        }

        enum TimeWindow {
            case morning, lunch, powerHour
        }
    }

    enum DataField {
        case vxxPrice
        case vixLevel
        case spyPrice
        case currentDate
        case currentTime
        case volumeVsAverage
        case vxxVsVWAP
        case sma20Position
        case sma50Position
        case supportLevel
        case resistanceLevel
        case tradesCount
        case winRate
        case dailyPnL
        case weeklyPnL
        case monthlyPnL

        var placeholder: String {
            "[INSERT]"
        }
    }

    // Generate prompt with live data filled in
    func generateWithLiveData(marketData: MarketData?, tradingStats: TradingStats?) -> String {
        var filledPrompt = template

        // Replace date/time placeholders
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        filledPrompt = filledPrompt.replacingOccurrences(of: "[DATE]", with: dateFormatter.string(from: Date()))
        filledPrompt = filledPrompt.replacingOccurrences(of: "[TIME]", with: timeFormatter.string(from: Date()))

        // Replace market data placeholders if available
        if let data = marketData {
            for field in dataFields {
                switch field {
                case .vxxPrice:
                    filledPrompt = filledPrompt.replacingOccurrences(of: "[VXX_PRICE]", with: String(format: "%.2f", data.currentPrice))
                case .vixLevel:
                    filledPrompt = filledPrompt.replacingOccurrences(of: "[VIX_LEVEL]", with: String(format: "%.2f", data.vix))
                case .spyPrice:
                    filledPrompt = filledPrompt.replacingOccurrences(of: "[SPY_PRICE]", with: String(format: "%.2f", data.spyDailyChange))
                case .volumeVsAverage:
                    let volumePct = (Double(data.volume) / Double(data.averageVolume)) * 100
                    filledPrompt = filledPrompt.replacingOccurrences(of: "[VOLUME_PCT]", with: String(format: "%.0f%%", volumePct))
                case .vxxVsVWAP:
                    let position = data.currentPrice > data.vwap ? "ABOVE" : "BELOW"
                    filledPrompt = filledPrompt.replacingOccurrences(of: "[VXX_VS_VWAP]", with: position)
                case .sma20Position, .sma50Position, .supportLevel, .resistanceLevel:
                    if let indicators = data.technicalIndicators {
                        switch field {
                        case .sma20Position:
                            let pos = indicators.isPriceAboveSMA20 ? "ABOVE" : "BELOW"
                            filledPrompt = filledPrompt.replacingOccurrences(of: "[SMA20_POS]", with: pos)
                        case .sma50Position:
                            let pos = indicators.isPriceAboveSMA50 ? "ABOVE" : "BELOW"
                            filledPrompt = filledPrompt.replacingOccurrences(of: "[SMA50_POS]", with: pos)
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
        }

        // Replace trading stats placeholders if available
        if let stats = tradingStats {
            filledPrompt = filledPrompt.replacingOccurrences(of: "[TRADES_COUNT]", with: "\(stats.totalTrades)")
            filledPrompt = filledPrompt.replacingOccurrences(of: "[WIN_RATE]", with: String(format: "%.1f%%", stats.winRate * 100))
            filledPrompt = filledPrompt.replacingOccurrences(of: "[DAILY_PNL]", with: String(format: "$%.2f", stats.dailyPnL))
            filledPrompt = filledPrompt.replacingOccurrences(of: "[WEEKLY_PNL]", with: String(format: "$%.2f", stats.weeklyPnL))
            filledPrompt = filledPrompt.replacingOccurrences(of: "[MONTHLY_PNL]", with: String(format: "$%.2f", stats.monthlyPnL))
        }

        return filledPrompt
    }
}

// MARK: - Trading Stats for Prompt Generation
struct TradingStats {
    let totalTrades: Int
    let wins: Int
    let losses: Int
    let dailyPnL: Double
    let weeklyPnL: Double
    let monthlyPnL: Double

    var winRate: Double {
        totalTrades > 0 ? Double(wins) / Double(totalTrades) : 0
    }

    var losingStreak: Int {
        // Calculate current losing streak
        0 // Would be calculated from trade history
    }
}

// MARK: - Prompt Library
class PromptLibrary {
    static let shared = PromptLibrary()

    // All trading prompts
    let prompts: [TradingPrompt] = [
        // Pre-Market Analysis (8:30-9:25 AM)
        TradingPrompt(
            type: .preMarketAnalysis,
            scheduledTime: .time(hour: 8, minute: 30),
            template: """
            I'm executing my systematic VXX trading approach. Today is [DATE].

            CURRENT DATA:
            - VXX pre-market price: $[VXX_PRICE]
            - VIX current level: $[VIX_LEVEL]
            - SPY futures: $[SPY_PRICE]
            - Major overnight news: [DESCRIBE]

            ANALYSIS NEEDED:
            1. Seasonal Context: How does [DATE] fit our seasonal VXX patterns?
            2. Overnight Action: VXX gap analysis and implications for morning fade strategy
            3. Market Structure: VIX futures curve status, contango strength assessment
            4. Economic Calendar: Risk assessment for scheduled releases today
            5. Technical Setup: Key levels, moving average positioning, pattern potential
            6. Options Environment: IV levels, institutional flow indicators

            WINDOW PROBABILITY ASSESSMENT:
            Rate each window (HIGH/MEDIUM/LOW/SKIP):
            - Morning Window (9:50-10:15 AM): 85% reliability
            - Lunch Window (12:20-12:40 PM): 70% reliability
            - Power Hour Window (3:10-3:25 PM): 80% reliability
            - Institutional Flow (3:45-4:10 PM): 90% reliability

            POSITION SIZING RECOMMENDATION:
            Based on current conditions and my systematic approach:
            - Recommended position size: [1 contract max]
            - Risk level for today: [GREEN/YELLOW/RED]

            EXECUTION PLAN:
            Provide specific entry criteria, volume thresholds (>200% required), and exit parameters for today's highest probability setup.
            """,
            dataFields: [.vxxPrice, .vixLevel, .spyPrice, .currentDate]
        ),

        // Morning Window (9:45 AM)
        TradingPrompt(
            type: .morningWindow,
            scheduledTime: .time(hour: 9, minute: 45),
            template: """
            Morning window assessment - 9:45 AM check:

            LIVE DATA:
            - VXX current: $[VXX_PRICE]
            - VIX current: [VIX_LEVEL]
            - VXX/VIX Ratio: [CALCULATE: VXX / VIX] (Need >1.45 minimum, >1.60 premium)
            - Volume vs average: [VOLUME_PCT]
            - VXX vs VWAP: [VXX_VS_VWAP]
            - 20 SMA: [SMA20_POS]
            - 50 SMA: [SMA50_POS]

            RATIO VALUE FILTER:
            - >1.60 = Premium fade (max position $500)
            - 1.55-1.60 = Strong fade ($450)
            - 1.45-1.55 = Normal fade ($350)
            - <1.45 = SKIP OR SMALL SIZE ONLY

            QUICK ASSESSMENT:
            1. Is the morning spike/weakness setting up for a fade?
            2. Volume confirmation present (>200% average)? Currently: [VOLUME_PCT]
            3. VXX/VIX Ratio check: Is VXX expensive enough (>1.45)?
            4. Technical pattern emerging (shooting star, doji, rejection)?
            5. Any news disruption in the last 30 minutes?

            GO/NO-GO DECISION:
            Give me clear entry criteria for the 9:50-10:15 AM window or recommend waiting for better setup.
            Remember: 85% reliability window, arrow signal + volume >200% + ratio >1.45 required.
            """,
            dataFields: [.vxxPrice, .vixLevel, .volumeVsAverage, .vxxVsVWAP, .sma20Position, .sma50Position]
        ),

        // Lunch Window (12:15 PM)
        TradingPrompt(
            type: .lunchWindow,
            scheduledTime: .time(hour: 12, minute: 15),
            template: """
            Lunch window assessment - 12:15 PM check:

            CURRENT STATUS:
            - VXX price: $[VXX_PRICE]
            - VIX level: [VIX_LEVEL]
            - VXX/VIX Ratio: [CALCULATE: VXX / VIX] (Need >1.45 to trade)
            - Morning trade result: [WIN/LOSS/NO TRADE]
            - Volume environment: [VOLUME_PCT]% of average
            - VXX vs VWAP: [VXX_VS_VWAP]

            LUNCH ANALYSIS:
            1. Is VXX showing typical lunch hour weakness/drift?
            2. Volume sufficient for reliable patterns (>150% average)? Currently: [VOLUME_PCT]
            3. VXX/VIX Ratio: Is fade worth taking (>1.45)?
            4. Any technical setups worth pursuing?
            5. Risk/reward favorable for smaller lunch scalp?

            RECOMMENDATION:
            Should I take the 12:20-12:40 PM window (70% reliability) or preserve capital for power hour (80% reliability)?
            """,
            dataFields: [.vxxPrice, .vixLevel, .volumeVsAverage, .vxxVsVWAP]
        ),

        // Power Hour Analysis (3:05 PM)
        TradingPrompt(
            type: .powerHourAnalysis,
            scheduledTime: .time(hour: 15, minute: 5),
            template: """
            Ready for VXX trading power hour window (3:10-3:25 PM).

            CURRENT SETUP:
            Date: [DATE]
            Time: 3:05 PM
            Strategy: VXX systematic approach

            MY CHART INDICATORS:
            - VXX 5-minute chart with:
              - 20 SMA (yellow line) - short-term trend: [SMA20_POS]
              - 50 SMA (orange line) - medium-term trend: [SMA50_POS]
              - VWAP (cyan line) - daily institutional bias: [VXX_VS_VWAP]
              - Volume vs 30-period average: [VOLUME_PCT]%

            CURRENT LEVELS:
            - VXX current price: $[VXX_PRICE]
            - VIX current level: $[VIX_LEVEL]
            - VXX/VIX Ratio: [CALCULATE: VXX / VIX]
            - Current volume vs average: [VOLUME_PCT]%

            VXX/VIX RATIO ASSESSMENT:
            - >1.60 = Premium fade (max position $500)
            - 1.55-1.60 = Strong fade ($450)
            - 1.45-1.55 = Normal fade ($350)
            - <1.45 = SKIP (VXX too cheap)

            PLEASE ANALYZE:
            1. ENTRY SIGNAL ASSESSMENT: Do I have a clear VXX pattern? Volume confirmation? SMA positioning?
            2. RATIO VALUE CHECK: Is VXX expensive enough to fade (>1.45)? What position size?
            3. MARKET CONTEXT CHECK: SPY stability? VIX behavior supporting thesis? Late-day news?
            4. RISK/REWARD ANALYSIS: Success probability? Entry levels? Profit targets and stops?
            5. EXECUTION DECISION: Clear GO/NO-GO with specific entry price, volume threshold, targets, stops, exit deadline (3:55 PM max)

            MY ENTRY CHECKLIST (confirm all are met):
            - [ ] Correct time window (3:10-3:25 PM)
            - [ ] Clear technical pattern or arrow signal
            - [ ] Volume >200% average (Currently: [VOLUME_PCT]%)
            - [ ] VXX/VIX Ratio >1.45 (Value filter)
            - [ ] No major news disruption
            - [ ] Market context supportive

            NOTE: 3:45-4:10 PM Institutional Flow Window coming up (90% reliability, 300%+ volume required)

            Help me make a disciplined, systematic decision based on our established strategy and current market conditions.
            """,
            dataFields: [.vxxPrice, .vixLevel, .volumeVsAverage, .vxxVsVWAP, .sma20Position, .sma50Position, .currentDate]
        ),

        // Institutional Flow Alert (3:40 PM) (Rating: 3)
        TradingPrompt(
            type: .institutionalFlowAlert,
            scheduledTime: .time(hour: 15, minute: 40),
            template: """
            --- INSTITUTIONAL FLOW WINDOW IN 5 MINUTES ---
            3:45-4:10 PM | 90% RELIABILITY | SUPREME SETUP

            This is your highest probability window. Portfolio rebalancing. Mutual fund NAV. Index rebalancing. Real institutional money flows.

            CURRENT DATA:
            - VXX: $[VXX_PRICE]
            - VIX: [VIX_LEVEL]
            - VXX/VIX Ratio: [CALCULATE: VXX / VIX]
            - Current volume: [VOLUME_PCT]%

            INSTITUTIONAL FLOW CRITERIA (ALL REQUIRED):
            [ ] Time: 3:45-4:10 PM window (5 minutes away)
            [ ] Volume: >300% average (institutional threshold)
            [ ] VXX/VIX Ratio: >1.45 (minimum), >1.60 (premium)
            [ ] Arrow signal or clean technical setup
            [ ] Direction conviction (institutions are decisive)

            WHAT TO WATCH FOR:
            1. Volume explosion at 3:45 PM (>300% = institutional money)
            2. Clean directional move (institutions don't hesitate)
            3. Moving average confirmation
            4. Ratio in fade zone (>1.45)

            POSITION SIZING FOR THIS WINDOW:
            - Ratio >1.60 + Volume >300% = MAX position ($500)
            - Ratio 1.55-1.60 + Volume >300% = Full position ($450)
            - Ratio 1.45-1.55 + Volume >300% = Standard ($350)
            - Ratio <1.45 = SKIP (institutions may be covering)

            IF ALREADY IN POWER HOUR POSITION:
            - Ratio >1.55 + Volume >300% at 3:45 = HOLD to 4:05 PM
            - Ratio <1.50 or volume fading = EXIT NOW
            - Hit profit target = TAKE IT

            EXIT DISCIPLINE:
            - If entering 3:45-4:00 PM: Exit by 4:05 PM MAX
            - If holding from earlier: Exit by 3:55 PM (use exit reminder)
            - NO OVERNIGHT HOLDS (non-negotiable)

            ACTION PLAN:
            1. Update VXX/VIX/Volume data at 3:44 PM
            2. Check ratio tier and volume threshold
            3. Watch for institutional volume surge at 3:45 PM
            4. Execute ONLY if ALL criteria met
            5. Set 4:05 PM hard exit if entering

            This window = Join institutional money. Don't fade it. Flow with it.

            Ready to execute?
            """,
            dataFields: [.vxxPrice, .vixLevel, .volumeVsAverage]
        ),

        // Exit Reminder (3:50 PM)
        TradingPrompt(
            type: .exitReminder,
            scheduledTime: .time(hour: 15, minute: 50),
            template: """
            --- EXIT TIME REMINDER ---

            5 MINUTES TO HARD EXIT (3:55 PM)

            Current positions: [DESCRIBE OR "NONE"]

            DISCIPLINE CHECKPOINT:
            [ ] 3:55 PM = EXIT ALL POSITIONS (unless institutional flow window)
            [ ] No "just 5 more minutes"
            [ ] No "I'll see what happens at close"
            [ ] No overnight holds under ANY circumstances

            EXCEPTION:
            If you entered during 3:45-4:00 PM institutional flow window:
            - You have until 4:05 PM MAX
            - Set alarm for 4:00 PM (5-minute warning)
            - Exit by 4:05 PM sharp

            WHY 3:55 PM EXIT IS SACRED:
            1. Prevents emotional attachment
            2. Prevents "hope trading"
            3. Preserves capital for tomorrow
            4. System integrity depends on it

            IF YOU'RE WINNING:
            - Take the profit, don't get greedy
            - Tomorrow has more setups

            IF YOU'RE LOSING:
            - Take the loss, preserve capital
            - System works over 20+ trades, not 1

            IF YOU'RE BREAKING EVEN:
            - Close it, no drama
            - Clean slate for tomorrow

            Set your exit order NOW if you haven't already.

            3:55 PM = Hard exit. No exceptions.
            """,
            dataFields: []
        ),

        // Post-Trade Analysis (3:55 PM)
        TradingPrompt(
            type: .postTradeAnalysis,
            scheduledTime: .time(hour: 15, minute: 55),
            template: """
            Daily trading wrap-up and analysis for [DATE]:

            TRADE SUMMARY:
            - Number of trades taken: [TRADES_COUNT]
            - Win/Loss record: [INSERT MANUALLY]
            - Total P&L: [DAILY_PNL]
            - Best trade: [DESCRIBE]
            - Worst trade: [DESCRIBE]

            EXECUTION ANALYSIS:
            1. Rules Adherence: Did I follow my systematic approach? Any deviations?
            2. Entry Quality: Were my entries based on proper criteria? Volume confirmation >200%?
            3. Exit Discipline: Did I take profits/losses at predetermined levels?
            4. Emotional State: How did I feel during trades? Any stress or euphoria?
            5. Pattern Recognition: Which setups worked best? Any failing patterns?

            ARROW SIGNAL TRACKING:
            - Which arrow signals worked best?
            - Volume confirmation accuracy rate
            - Time window performance review
            - Moving average cross success rate

            MARKET LESSONS:
            What did today teach me about:
            - VXX behavior in current conditions
            - Volume patterns and reliability
            - Technical indicator effectiveness
            - Institutional flow window (if traded)

            TOMORROW'S PREPARATION:
            Based on today's results:
            1. Position sizing adjustment needed?
            2. Focus areas for improvement?
            3. Pattern recognition refinements?
            4. Risk management updates?

            Help me extract maximum learning value from today's trading to improve tomorrow's execution.
            """,
            dataFields: [.currentDate, .tradesCount, .dailyPnL]
        ),

        // Crisis Mode (VIX >30)
        TradingPrompt(
            type: .crisisMode,
            scheduledTime: .condition(.vixAbove(30)),
            template: """
            EMERGENCY: VIX spike above 30 - Crisis mode assessment needed:

            CURRENT SITUATION:
            - VIX level: [VIX_LEVEL]
            - VXX price: $[VXX_PRICE]
            - Current positions: [DESCRIBE]
            - Market context: [DESCRIBE CRISIS]

            IMMEDIATE ACTIONS NEEDED:
            1. Should I close all positions immediately?
            2. What's the risk of holding through this volatility spike?
            3. When should I consider re-entering the market?
            4. Capital preservation priorities?

            Provide crisis management guidance focused on capital preservation over profit maximization.
            """,
            dataFields: [.vixLevel, .vxxPrice]
        ),

        // Losing Streak (3+ losses)
        TradingPrompt(
            type: .losingStreak,
            scheduledTime: .condition(.losingStreakCount(3)),
            template: """
            System check - experiencing losing streak:

            RECENT PERFORMANCE:
            - Last [X] trades: [Results]
            - Current drawdown: [X%]
            - Rule violations: [DESCRIBE ANY]
            - Emotional state: [DESCRIBE]

            DIAGNOSTIC ANALYSIS:
            1. Are losses due to system failure or normal variance?
            2. Have I been following all rules properly?
            3. Has the market regime changed?
            4. Should I reduce position sizes or pause trading?

            Help me determine if this is normal drawdown or system breakdown, with specific recovery recommendations.
            """,
            dataFields: [.tradesCount, .winRate]
        )
    ]

    // Get prompt for current time
    func getScheduledPrompt(for date: Date = Date()) -> TradingPrompt? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        return prompts.first { prompt in
            switch prompt.scheduledTime {
            case .time(let schedHour, let schedMinute):
                return hour == schedHour && abs(minute - schedMinute) <= 5 // 5-minute window
            default:
                return false
            }
        }
    }

    // Get all prompts for today
    func getTodayPrompts() -> [TradingPrompt] {
        prompts.filter { prompt in
            switch prompt.scheduledTime {
            case .time:
                return true
            default:
                return false
            }
        }.sorted { $0.type.priority < $1.type.priority }
    }

    // Check for conditional prompts
    func checkConditionalPrompts(vix: Double, losingStreak: Int) -> [TradingPrompt] {
        var triggered: [TradingPrompt] = []

        for prompt in prompts {
            switch prompt.scheduledTime {
            case .condition(let condition):
                switch condition {
                case .vixAbove(let threshold):
                    if vix > threshold {
                        triggered.append(prompt)
                    }
                case .losingStreakCount(let count):
                    if losingStreak >= count {
                        triggered.append(prompt)
                    }
                default:
                    break
                }
            default:
                break
            }
        }

        return triggered.sorted { $0.type.priority < $1.type.priority }
    }
}
