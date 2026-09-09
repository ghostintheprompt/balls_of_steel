import Foundation

// MARK: - StrategySpec
//
// Single source of truth for every threshold, time bound, and rule in the VXX
// strategy. Mirrors `docs/trading docs/` (thinkorswim_complete_setup_2026.md +
// vxx_trading_prompts_2026.md + vxx_trading_philosophy_discipline.md). The
// code references these constants; the in-app Strategy Audit (Settings →
// Strategy Audit) verifies runtime behavior matches them.
//
// When the docs change, update this file FIRST, then run the audit to see
// what code needs to follow. Never edit a magic number elsewhere in the code
// without updating the spec.
//
// Rule from user (2026-05-14): catch drift always. See
// memory/feedback_catch_drift_always.md.

enum StrategySpec {

    // MARK: - VXX/VIX Ratio Tiers
    //
    // From the strategy prompts doc:
    //   >1.60 = PREMIUM FADE   (max position $500)
    //   1.55-1.60 = STRONG     ($400-500)
    //   1.45-1.55 = NORMAL     ($300-400)
    //   1.35-1.45 = WEAK       ($150-250 or skip)
    //   <1.35 = NO FADE        (skip puts entirely)
    enum RatioTier: String, CaseIterable {
        case noFade, weakFade, normalFade, strongFade, premiumFade

        var lowerBound: Double {
            switch self {
            case .noFade:      return -.infinity
            case .weakFade:    return 1.35
            case .normalFade:  return 1.45
            case .strongFade:  return 1.55
            case .premiumFade: return 1.60
            }
        }

        var label: String {
            switch self {
            case .noFade:      return "NO FADE"
            case .weakFade:    return "WEAK FADE"
            case .normalFade:  return "NORMAL FADE"
            case .strongFade:  return "STRONG FADE"
            case .premiumFade: return "PREMIUM FADE"
            }
        }

        /// Max dollar risk per the doc's position-sizing table.
        var maxPositionDollars: Int {
            switch self {
            case .noFade:      return 0
            case .weakFade:    return 250
            case .normalFade:  return 400
            case .strongFade:  return 500
            case .premiumFade: return 500
            }
        }
    }

    static let minimumRatioForEntry: Double = 1.45
    static let noFadeBelowRatio: Double = 1.35
    static let absoluteMaxPositionDollars: Int = 500
    static let absoluteMaxContracts: Int = 8

    static func tier(forRatio ratio: Double) -> RatioTier {
        if ratio >= 1.60 { return .premiumFade }
        if ratio >= 1.55 { return .strongFade }
        if ratio >= 1.45 { return .normalFade }
        if ratio >= 1.35 { return .weakFade }
        return .noFade
    }

    // MARK: - Trading Windows (ET clock)
    //
    // From the prompts doc:
    //   Morning Fade        9:50-10:15 AM
    //   Power Hour          3:10-3:25 PM
    //   Institutional Flow  3:45-4:10 PM
    // The Institutional window is the high-conviction late-flow swing. The
    // quote/alert session remains active until the 4:15 PM ET extended close.
    struct TradingWindow {
        let id: String
        let label: String
        let shortLabel: String
        let startMinutes: Int        // since midnight ET
        let endMinutes: Int          // since midnight ET (exclusive)
        let volumeThresholdPercent: Double
        let publishedReliabilityPercent: Int?   // nil = doc doesn't quantify
        let isEntryWindow: Bool

        /// Latest minute (since midnight ET) for the quote/alert session close
        /// tied to this window. Nil = no special session extension.
        let hardExitMinutes: Int?

        /// Fraction of the ratio tier's `maxPositionDollars` this window is
        /// allowed to size up to. 1.0 = full size (the three proven anchor
        /// windows). Anything less than 1.0 is a real cap, not a suggestion --
        /// see the 2026-09-09 hardening note below.
        let positionSizeMultiplier: Double
    }

    static let morningWindow = TradingWindow(
        id: "morning",
        label: "Morning Fade (9:50-10:15)",
        shortLabel: "MORN",
        startMinutes: 9 * 60 + 50,     // 9:50 AM ET
        endMinutes: 10 * 60 + 15,      // 10:15 AM ET
        volumeThresholdPercent: 200,
        publishedReliabilityPercent: 85,
        isEntryWindow: true,
        hardExitMinutes: 16 * 60 + 15, // 4:15 PM ET extended-session close
        positionSizeMultiplier: 1.0
    )

    static let powerHourWindow = TradingWindow(
        id: "powerHour",
        label: "Power Hour (3:10-3:25)",
        shortLabel: "POWER",
        startMinutes: 15 * 60 + 10,    // 3:10 PM ET
        endMinutes: 15 * 60 + 25,      // 3:25 PM ET
        volumeThresholdPercent: 200,
        publishedReliabilityPercent: 80,
        isEntryWindow: true,
        hardExitMinutes: 16 * 60 + 15, // 4:15 PM ET extended-session close
        positionSizeMultiplier: 1.0
    )

    static let institutionalWindow = TradingWindow(
        id: "institutional",
        label: "Institutional Flow (3:45-4:10)",
        shortLabel: "INST",
        startMinutes: 15 * 60 + 45,    // 3:45 PM ET
        endMinutes: 16 * 60 + 10,      // 4:10 PM ET
        volumeThresholdPercent: 300,   // doc: ≥300% for Institutional
        publishedReliabilityPercent: 90,
        isEntryWindow: true,
        hardExitMinutes: 16 * 60 + 15, // 4:15 PM ET extended-session close
        positionSizeMultiplier: 1.0
    )

    /// Added 2026-09-09 alongside `offAnchorWindow` (below) -- these two are
    /// what makes the 2026-09-08 "off-anchor windows are alertable, not
    /// blocked" call actually hold a real position-sizing line, not just a
    /// harder volume bar. Reliability numbers are `vxx_trading_philosophy_
    /// discipline.md`'s own published table (lines 282-320) -- Lunch Drift
    /// 70%, previously not mirrored in code at all. Multiplier is Michael's
    /// call, not a doc number: half size for a documented-but-choppy window.
    static let lunchWindow = TradingWindow(
        id: "lunch",
        label: "Lunch Drift (12:20-12:40)",
        shortLabel: "LUNCH",
        startMinutes: 12 * 60 + 20,    // 12:20 PM ET
        endMinutes: 12 * 60 + 40,      // 12:40 PM ET
        volumeThresholdPercent: 300,   // off-anchor bar, same as Institutional
        publishedReliabilityPercent: 70,
        isEntryWindow: true,
        hardExitMinutes: 16 * 60 + 15,
        positionSizeMultiplier: 0.5
    )

    /// Catch-all for every other open-market minute (`.open`, `.afternoonFlex`,
    /// `.close` in `TimeWindowInput`) -- the doc's own "All Other Times: 50%
    /// reliability, don't trade" bucket. The 2026-09-08 call made this
    /// alertable instead of hard-blocked (a real ~2% move got missed for
    /// being 20 minutes outside Power Hour); this multiplier is the other
    /// half of that tradeoff -- alertable, but capped well under full size.
    /// Sanity-check 0.35 against how it actually trades; it's a judgment
    /// call, not a doc number.
    static let offAnchorWindow = TradingWindow(
        id: "offAnchor",
        label: "Outside Optimal Window",
        shortLabel: "OFF-PEAK",
        startMinutes: 0,
        endMinutes: 0,                 // not a contiguous range -- see LiveTapeService.currentTimeWindow()
        volumeThresholdPercent: 300,
        publishedReliabilityPercent: 50,
        isEntryWindow: true,
        hardExitMinutes: 16 * 60 + 15,
        positionSizeMultiplier: 0.35
    )

    static let allEntryWindows: [TradingWindow] = [
        morningWindow,
        powerHourWindow,
        institutionalWindow,
        lunchWindow,
        offAnchorWindow
    ]

    /// Volume bar required to clear the criteria-1 (volume) gate, expressed as
    /// a percent of the 30-period average. Window-dependent per the doc:
    /// Morning + Power → 200%, Institutional → 300%.
    static func volumeThresholdPercent(forTimeWindowID id: String) -> Double {
        allEntryWindows.first(where: { $0.id == id })?.volumeThresholdPercent
            ?? morningWindow.volumeThresholdPercent
    }

    // MARK: - Session close times
    //
    // Quotes/alerts remain active through the extended 4:15 PM ET close.
    // Legacy cutoff names remain internal for older call sites, but the
    // user-facing language should describe session close, not a strategy stop.

    static let extendedSessionCloseMinutes: Int = 16 * 60 + 15 // 4:15 PM
    static let sessionCloseWarningMinutes: Int = extendedSessionCloseMinutes - 5
    static let defaultHardExitMinutes: Int = extendedSessionCloseMinutes
    static let institutionalHardExitMinutes: Int = extendedSessionCloseMinutes
    static let afterHoursMinutes: Int = extendedSessionCloseMinutes
    static let preMarketCutoffMinutes: Int = 9 * 60 + 30    // 9:30 AM

    /// Was a trade opened in (or after the start of) the Institutional window?
    static func wasOpenedInInstitutionalWindow(_ openedAt: Date) -> Bool {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: TimeZone(identifier: "America/New_York")!, from: openedAt)
        let h = comps.hour ?? 0
        let m = comps.minute ?? 0
        return (h * 60 + m) >= institutionalWindow.startMinutes
    }

    /// Effective session close (in ET minutes) given tracked timestamps.
    /// Older call sites still use the legacy cutoff method name, but all paths now
    /// resolve to the 4:15 PM ET extended close.
    static func hardExitMinutes(forOpenedAt timestamps: [Date]) -> Int {
        timestamps.contains(where: wasOpenedInInstitutionalWindow)
            ? institutionalHardExitMinutes
            : defaultHardExitMinutes
    }

    // MARK: - Pattern criteria (ToS / CandlestickPattern.swift)
    //
    // Doc values mirrored here so the auditor can confirm PatternRecognizer
    // hasn't drifted. Heuristics not in the doc are excluded — see
    // memory/feedback_catch_drift_always.md.

    static let volumeFactorThreshold: Double = 2.0   // 200% of 30-period avg
    static let dojiMaxBodyPercent: Double = 0.10
    static let smallBodyMaxPercent: Double = 0.30    // Shooting Star / Hammer / Hanging Man
    static let shadowToBodyRatio: Double = 2.0       // long shadow ≥ 2× body
    static let oppositeShadowMaxPercent: Double = 0.10 // short opposite shadow

    // MARK: - 5-criteria gate weights (display only)
    //
    // The strategy treats all 5 as MANDATORY; weights are for the doc's
    // "pilot checklist" explanation and don't relax the all-required rule.
    static let volumeWeight: Double = 0.30
    static let timeWindowWeight: Double = 0.25
    static let ratioWeight: Double = 0.25
    static let keyLevelWeight: Double = 0.15
    static let patternWeight: Double = 0.05

    // MARK: - Exit thresholds
    static let profitTargetPercent: Double = 30      // first scale at 30%, full at 50%
    static let profitFullExitPercent: Double = 50
    static let stopLossPercent: Double = 50

    // MARK: - Circuit breakers (philosophy doc)
    static let consecutiveLossesCutoff: Int = 2
    static let vixPauseLevel: Double = 25
    static let vixCrisisLevel: Double = 30
    static let weeklyDrawdownReviewDollars: Int = 500
}
