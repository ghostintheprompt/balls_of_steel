# Steel Trading Desk Handoff

Last updated: May 14, 2026

## Current State

The repo is a native SwiftUI Xcode project with one app target: `Steel_Trading_Desk`. The target supports `macosx`, `iphoneos`, and `iphonesimulator`. There is no watchOS target yet.

Verified builds:

```sh
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Debug -destination generic/platform=iOS -derivedDataPath /private/tmp/balls_of_steel_ios_build CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Debug -destination platform=macOS -derivedDataPath /private/tmp/balls_of_steel_mac_build CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Release -destination generic/platform=iOS -derivedDataPath /private/tmp/balls_of_steel_ios_release_function CODE_SIGNING_ALLOWED=NO build
```

All commands pass as of this handoff. A signed `Release-iphoneos` build was also built and installed on the paired iPhone named `ZZZ` using the local MDRN wildcard development profile:

```sh
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Release -destination 'platform=iOS,id=00008120-000E64960CE9A01E' -derivedDataPath /private/tmp/balls_of_steel_device_release_function_retry DEVELOPMENT_TEAM=9TB25L4266 CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY='Apple Development' build
xcrun devicectl device install app --device DC63616F-433E-5833-9255-BE85AAFC9A7A /private/tmp/balls_of_steel_device_release_function_retry/Build/Products/Release-iphoneos/Steel_Trading_Desk.app
xcrun devicectl device process launch --device DC63616F-433E-5833-9255-BE85AAFC9A7A app.mdrn.steel
```

Latest signed Release pushed to `ZZZ` on **May 14, 2026 22:20 ET** with everything from today's session: chart Sessions A/B/C, strategy audit + 7 drift fixes, compliance scrub (4 dead view files removed + disclaimer + privacy text updated), iPad/Mac NavigationView `.stack` fix. Ready for tomorrow's market-hours playtest.

Earlier install — signed Release pushed to `ZZZ` after the `NEXT MOVE` command-card pass:

```sh
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Release -destination 'platform=iOS,id=00008120-000E64960CE9A01E' -derivedDataPath /private/tmp/balls_of_steel_device_release_command DEVELOPMENT_TEAM=9TB25L4266 CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY='Apple Development' build
xcrun devicectl device install app --device DC63616F-433E-5833-9255-BE85AAFC9A7A /private/tmp/balls_of_steel_device_release_command/Build/Products/Release-iphoneos/Steel_Trading_Desk.app
xcrun devicectl device process launch --device DC63616F-433E-5833-9255-BE85AAFC9A7A app.mdrn.steel
```

## What Changed In This Pass

**Disclaimer + privacy + compliance scrub — DONE (May 14, 2026).** Three release-blocker punchlist items closed.

- **Disclaimer text** (`DisclaimerView.swift`) scrubbed of all 4 "win rate" mentions → "strategies/examples are educational, not promises."
- **Privacy Policy** updated to honestly disclose optional Finnhub/Polygon/Schwab/Yahoo network requests when Live Mode is on (device → provider direct, never through us). Keychain disclosed. iOS + macOS storage both noted (was macOS-only).
- **AboutLegalView** hard-coded "v3.0" / "3.0.0" replaced with `Bundle.main.infoDictionary` reads.
- **4 dead view files deleted**: `StrategiesListView.swift` (16 fabricated win-rate rows — biggest App Review risk), `ArrowSignalViews.swift` (reliability % displays), `VXXTradingDashboard.swift` (pre-redesign legacy), `PatternIndicatorViews.swift` (confidence % display). All only referenced by their own previews or the dead VXX dashboard. pbxproj cleaned.
- **`VXXTradingWindow.winRate`** getter removed (unused, contained "highest probability" comment + fabricated lunch %).
- **`MarketDataEntry.ratioTier`** and **`TechnicalIndicators.RatioTier.displayName`** now use `StrategySpec.tier(forRatio:).label` — dropped "(Rating: 1/2/3)" parenthetical that wasn't in the doc.
- App Store metadata docs scanned — `APP_STORE_CONNECT_COPY.md`, `AppStoreMetadata.md`, `MARKETING.md`, `LAUNCH_GUIDE.md`, `LAUNCH_PLAN.md` already clean.

Both iOS + macOS Debug builds green.

---

**Strategy ↔ code alignment audit — DONE (May 14, 2026).** Built a permanent drift-catching mechanism.

- **`Models/StrategySpec.swift`** — canonical constants mirrored from `docs/trading docs/`: ratio tiers (1.35/1.45/1.55/1.60), volume thresholds per window (200/200/300%), time windows (Morning 9:50-10:15, Power 15:10-15:25, Institutional 15:45-16:10), exit cutoffs (15:55 default, 16:05 for Institutional positions), pattern criteria, position sizing.
- **`Services/StrategyAuditor.swift`** — runs ~30 checks across 6 categories (RATIO / VOLUME / WINDOWS / EXITS / PATTERNS / SIZING). Returns `[AuditResult]` with expected vs actual + doc-source citation.
- **Settings → Strategy Audit** sheet — one-button "is the code still doing what the doc says?" check. Summary banner (PASS / FAIL / WARN / TOTAL) + categorised result list with failures first.

**First-run drift caught and fixed:**
1. Morning window unreachable for 9:50-10:04 ET (switch-case order silently shadowed `.morning` with `.open`).
2. Lunch was flagged as a VXX entry window (doc explicitly excludes it).
3. Volume threshold was uniform at 200% (Institutional needs 300% per doc).
4. Fabricated reliability % for non-doc windows (afternoonFlex 72%, etc. — violated "no win-rate % in primary UI" rule).
5. Hard exit time uniform at 15:55, clipping Institutional positions that doc allows to hold to 16:05. User confirmed Institutional swing 3:40-4:15 is the primary opportunity — extended cutoff to 16:05 when any open position came from Institutional window.
6. Bearish Engulfing body-size filter (≥40%) wasn't in the doc — removed.
7. Divergence as hard ratio gate (`!ratioConverging` required) wasn't in the doc — now a soft warning in `ratioDetail`.

Both iOS + macOS Debug builds green.

---

**iPhone chart redesign — Sessions A + B (May 14, 2026).** The 140pt squashed TradingView WebView on the iPhone home was unreadable for the strategy's candle-pattern reads. Replaced with native Swift Charts. Two-tier pattern matches Robinhood / Webull / Schwab / ToS mobile.

Session A:
- `PhoneCandleStrip` (inline ~150pt on phone home): native candles + VWAP (cyan) + 20 SMA (amber faded dashed) + 50 SMA (amber solid) + right-side price/ratio readout. Whole tile is a tap target.
- `PhoneChartSheet` (fullscreen `.large` detent): same chart at full density + segmented interval picker (1M / 5M / 15M, all client-aggregated from Finnhub's 1-min bars).
- New `Array<Candle>.aggregated(bucketSeconds:)` in `Models/Quote.swift` does the rollup.
- `LiveTapeService.LiveSnapshot` now carries `vxxVwap` and `vxxCandles`.
- User's ToS setup + philosophy + prompt docs landed in `docs/trading docs/` — now the strategy spec.

Session B (stacks on Session A):
- **Time-window vertical stripes** on both tile + sheet — faint amber underlay during the 3 ToS windows (9:50-10:15 Morning, 15:10-15:25 Power, 15:45-16:10 Institutional). Subtle on the tile, more visible on the sheet.
- **Volume sub-panel** under the price chart in the sheet — green/red `BarMark` per candle, dashed `RuleMark` at 2× 30-period average (the 200% institutional threshold from ToS). "LAST X%" readout turns green when ≥200%.
- **VXX/VIX ratio tier band** — horizontal level meter, 5 zones at the strategy's tier boundaries (1.20 / 1.35 / 1.45 / 1.55 / 1.60 / 1.80). Current ratio rendered as a vertical marker + triangle. Tier label readout: "PREMIUM FADE", "STRONG FADE", "NORMAL FADE", "WEAK · CAUTION", "NO FADE".

Session C (also May 14):
- **Bearish Engulfing detector** added to `PatternRecognizer` (`Models/CandlestickPattern.swift`). Now scans for all 5 ToS patterns: Shooting Star / Doji / Hammer / Hanging Man / Bearish Engulfing.
- **Series-wide scanner** `detectPatternsAcrossSeries` runs the per-candle recognizer over the whole visible series, so every historical pattern hit lights up on the chart, not just the latest.
- **Pattern markers** on the price chart in the sheet. Bearish triggers get an amber down-triangle above the candle (opacity scaled by signal strength); doji gets a circle; hammer (bullish — warning to puts traders) gets a muted steel up-triangle below the candle. Each marker carries a 2-letter shortCode (SS / DJ / HM / HG / BE).
- **Tap-to-OHLCV** via `chartOverlay` + DragGesture. Selected candle gets a dashed vertical guide; an OHLCVReadout row underneath shows T · O · H · L · C · V · VOL% with VOL% turning green at ≥200%. X button clears selection.

Both iOS + macOS Debug builds green. Not yet installed on `ZZZ` — install + market-hours check is the next step.

---

## Earlier passes

Boiler-room redesign per `CLAUDE_CODE_DIRECTIONS.md`. All 9 phases shipped.

- **Phase 1 — Token swap.** New palette (CRT amber `#FFB000` on near-black) and IBM Plex font stack. System fallback wired; Plex `.ttf` files pending bundling.
- **Phase 2 — Decoration killed.** Every cornerRadius → 2pt, every shadow/glow on cards removed, every bare `.purple/.orange/.yellow/.cyan/.gray` color replaced with a `DesignSystem` token, large fixed paddings collapsed.
- **Phase 3 — Mac single-window terminal.** Three-column layout (ticker strip / left rail gate spine / chart center / right rail NEXT MOVE+RAW READ+SECOND READ+ET clock / status footer). Mac TabView removed.
- **Phase 4 — iPhone gate-spine.** Phone home is ticker strip → NEXT MOVE verb → 4-gate stack with amber blocker highlight + tap-through → mini chart → ET clock + hard-stop countdown footer. Tapping a gate opens a drill-in sheet with big number + tier table + house rule.
- **Phase 5 — TradingView chart embed.** New `Views/Components/ChartWebView.swift` (cross-platform WKWebView). VWAP + SMA + Volume overlays. 15-min delayed disclosure in chart footer.
- **Phase 6 — MarketDataProvider scaffolding.** Protocol + 4 provider files (`Finnhub`, `Polygon`, `Schwab`, `Yahoo`). Settings has a segmented picker + per-provider setup note + API key field. Real network calls stubbed; gates still consume manual tape entry.
- **Phase 7 — DeskState machine.** New `Models/DeskState.swift`. iPhone hard-exit takeover (15:50–16:10 ET) drives off `DeskState.isTakeover`.
- **Phase 8 — Notification copy.** Every body string in `SignalNotification.swift` rewritten to blunt diagnosis tone. Registered `STEEL_DESK` notification category with "Open Desk" foreground action.
- **Phase 9 — App Store metadata.** Subtitle synced to "Native Volatility Analysis Tool". Promo text + description rewritten to mention chart embed and hard-exit takeover. `RELEASE_PUNCH_LIST.md` refreshed to reflect what's done vs. what remains.

## Important Findings

- The app is not a website, game, generic trading app, or AI app. It is a broker-desk utility with function and attitude.
- The practical product is simple: VXX setup, VXX/VIX ratio, VWAP/level, volume confirmation, correct time window, prompt if useful, execute on broker, manage risk. Execution belongs on the actual trading platform.
- iPhone should be the lead release surface, but the UI still needs market-hours evaluation for legibility, speed, and whether each screen earns its place.
- The app should be described as a manual, local-first trading discipline desk. It should not promise signals, win rates, financial advice, or automated execution.
- The visual system should feel like wealth, grit, and balls through utility, not through hype. Avoid website/video-game treatment, decorative cards, novelty motion, and fake authority copy.
- Remaining orange/purple accents should be audited because they read off-brand and can make the app feel like an AI template.
- There are multiple launch/metadata docs with stronger internal language than App Review should see.
- The release direction is no paywall. Keep it that way unless monetization returns later as patronage, support, or serious investor interest earned by usefulness.
- Internal monetization note: VXX stays free. If a paid trading product exists later, the SPY version is the candidate, as a separate serious offer. Do not put this in public App Store copy.
- There is no test target.
- watchOS belongs on the future punch list only.

## Suggested Next Session

1. **Build + install signed Release on `ZZZ`** to evaluate the complete native chart (tile + fullscreen sheet with VWAP / 20-50 SMA / window stripes / volume panel / ratio tier band / pattern markers / tap-to-OHLCV) during market hours. Verify:
   - Finnhub free tier returns enough 1-min bars for 50 SMA to plot
   - `^VIX` returns data — fall back to `INDEX:VIX` / `TVC:VIX` in `LiveTapeService.fetchAndPersist` if not
   - Pattern markers fire on real candles at sane positions (Shooting Star at tops, Hammer at bottoms, etc.)
   - Tap-to-OHLCV reads cleanly at thumb distance
   - Live-tape end-to-end still works (gates flip without touching manual entry)
4. Refresh App Store screenshots: the iPhone home now shows the new chart tile — screenshots should reflect it. Re-render the icon since SteelDeskMark is amber-on-black.
5. Add an XCTest target. Cover `TimeManager` window logic, `DeskState.current(...)` boundary times, `VXXStrategyState.firstFailingGateIndex`, ratio threshold tiers, candle aggregation rollup math.
6. Scrub `LAUNCH_GUIDE.md` / `LAUNCH_PLAN.md` / `MARKETING.md` for any remaining "Pro/Premium/Coach/win-rate %" leakage and reconcile with `APP_STORE_CONNECT_COPY.md` as the canonical source.

## Files To Start With

- `docs/RELEASE_PUNCH_LIST.md`
- `docs/AppStoreMetadata.md`
- `docs/MARKETING.md`
- `Steel_Trading_Desk/Views/MainView.swift`
- `Steel_Trading_Desk/Views/TradingDashboard.swift`
- `Steel_Trading_Desk/Views/VXXTradingDashboard.swift`
- `Steel_Trading_Desk/Views/ManualDataEntryView.swift`
- `Steel_Trading_Desk/Views/PromptCoachView.swift`
- `Steel_Trading_Desk/Views/Components/DesignSystem.swift`

## Open Risks

- App Review may object to performance claims or language that sounds like actionable financial advice.
- The iPhone UI may still be too dense in VXX, Tape, Prompt, and Risk flows.
- Some screens may still contain UI without enough function. These should be cut or rewritten before TestFlight.
- Background monitoring on iOS needs a stricter review before it is described as a release feature.
- Mac App Store builds may need different update-checker behavior than direct-distribution builds.
- External TestFlight should wait until first-run disclaimer, privacy copy, and manual-only positioning are clear.
