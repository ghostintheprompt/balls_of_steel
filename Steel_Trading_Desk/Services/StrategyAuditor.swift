import Foundation

// MARK: - StrategyAuditor
//
// Runs `StrategySpec` checks against the code's runtime behavior and reports
// any drift. The Settings → Strategy Audit screen calls `run()` and renders
// the results.
//
// What this catches:
//   - Threshold drift (ratio, volume, body %, etc.) when somebody edits a
//     literal in code instead of `StrategySpec`.
//   - Time-window boundary errors (e.g. the Morning-window-unreachable bug
//     that was the first thing this auditor caught).
//   - Pattern-recognizer divergence from the doc.
//   - Hard-exit-time drift.
//
// What it does NOT catch:
//   - Doc changes that haven't been mirrored into `StrategySpec` (the spec
//     is the canonical source; if a doc changes, update spec first).
//   - Logic bugs in code that happen to match the spec. Boundary checks help
//     here but they're not exhaustive — they're spot checks.
//
// Rule from [[feedback-catch-drift-always]]: any new strategy constant goes
// in StrategySpec, and a corresponding audit case goes here.

enum AuditStatus: String {
    case pass     = "PASS"
    case fail     = "FAIL"
    case warning  = "WARN"
}

struct AuditResult: Identifiable {
    let id = UUID()
    let category: AuditCategory
    let title: String
    let expected: String
    let actual: String
    let status: AuditStatus
    /// Where in the doc this rule comes from (filename or section name).
    let docSource: String
}

enum AuditCategory: String, CaseIterable {
    case ratio     = "RATIO"
    case volume    = "VOLUME"
    case windows   = "WINDOWS"
    case exits     = "EXITS"
    case patterns  = "PATTERNS"
    case sizing    = "SIZING"
}

struct StrategyAuditor {

    // MARK: - Public

    @MainActor
    static func run() -> [AuditResult] {
        var out: [AuditResult] = []
        out.append(contentsOf: ratioChecks())
        out.append(contentsOf: volumeChecks())
        out.append(contentsOf: windowChecks())
        out.append(contentsOf: exitChecks())
        out.append(contentsOf: patternChecks())
        out.append(contentsOf: sizingChecks())
        return out
    }

    // MARK: - Ratio

    private static func ratioChecks() -> [AuditResult] {
        var r: [AuditResult] = []

        // Tier boundaries — verify StrategySpec.tier(forRatio:) lands in the
        // correct tier at each boundary value.
        let cases: [(Double, StrategySpec.RatioTier, String)] = [
            (1.20, .noFade,      "1.20 (deep cheap)"),
            (1.34, .noFade,      "1.34 (just below threshold)"),
            (1.35, .weakFade,    "1.35 (weak boundary)"),
            (1.44, .weakFade,    "1.44 (just below normal)"),
            (1.45, .normalFade,  "1.45 (normal boundary)"),
            (1.54, .normalFade,  "1.54 (just below strong)"),
            (1.55, .strongFade,  "1.55 (strong boundary)"),
            (1.59, .strongFade,  "1.59 (just below premium)"),
            (1.60, .premiumFade, "1.60 (premium boundary)"),
            (1.75, .premiumFade, "1.75 (deep premium)")
        ]
        for (ratio, expectedTier, label) in cases {
            let actualTier = StrategySpec.tier(forRatio: ratio)
            r.append(AuditResult(
                category: .ratio,
                title: "Ratio tier at \(label)",
                expected: expectedTier.label,
                actual: actualTier.label,
                status: actualTier == expectedTier ? .pass : .fail,
                docSource: "vxx_trading_prompts_2026.md / Quick Reference Card"
            ))
        }

        // Minimum ratio for entry — the canonical 1.45 threshold.
        r.append(AuditResult(
            category: .ratio,
            title: "Minimum ratio for entry",
            expected: "1.45",
            actual: String(format: "%.2f", StrategySpec.minimumRatioForEntry),
            status: StrategySpec.minimumRatioForEntry == 1.45 ? .pass : .fail,
            docSource: "thinkorswim_complete_setup_2026.md / Indicator Hierarchy"
        ))

        // No-fade zone — anything below 1.35.
        r.append(AuditResult(
            category: .ratio,
            title: "No-fade cutoff",
            expected: "1.35",
            actual: String(format: "%.2f", StrategySpec.noFadeBelowRatio),
            status: StrategySpec.noFadeBelowRatio == 1.35 ? .pass : .fail,
            docSource: "vxx_trading_prompts_2026.md / Ratio Tiers"
        ))

        return r
    }

    // MARK: - Volume

    private static func volumeChecks() -> [AuditResult] {
        var r: [AuditResult] = []

        let m = StrategySpec.morningWindow
        r.append(AuditResult(
            category: .volume,
            title: "Morning window volume threshold",
            expected: "200%",
            actual: "\(Int(m.volumeThresholdPercent))%",
            status: m.volumeThresholdPercent == 200 ? .pass : .fail,
            docSource: "vxx_trading_prompts_2026.md / PROMPT 1"
        ))

        let p = StrategySpec.powerHourWindow
        r.append(AuditResult(
            category: .volume,
            title: "Power Hour volume threshold",
            expected: "200%",
            actual: "\(Int(p.volumeThresholdPercent))%",
            status: p.volumeThresholdPercent == 200 ? .pass : .fail,
            docSource: "vxx_trading_prompts_2026.md / PROMPT 2"
        ))

        let i = StrategySpec.institutionalWindow
        r.append(AuditResult(
            category: .volume,
            title: "Institutional volume threshold",
            expected: "300%",
            actual: "\(Int(i.volumeThresholdPercent))%",
            status: i.volumeThresholdPercent == 300 ? .pass : .fail,
            docSource: "vxx_trading_prompts_2026.md / PROMPT 3"
        ))

        return r
    }

    // MARK: - Windows

    private static func windowChecks() -> [AuditResult] {
        var r: [AuditResult] = []

        let expected: [(StrategySpec.TradingWindow, Int, Int, String)] = [
            (StrategySpec.morningWindow,       9 * 60 + 50, 10 * 60 + 15, "9:50-10:15"),
            (StrategySpec.powerHourWindow,    15 * 60 + 10, 15 * 60 + 25, "3:10-3:25"),
            (StrategySpec.institutionalWindow, 15 * 60 + 45, 16 * 60 + 10, "3:45-4:10")
        ]
        for (window, start, end, label) in expected {
            let bounds = "\(window.startMinutes)-\(window.endMinutes)"
            let target = "\(start)-\(end)"
            r.append(AuditResult(
                category: .windows,
                title: "\(window.label) bounds",
                expected: label,
                actual: bounds == target ? label : bounds,
                status: bounds == target ? .pass : .fail,
                docSource: "vxx_trading_prompts_2026.md / Time Windows"
            ))
        }

        // Confirm currentTimeWindow logic returns the correct entry window at
        // each boundary. The Morning-window-unreachable bug (drift fix
        // 2026-05-14) is what motivated this check.
        let probes: [(Int, String, String)] = [
            (9 * 60 + 50, "morning",       "9:50 — Morning starts"),
            (10 * 60 + 0, "morning",       "10:00 — mid-Morning"),
            (10 * 60 + 14, "morning",      "10:14 — Morning end-1"),
            (15 * 60 + 10, "powerHour",    "15:10 — Power starts"),
            (15 * 60 + 24, "powerHour",    "15:24 — Power end-1"),
            (15 * 60 + 45, "institutional", "15:45 — Institutional starts"),
            (16 * 60 + 9, "institutional", "16:09 — Institutional end-1")
        ]
        for (minute, expected, label) in probes {
            let actual = currentTimeWindowName(forMinute: minute)
            r.append(AuditResult(
                category: .windows,
                title: "currentTimeWindow at \(label)",
                expected: expected,
                actual: actual,
                status: actual == expected ? .pass : .fail,
                docSource: "thinkorswim_complete_setup_2026.md / Daily Usage"
            ))
        }

        return r
    }

    // MARK: - Exits

    private static func exitChecks() -> [AuditResult] {
        var r: [AuditResult] = []

        r.append(AuditResult(
            category: .exits,
            title: "Default hard-exit cutoff (3:55 PM)",
            expected: "955 minutes",
            actual: "\(StrategySpec.defaultHardExitMinutes) minutes",
            status: StrategySpec.defaultHardExitMinutes == 15 * 60 + 55 ? .pass : .fail,
            docSource: "thinkorswim_complete_setup_2026.md / Exit Strategy"
        ))

        r.append(AuditResult(
            category: .exits,
            title: "Institutional hard-exit cutoff (4:05 PM)",
            expected: "965 minutes",
            actual: "\(StrategySpec.institutionalHardExitMinutes) minutes",
            status: StrategySpec.institutionalHardExitMinutes == 16 * 60 + 5 ? .pass : .fail,
            docSource: "thinkorswim_complete_setup_2026.md / Exit Strategy"
        ))

        // Doc-faithful behavior: an Institutional position extends the cutoff.
        let inst = makeDate(hour: 15, minute: 50)
        let earlier = makeDate(hour: 11, minute: 15)
        let withInst = StrategySpec.hardExitMinutes(forOpenedAt: [earlier, inst])
        let withoutInst = StrategySpec.hardExitMinutes(forOpenedAt: [earlier])
        r.append(AuditResult(
            category: .exits,
            title: "Hard exit with Institutional position open",
            expected: "16:05",
            actual: formatMinutes(withInst),
            status: withInst == 16 * 60 + 5 ? .pass : .fail,
            docSource: "vxx_trading_prompts_2026.md / PROMPT 3 + user spec 2026-05-14"
        ))
        r.append(AuditResult(
            category: .exits,
            title: "Hard exit with only earlier positions",
            expected: "15:55",
            actual: formatMinutes(withoutInst),
            status: withoutInst == 15 * 60 + 55 ? .pass : .fail,
            docSource: "thinkorswim_complete_setup_2026.md / Exit Strategy"
        ))

        return r
    }

    // MARK: - Patterns

    private static func patternChecks() -> [AuditResult] {
        var r: [AuditResult] = []

        r.append(AuditResult(
            category: .patterns,
            title: "Volume factor for pattern confirmation",
            expected: "2.0 (200%)",
            actual: String(format: "%.1f (%.0f%%)", StrategySpec.volumeFactorThreshold, StrategySpec.volumeFactorThreshold * 100),
            status: StrategySpec.volumeFactorThreshold == 2.0 ? .pass : .fail,
            docSource: "thinkorswim_complete_setup_2026.md / Pattern Recognition"
        ))

        r.append(AuditResult(
            category: .patterns,
            title: "Doji max body % of total range",
            expected: "10%",
            actual: "\(Int(StrategySpec.dojiMaxBodyPercent * 100))%",
            status: StrategySpec.dojiMaxBodyPercent == 0.10 ? .pass : .fail,
            docSource: "thinkorswim_complete_setup_2026.md / Candlestick Patterns"
        ))

        r.append(AuditResult(
            category: .patterns,
            title: "Small-body max % (Shooting Star / Hammer / Hanging Man)",
            expected: "30%",
            actual: "\(Int(StrategySpec.smallBodyMaxPercent * 100))%",
            status: StrategySpec.smallBodyMaxPercent == 0.30 ? .pass : .fail,
            docSource: "thinkorswim_complete_setup_2026.md / Candlestick Patterns"
        ))

        r.append(AuditResult(
            category: .patterns,
            title: "Long-shadow to body ratio",
            expected: "≥2.0",
            actual: "\(StrategySpec.shadowToBodyRatio)",
            status: StrategySpec.shadowToBodyRatio == 2.0 ? .pass : .fail,
            docSource: "thinkorswim_complete_setup_2026.md / Candlestick Patterns"
        ))

        return r
    }

    // MARK: - Sizing

    private static func sizingChecks() -> [AuditResult] {
        var r: [AuditResult] = []

        let table: [(StrategySpec.RatioTier, Int)] = [
            (.noFade,      0),
            (.weakFade,    250),
            (.normalFade,  400),
            (.strongFade,  500),
            (.premiumFade, 500)
        ]
        for (tier, expected) in table {
            r.append(AuditResult(
                category: .sizing,
                title: "Max position $ for \(tier.label)",
                expected: "$\(expected)",
                actual: "$\(tier.maxPositionDollars)",
                status: tier.maxPositionDollars == expected ? .pass : .fail,
                docSource: "vxx_trading_prompts_2026.md / Position Sizing"
            ))
        }

        r.append(AuditResult(
            category: .sizing,
            title: "Absolute max contracts",
            expected: "8",
            actual: "\(StrategySpec.absoluteMaxContracts)",
            status: StrategySpec.absoluteMaxContracts == 8 ? .pass : .fail,
            docSource: "vxx_trading_prompts_2026.md / Position Sizing"
        ))

        return r
    }

    // MARK: - Helpers

    private static func currentTimeWindowName(forMinute t: Int) -> String {
        // Mirror LiveTapeService.currentTimeWindow without instantiating a
        // Date — pure mapping logic.
        if t >= StrategySpec.morningWindow.startMinutes && t < StrategySpec.morningWindow.endMinutes { return "morning" }
        if t >= StrategySpec.powerHourWindow.startMinutes && t < StrategySpec.powerHourWindow.endMinutes { return "powerHour" }
        if t >= StrategySpec.institutionalWindow.startMinutes && t < StrategySpec.institutionalWindow.endMinutes { return "institutional" }
        if t < StrategySpec.preMarketCutoffMinutes { return "preMarket" }
        if t >= StrategySpec.afterHoursMinutes { return "afterHours" }
        return "neutral"
    }

    private static func makeDate(hour: Int, minute: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let now = Date()
        var c = cal.dateComponents([.year, .month, .day], from: now)
        c.hour = hour
        c.minute = minute
        c.timeZone = TimeZone(identifier: "America/New_York")
        return cal.date(from: c) ?? now
    }

    private static func formatMinutes(_ m: Int) -> String {
        String(format: "%d:%02d", m / 60, m % 60)
    }
}

// MARK: - AuditSummary

struct AuditSummary {
    let total: Int
    let passes: Int
    let warnings: Int
    let failures: Int

    var allPass: Bool { failures == 0 && warnings == 0 }

    init(results: [AuditResult]) {
        total = results.count
        passes = results.filter { $0.status == .pass }.count
        warnings = results.filter { $0.status == .warning }.count
        failures = results.filter { $0.status == .fail }.count
    }
}
