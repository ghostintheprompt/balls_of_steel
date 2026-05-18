# Steel Trading Desk Handoff

Last updated: May 16, 2026

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

**Provider reality + architecture decisions — May 16, 2026.** Session opened with a panic ("APIs not connecting before release"), turned into a deeper conversation about long-term product direction. No rush — user confirmed this is a multi-year, self-first tool. Multiple memory + STRATEGY_NOTES.md updates were saved through the session to capture learnings.

**Discoveries logged in `STRATEGY_NOTES.md` "Provider reality" section:**
- **Finnhub free tier paywalled `/stock/candle` mid-2024.** The user-visible "Finnhub rejected the API key" error in Settings → Data Source is actually the endpoint paywall, not the key. `FinnhubProvider.quote()` parallel-fetches `/quote` (still free) + `/stock/candle` (now 403) and requires both.
- **All other providers in this repo are stubs.** `PolygonProvider`, `YahooProvider`, `SchwabProviderAdapter` all throw `.notImplemented`. `SchwabService` returns hardcoded sample data — never live.
- **Schwab is the durable home.** User had a Schwab developer ID registered ~2025; an earlier prototype had working Schwab integration before the Nov 2025 pivot to ToS + manual mode. User can't currently log in to `developer.schwab.com` — account recovery is the long-pole. Pre-strip code lives at `git show 0115bf5:Balls_of_Steel/Services/SchwabService.swift`. Strip commit is `26d6ee3`.

**Architecture decisions locked in `STRATEGY_NOTES.md`:**
- Two App Store apps shipped in parallel: **Steel VXX Desk** (free) and **Steel SPY Desk** (paid, one-time). Shared `SteelStrategyKit` Swift Package as the durable engine.
- Both desks options-only, never shares. VXX uses puts, SPY uses calls + candlestick-direction confirmation. Same 5-criteria gate, same time windows, same circuit breakers — execution vehicle differs.
- Manual entry is the fallback, not the design. "Why do manual unless I have to — it's the AI automation age."
- Product framing locked: **"a discipline engine."** Deliberately niche; don't widen the market.

**Code changes:**
- `Steel_Trading_Desk/Views/SettingsView.swift` — `dataSourceCard` replaced. Removed the broken provider picker, API-key SecureField, auto-populate toggle, live status row, and 5 computed properties (`liveModeBinding`, `liveStatusText`, `providerBinding`, `keyBinding`, `keyPlaceholder`). Now shows "MANUAL ENTRY — FALLBACK" + "LIVE FEED — RESTORING" placeholder copy in the same `InfoCard` styling with `DesignSystem.amber` accents.
- `Steel_Trading_Desk/Views/SettingsView.swift` — `brokerCard` similarly rewritten. Removed the broken Connect button + `apiKey` SecureField (which silently called `SchwabService.streamQuotes` that throws `.educationalModeOnly`). Now shows "SCHWAB — INTEGRATION PENDING" placeholder.
- `Steel_Trading_Desk/Views/SettingsView.swift` — removed unused `@State apiKey`, `@StateObject connectionManager`, `@StateObject marketDataRegistry`, `@StateObject liveTape`, `@State finnhubKey`, `@State polygonKey`, `@State liveEnabled` declarations.
- `Steel_Trading_Desk/Services/LiveTapeService.swift` — `init()` no longer auto-starts. Any existing user with `liveTape.enabled = true` in UserDefaults will stop silently polling the dead Finnhub endpoint on next launch.
- `STRATEGY_NOTES.md` — expanded with "Product framing" (discipline engine, niche), "Provider reality (2026-05-16)", revised "Paid product" decision (parallel two-app architecture + shared Swift Package + options-only mechanics), Finnhub affiliate section marked STALE.
- New doc: **`docs/SCHWAB_API_READINESS.md`** — full readiness assessment for the Schwab Trader API integration. Current state, historical-code review, real API requirements (with explicit "confirm against live docs at implementation time" caveats), gap analysis, sequenced plan for when dev-portal access is restored, open questions for next session.

**Memory updates this session (`~/.claude/projects/.../memory/`):**
- `feedback_no_weak_assumptions.md` — confirm before proposing providers/architecture/monetization; verify external claims.
- `feedback_docs_track_reality.md` — keep STRATEGY_NOTES + docs current as reality is learned.
- `feedback_options_only_never_shares.md` — both desks trade options exclusively. VXX puts, SPY calls.
- `feedback_niche_positioning.md` — deliberately niche; select for the right user, don't maximize installs.
- `feedback_preserve_design.md` — function-only changes; replace broken interactive guts with informative copy in the same card.
- `feedback_automation_not_manual.md` — automation is destination, manual is fallback.
- `user_boiler_room_background.md` — user is a former boiler-room broker; the voice and method are earned, not constructed.
- `project_schwab_dev_history.md` — Schwab dev account exists from ~2025; recovery work, not fresh build.

**Builds:** Not verified this session (no Xcode build run). SourceKit showed spurious "type not in scope" diagnostics during edits but those are indexing artifacts on types defined in the same module — should heal on next clean build. Verify with the canonical iOS + macOS Debug builds before installing.

---

**Disclaimer + privacy + compliance scrub — DONE (May 14, 2026).** Three release-blocker punchlist items closed.

- **Disclaimer text** (`DisclaimerView.swift`) scrubbed of all 4 "win rate" mentions → "strategies/examples are educational, not promises."
- **Privacy Policy** updated to honestly disclose optional Finnhub/Polygon/Schwab/Yahoo network requests when Live Mode is on (device → provider direct, never through us). Keychain disclosed. iOS + macOS storage both noted (was macOS-only).
- **AboutLegalView** hard-coded "v3.0" / "3.0.0" replaced with `Bundle.main.infoDictionary` reads.
- **4 dead view files deleted**: `StrategiesListView.swift` (16 fabricated win-rate rows — biggest App Review risk), `ArrowSignalViews.swift` (reliability % displays), `VXXTradingDashboard.swift` (pre-redesign legacy), `PatternIndicatorViews.swift` (confidence % display). All only referenced by their own previews or the dead VXX dashboard. pbxproj cleaned.
- **`VXXTradingWindow.winRate`** getter removed (unused, contained "highest probability" comment + fabricated lunch %).
- **`MarketDataEntry.ratioTier`** and **`TechnicalIndicators.RatioTier.displayName`** now use `StrategySpec.tier(forRatio:).label` — dropped "(Rating: 1/2/3)" parenthetical that wasn't in the doc.
- App Store metadata docs scanned — `APP_STORE_CONNECT_COPY.md` and `LAUNCH_GUIDE.md` already clean. (Later, on 2026-05-16: `LAUNCH_PLAN.md` was merged into `LAUNCH_GUIDE.md`; `MARKETING.md` and `AppStoreMetadata.md` were merged into `APP_STORE_CONNECT_COPY.md`. All three originals deleted.)

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

**Read first:** `STRATEGY_NOTES.md` (especially the new "Provider reality" + "Paid product" sections), `docs/SCHWAB_API_READINESS.md` (the full Schwab integration plan), and the memory files added this session — they encode product direction that the May 14 punch list predates.

**Highest-priority work, in order:**

1. **User: recover `developer.schwab.com` login.** That's the long-pole. Until this lands, code work on the Schwab API is blocked. See "Open questions / blockers" in `docs/SCHWAB_API_READINESS.md` for what's needed from the dev portal (client ID, registered redirect URI, decision on multi-account vs single-user).
2. **Once dev portal is back:** Work through `docs/SCHWAB_API_READINESS.md` "The plan" section — OAuth flow first, REST second, streamer third. Re-verify the endpoint/protocol claims against current Schwab docs before writing code (per the no-weak-assumptions rule).
3. **Capture SPY execution rules into `docs/trading docs/spy_execution.md`.** User confirmed 2026-05-16 that SPY uses the exact same setup as VXX but with calls + candlestick-direction confirmation. The specifics (candle-direction logic, strike selection, DTE choice for SPY vs VXX) need to be written down before SPY app shell work begins. Capture from user via Q&A — `vxx_trading_philosophy_discipline.md` is the template.
4. **Map `SteelStrategyKit` Swift Package extraction.** Audit `Steel_Trading_Desk` and produce a categorized plan: shared engine (strategy gates, divergence read, alerts, design system, audit, time windows, position sizing) vs VXX-app-specific surfaces (VXX trade execution UI, VXX-specific copy). Pure research, no input from user needed. Output: a doc + an extraction-order plan.

**Lower-priority carryover from May 14:**
- Build + install signed Release on `ZZZ` to evaluate the May-14 chart work (native chart tile, fullscreen sheet, VWAP/SMA/window stripes/volume panel/ratio tier band/pattern markers/tap-OHLCV) during market hours. **Important:** with `LiveTapeService` auto-start now disabled and the Finnhub flow removed from Settings, end-to-end "live-tape feeds the gates" can't be tested this build — verify only the manual-entry path on device for now.
- Refresh App Store screenshots: iPhone home now shows the new chart tile. Re-render icon since SteelDeskMark is amber-on-black.
- Add an XCTest target. Cover `TimeManager` window logic, `DeskState.current(...)` boundary times, `VXXStrategyState.firstFailingGateIndex`, ratio threshold tiers, candle aggregation rollup math.
- Docs consolidation complete (2026-05-16). Three docs (`LAUNCH_PLAN.md`, `MARKETING.md`, `AppStoreMetadata.md`) deleted and folded into `LAUNCH_GUIDE.md` (runbook) and `APP_STORE_CONNECT_COPY.md` (App Store paste sheet). No further action.

## Files To Start With

- `STRATEGY_NOTES.md` (root) — product direction, niche framing, paid-product architecture
- `docs/RELEASE_PUNCH_LIST.md` — day-to-day P0
- `docs/LAUNCH_GUIDE.md` — submission runbook + status
- `docs/APP_STORE_CONNECT_COPY.md` — App Store paste sheet (canonical metadata)
- `docs/SCHWAB_API_READINESS.md` — v1.1 provider plan
- `Steel_Trading_Desk/Views/MainView.swift`
- `Steel_Trading_Desk/Views/TradingDashboard.swift`
- `Steel_Trading_Desk/Views/ManualDataEntryView.swift`
- `Steel_Trading_Desk/Views/PromptCoachView.swift`
- `Steel_Trading_Desk/Views/Components/DesignSystem.swift`

## Open Risks

- **Schwab dev-portal account recovery is the long-pole for v1.1.** If account recovery fails outright (e.g., dev portal closed the registration after a year of inactivity), full re-application + approval could take weeks. Worth user reaching out to Schwab developer support proactively.
- **The historical Schwab code in `0115bf5` is not actually production-validated against the real Schwab Trader API.** The static `Bearer <apiKey>` auth pattern is generic, not real Schwab OAuth. Plan for substantial rewrite, not resurrection — see `docs/SCHWAB_API_READINESS.md` "Historical Schwab code" section for what's actually salvageable (~30% plumbing, 70% rewrite).
- App Review may object to performance claims or language that sounds like actionable financial advice.
- The iPhone UI may still be too dense in VXX, Tape, Prompt, and Risk flows.
- Some screens may still contain UI without enough function. These should be cut or rewritten before TestFlight.
- Background monitoring on iOS needs a stricter review before it is described as a release feature.
- Mac App Store builds may need different update-checker behavior than direct-distribution builds.
- External TestFlight should wait until first-run disclaimer, privacy copy, and manual-only positioning are clear.
- **The two-app shipping plan** (VXX free + SPY paid sharing `SteelStrategyKit`) hasn't been validated against App Store review for the SPY paid app. Apple sometimes scrutinizes paid trading-adjacent apps more carefully. Worth checking review guidelines before SPY app submission, especially around the "discipline engine" framing vs anything that could read as a signals subscription.
