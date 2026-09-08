import Foundation

// MARK: - StrategyAuditor
//
// Runs `StrategySpec` checks against the code's runtime behavior and reports
// any drift. The Settings → Strategy Audit screen calls `run()` and renders
// the results.
//
// What this catches:
//   - LIVE PROOF (added 2026-09-08): is the feed actually ticking right now,
//     is "today's" candle actually today, are VWAP/bid/ask real numbers —
//     runtime checks against the running pipeline, not just static config.
//     This is the category that would have caught the 2026-09-08 bugs
//     (stale-day Schwab candles; pattern/key-level/arrow never wired live) —
//     every other check below had matching constants the whole time.
//   - Threshold drift (ratio, volume, body %, etc.) when somebody edits a
//     literal in code instead of `StrategySpec`.
//   - Time-window boundary errors (e.g. the Morning-window-unreachable bug
//     that was the first thing this auditor caught).
//   - Pattern-recognizer divergence from the doc.
//   - Session-close-time drift.
//
// What it does NOT catch:
//   - Doc changes that haven't been mirrored into `StrategySpec` (the spec
//     is the canonical source; if a doc changes, update spec first).
//   - Logic bugs in code that happen to match the spec. Boundary checks help
//     here but they're not exhaustive — they're spot checks.
//   - A gate that's wired to compute live but is fed the WRONG live source
//     (e.g. right shape, wrong day) unless a live-proof check specifically
//     targets that failure mode, the way the "today's candle is actually
//     today" check now does.
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
    case liveProof      = "LIVE PROOF"
    case ratio          = "RATIO"
    case volume         = "VOLUME"
    case windows        = "WINDOWS"
    case exits          = "EXITS"
    case patterns       = "PATTERNS"
    case sizing         = "SIZING"
    case optionSelector = "OPTION SELECTOR"
}

struct StrategyAuditor {

    // MARK: - Public

    @MainActor
    static func run() -> [AuditResult] {
        var out: [AuditResult] = []
        out.append(contentsOf: liveProofChecks())
        out.append(contentsOf: ratioChecks())
        out.append(contentsOf: volumeChecks())
        out.append(contentsOf: windowChecks())
        out.append(contentsOf: exitChecks())
        out.append(contentsOf: patternChecks())
        out.append(contentsOf: sizingChecks())
        out.append(contentsOf: optionSelectorChecks())
        return out
    }

    // MARK: - Live Proof
    //
    // Everything below this checks CODE against the DOC -- deterministic,
    // synthetic, doesn't touch real data. None of it would have caught the
    // real 2026-09-08 bugs (Schwab returning last Friday's candles instead
    // of today's; pattern/key-level/arrow silently never computed live) --
    // the code's constants matched the doc exactly the whole time. This
    // section checks the RUNNING PIPELINE against reality instead: is the
    // feed actually ticking right now, is "today's" candle actually today,
    // are the numbers a trader would check against ThinkOrSwim actually
    // present. Warns (not fails) when Live Tape is simply off, since that's
    // a setting, not a bug.

    @MainActor
    private static func liveProofChecks() -> [AuditResult] {
        var r: [AuditResult] = []
        let live = LiveTapeService.shared
        let source = "runtime / LiveTapeService.shared"

        guard live.isEnabled else {
            r.append(AuditResult(
                category: .liveProof,
                title: "Live Tape enabled",
                expected: "on",
                actual: "off",
                status: .warning,
                docSource: source
            ))
            return r
        }

        if let lastTick = live.lastTickAt {
            let age = Date().timeIntervalSince(lastTick)
            r.append(AuditResult(
                category: .liveProof,
                title: "Last successful tick age",
                expected: "< 90s (30s poll interval)",
                actual: "\(Int(age))s ago",
                status: age < 90 ? .pass : .fail,
                docSource: source
            ))
        } else {
            r.append(AuditResult(
                category: .liveProof,
                title: "Last successful tick age",
                expected: "a real tick has landed",
                actual: "none yet",
                status: .warning,
                docSource: source
            ))
        }

        if let error = live.lastError, !live.isLive {
            r.append(AuditResult(
                category: .liveProof,
                title: "Feed error",
                expected: "none",
                actual: error,
                status: .fail,
                docSource: source
            ))
        }

        if let snapshot = live.lastSnapshot {
            let candles = snapshot.vxxCandles
            let cal = Calendar(identifier: .gregorian)
            let lastCandleIsToday = candles.last.map { cal.isDateInToday($0.timestamp) } ?? false
            r.append(AuditResult(
                category: .liveProof,
                title: "Today's candle is actually today",
                expected: "true",
                actual: "\(lastCandleIsToday) (\(candles.count) candles)",
                status: candles.isEmpty ? .warning : (lastCandleIsToday ? .pass : .fail),
                docSource: "the exact 2026-09-08 bug: Schwab returned last Friday's session"
            ))

            r.append(AuditResult(
                category: .liveProof,
                title: "VWAP has a real number, not just a category",
                expected: "> 0",
                actual: String(format: "%.2f", snapshot.vxxVwap),
                status: snapshot.vxxVwap > 0 ? .pass : .fail,
                docSource: "MarketDataEntry.vwapValue"
            ))

            r.append(AuditResult(
                category: .liveProof,
                title: "Bid/Ask present",
                expected: "both > 0",
                actual: String(format: "%.2f / %.2f", snapshot.vxxBid, snapshot.vxxAsk),
                status: (snapshot.vxxBid > 0 && snapshot.vxxAsk > 0) ? .pass : .fail,
                docSource: "Quote.bid / Quote.ask"
            ))
        } else {
            r.append(AuditResult(
                category: .liveProof,
                title: "Live snapshot present",
                expected: "a tick has landed",
                actual: "none yet",
                status: .warning,
                docSource: source
            ))
        }

        return r
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

        // Revised 2026-09-08: the market being open now makes a window
        // alertable, not just the three anchors -- but only pre-market and
        // after-hours stay excluded, and every off-anchor window has to
        // clear the same 300% bar Institutional already requires. Real
        // case this fixes: docs/trading docs/fails/
        // fail-01-2026-09-08-afternoon-flex-block.md.
        let entryWindowCases: [(TimeWindowInput, Bool, String)] = [
            (.preMarket, false, "Pre-market"),
            (.afterHours, false, "After hours"),
            (.open, true, "Open"),
            (.morning, true, "Morning"),
            (.lunch, true, "Lunch"),
            (.afternoonFlex, true, "Afternoon Flex"),
            (.powerHour, true, "Power Hour"),
            (.close, true, "Close"),
            (.institutional, true, "Institutional")
        ]
        for (window, expected, label) in entryWindowCases {
            let actual = window.isVXXEntryWindow
            r.append(AuditResult(
                category: .windows,
                title: "\(label) is alertable when market is open",
                expected: expected ? "yes" : "no",
                actual: actual ? "yes" : "no",
                status: actual == expected ? .pass : .fail,
                docSource: "Michael's call 2026-09-08, see fail-01 case study"
            ))
        }

        let offAnchorVolumeCases: [(TimeWindowInput, String)] = [
            (.open, "Open"), (.lunch, "Lunch"), (.afternoonFlex, "Afternoon Flex"), (.close, "Close")
        ]
        for (window, label) in offAnchorVolumeCases {
            r.append(AuditResult(
                category: .windows,
                title: "\(label) volume bar matches Institutional's (no free pass)",
                expected: "300%",
                actual: "\(Int(window.requiredVolumePercent))%",
                status: window.requiredVolumePercent == 300 ? .pass : .fail,
                docSource: "Michael's call 2026-09-08, see fail-01 case study"
            ))
        }

        return r
    }

    // MARK: - Exits

    private static func exitChecks() -> [AuditResult] {
        var r: [AuditResult] = []

        r.append(AuditResult(
            category: .exits,
            title: "Default session close (4:15 PM)",
            expected: "975 minutes",
            actual: "\(StrategySpec.defaultHardExitMinutes) minutes",
            status: StrategySpec.defaultHardExitMinutes == StrategySpec.extendedSessionCloseMinutes ? .pass : .fail,
            docSource: "user spec 2026-08-03 / extended session close"
        ))

        r.append(AuditResult(
            category: .exits,
            title: "Institutional session close (4:15 PM)",
            expected: "975 minutes",
            actual: "\(StrategySpec.institutionalHardExitMinutes) minutes",
            status: StrategySpec.institutionalHardExitMinutes == StrategySpec.extendedSessionCloseMinutes ? .pass : .fail,
            docSource: "user spec 2026-08-03 / extended session close"
        ))

        // Quote/alert behavior: all tracked windows share the 4:15 PM ET close.
        let inst = makeDate(hour: 15, minute: 50)
        let earlier = makeDate(hour: 11, minute: 15)
        let withInst = StrategySpec.hardExitMinutes(forOpenedAt: [earlier, inst])
        let withoutInst = StrategySpec.hardExitMinutes(forOpenedAt: [earlier])
        r.append(AuditResult(
            category: .exits,
            title: "Session close with Institutional position open",
            expected: "16:15",
            actual: formatMinutes(withInst),
            status: withInst == StrategySpec.extendedSessionCloseMinutes ? .pass : .fail,
            docSource: "user spec 2026-08-03 / extended session close"
        ))
        r.append(AuditResult(
            category: .exits,
            title: "Session close with only earlier positions",
            expected: "16:15",
            actual: formatMinutes(withoutInst),
            status: withoutInst == StrategySpec.extendedSessionCloseMinutes ? .pass : .fail,
            docSource: "user spec 2026-08-03 / extended session close"
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

    // MARK: - Option Selector
    //
    // Verifies the tightened-suggestion picker doesn't drift on its own
    // bounds. These checks run against synthetic contracts so the audit is
    // deterministic regardless of the live chain. Rule from
    // [[feedback-catch-drift-always]] applies here too.

    private static func optionSelectorChecks() -> [AuditResult] {
        var r: [AuditResult] = []

        // Bound constants — locked at known values, not arbitrary literals.
        r.append(checkConstant(
            title: "Target delta",
            expected: "0.55",
            actual: String(format: "%.2f", OptionSelector.targetDelta),
            pass: OptionSelector.targetDelta == 0.55
        ))
        r.append(checkConstant(
            title: "Delta band half-width",
            expected: "0.05 (|Δ| 0.50–0.60)",
            actual: String(format: "%.2f", OptionSelector.deltaBandHalfWidth),
            pass: OptionSelector.deltaBandHalfWidth == 0.05
        ))
        r.append(checkConstant(
            title: "DTE bounds",
            expected: "3–7 days",
            actual: "\(OptionSelector.dteMin)–\(OptionSelector.dteMax) days",
            pass: OptionSelector.dteMin == 3 && OptionSelector.dteMax == 7
        ))

        // Band edges — verify boundary inclusion behavior.
        let bandEdgeCases: [(Double, Bool, String)] = [
            (0.49, false, "Δ 0.49 (just below band)"),
            (0.50, true,  "Δ 0.50 (lower edge)"),
            (0.55, true,  "Δ 0.55 (target)"),
            (0.60, true,  "Δ 0.60 (upper edge)"),
            (0.61, false, "Δ 0.61 (just above band)"),
            (-0.55, true, "Δ -0.55 (put target)"),
            (-0.49, false, "Δ -0.49 (just inside zero for puts)")
        ]
        for (delta, shouldPass, label) in bandEdgeCases {
            let actual = OptionSelector.isWithinDeltaBand(delta)
            r.append(AuditResult(
                category: .optionSelector,
                title: "Delta band: \(label)",
                expected: shouldPass ? "in band" : "rejected",
                actual: actual ? "in band" : "rejected",
                status: actual == shouldPass ? .pass : .fail,
                docSource: "OptionSelector.swift / tightened bounds"
            ))
        }

        // DTE bounds — boundary inclusion.
        let now = Date()
        let cal = Calendar(identifier: .gregorian)
        let dteCases: [(Int, Bool, String)] = [
            (0, false, "0 DTE (below band)"),
            (2, false, "2 DTE (below band)"),
            (3, true,  "3 DTE (lower edge)"),
            (5, true,  "5 DTE (middle)"),
            (7, true,  "7 DTE (upper edge)"),
            (8, false, "8 DTE (above band)")
        ]
        for (days, shouldPass, label) in dteCases {
            guard let expiration = cal.date(byAdding: .day, value: days, to: now) else { continue }
            let actual = OptionSelector.isWithinDTE(expiration, now: now)
            r.append(AuditResult(
                category: .optionSelector,
                title: "DTE band: \(label)",
                expected: shouldPass ? "in band" : "rejected",
                actual: actual ? "in band" : "rejected",
                status: actual == shouldPass ? .pass : .fail,
                docSource: "OptionSelector.swift / dteMin–dteMax"
            ))
        }

        // Spread gate — wide spread must be rejected.
        let tight = syntheticContract(strike: 100, ask: 1.02, bid: 0.98, expiration: now)
        let wide  = syntheticContract(strike: 100, ask: 1.20, bid: 0.80, expiration: now)
        r.append(AuditResult(
            category: .optionSelector,
            title: "Spread gate: tight ($0.04 on $1.00)",
            expected: "accepted",
            actual: OptionSelector.passesSpreadGate(tight) ? "accepted" : "rejected",
            status: OptionSelector.passesSpreadGate(tight) ? .pass : .fail,
            docSource: "OptionSelector.swift / passesSpreadGate"
        ))
        r.append(AuditResult(
            category: .optionSelector,
            title: "Spread gate: wide ($0.40 on $1.00)",
            expected: "rejected",
            actual: OptionSelector.passesSpreadGate(wide) ? "accepted" : "rejected",
            status: !OptionSelector.passesSpreadGate(wide) ? .pass : .fail,
            docSource: "OptionSelector.swift / passesSpreadGate"
        ))

        // Sizing — contract count must floor and clamp to absoluteMaxContracts.
        let chain = makeAuditChain(side: .call, deltas: [0.55], strike: 100, ask: 2.00, bid: 1.96, dte: 4, now: now)
        if let small = OptionSelector.suggest(side: .call, chain: chain, budget: 1000, now: now) {
            r.append(AuditResult(
                category: .optionSelector,
                title: "Sizing floor: $1000 / $200 = 5 contracts",
                expected: "5",
                actual: "\(small.contractCount)",
                status: small.contractCount == 5 ? .pass : .fail,
                docSource: "OptionSelector.swift / floor(budget / ask*100)"
            ))
        } else {
            r.append(AuditResult(
                category: .optionSelector,
                title: "Sizing floor: $1000 / $200 = 5 contracts",
                expected: "5",
                actual: "no suggestion",
                status: .fail,
                docSource: "OptionSelector.swift / floor(budget / ask*100)"
            ))
        }
        // Clamp — over-budget must still cap at StrategySpec.absoluteMaxContracts.
        let cheapChain = makeAuditChain(side: .call, deltas: [0.55], strike: 100, ask: 0.20, bid: 0.18, dte: 4, now: now)
        if let big = OptionSelector.suggest(side: .call, chain: cheapChain, budget: 1000, now: now) {
            r.append(AuditResult(
                category: .optionSelector,
                title: "Sizing clamp at absoluteMaxContracts (\(StrategySpec.absoluteMaxContracts))",
                expected: "\(StrategySpec.absoluteMaxContracts)",
                actual: "\(big.contractCount)",
                status: big.contractCount == StrategySpec.absoluteMaxContracts ? .pass : .fail,
                docSource: "StrategySpec.absoluteMaxContracts"
            ))
        }

        // Band miss — feeding a chain with no in-band delta must return nil
        // (selector must NEVER silently widen).
        let offBandChain = makeAuditChain(side: .call, deltas: [0.30, 0.40, 0.75], strike: 100, ask: 1.00, bid: 0.98, dte: 4, now: now)
        let bandMiss = OptionSelector.suggest(side: .call, chain: offBandChain, budget: 1000, now: now)
        r.append(AuditResult(
            category: .optionSelector,
            title: "Band miss returns nil (no silent widening)",
            expected: "nil",
            actual: bandMiss == nil ? "nil" : "non-nil",
            status: bandMiss == nil ? .pass : .fail,
            docSource: "OptionSelector.swift / closest match within band"
        ))

        return r
    }

    private static func checkConstant(title: String, expected: String, actual: String, pass: Bool) -> AuditResult {
        AuditResult(
            category: .optionSelector,
            title: title,
            expected: expected,
            actual: actual,
            status: pass ? .pass : .fail,
            docSource: "OptionSelector.swift / suggestion bounds"
        )
    }

    private static func syntheticContract(
        strike: Double,
        ask: Double,
        bid: Double,
        expiration: Date,
        delta: Double = 0.55,
        type: OptionType = .call
    ) -> OptionContract {
        OptionContract(
            symbol: "AUDIT",
            strike: strike,
            expiration: expiration,
            type: type,
            bid: bid,
            ask: ask,
            last: (bid + ask) / 2,
            volume: 100,
            openInterest: 100,
            delta: delta,
            gamma: 0.05,
            theta: -0.05,
            vega: 0.10,
            impliedVolatility: 50
        )
    }

    private static func makeAuditChain(
        side: OptionType,
        deltas: [Double],
        strike: Double,
        ask: Double,
        bid: Double,
        dte: Int,
        now: Date
    ) -> OptionsChain {
        let cal = Calendar(identifier: .gregorian)
        let expiration = cal.date(byAdding: .day, value: dte, to: now) ?? now
        let contracts = deltas.enumerated().map { idx, delta in
            syntheticContract(
                strike: strike + Double(idx),
                ask: ask,
                bid: bid,
                expiration: expiration,
                delta: side == .call ? delta : -delta,
                type: side
            )
        }
        return OptionsChain(
            symbol: "AUDIT",
            calls: side == .call ? contracts : [],
            puts:  side == .put  ? contracts : [],
            underlyingPrice: strike
        )
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
