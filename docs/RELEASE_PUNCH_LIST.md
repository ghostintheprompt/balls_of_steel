# Steel Trading Desk Release Punch List

Last updated: May 14, 2026 (after the native iPhone chart redesign).

## Product Position

Steel Trading Desk is a local-first, manual trading discipline utility for SPY and VXX options traders. The app is a hard discipline layer: enter the tape, watch the four gates clear in order, embed a chart for context, execute manually on a broker, and keep the exit honest.

It is not financial advice, automated trading, managed execution, guaranteed signals, or a brokerage replacement.

It is not a website, game, generic trading dashboard, or AI authority product. It exists for one workflow: VXX setup → VXX/VIX ratio → VWAP/level → volume confirmation → correct time window → optional second read → broker execution → risk management → hard exit.

Monetization posture: no paywall for the desk. Strategy and core tools are free. If a paid product exists later, it is a separate SPY-focused offer earned through usefulness.

Internal product note: VXX is the free desk and proof of craft. Keep paid-tier ideas out of public App Store copy for the VXX release.

## Done in the boiler-room redesign pass (May 2026)

- **Token swap.** New palette (CRT amber `#FFB000` on near-black). IBM Plex fonts now live and bundled: Sans Regular + SemiBold, Sans Condensed Bold, Mono Regular + SemiBold. ~1MB total in the app bundle. System fallback retained per-family but disabled by default.
- **Decoration killed.** All `RoundedRectangle` corners → 2pt; every shadow/glow on cards removed; `.padding(20)` collapsed; every purple/orange/yellow/cyan/gray bare color replaced with a `DesignSystem` token.
- **Mac single-window terminal.** Three-column layout (ticker strip / left rail gate spine / chart center / right rail NEXT MOVE+RAW READ+SECOND READ+ET clock / status footer). The Mac TabView is gone; the gate sequence IS the navigation. Manual entry + Prompt Coach come up as sheets from the right rail.
- **iPhone gate-spine.** Phone home is now ticker strip → NEXT MOVE verb → 4-gate stack with amber blocker highlight → mini chart → ET clock + hard-stop countdown footer. Tapping a gate opens a drill-in sheet with big number + tier table + house rule.
- **Hard-exit takeover.** Between 15:50 and 16:10 ET the iPhone screen is replaced by a giant red countdown to 15:55, open positions list with live P/L, and the three exit rules. Triggered automatically by `DeskState.isTakeover`.
- **TradingView chart embed.** New `Views/Components/ChartWebView.swift` wraps the TradingView Advanced Chart widget in `WKWebView` (cross-platform). VWAP + SMA + Volume overlays. 15-minute delayed disclosure in the chart footer.
- **MarketDataProvider scaffolding.** New protocol + 4 provider files (`Finnhub`, `Polygon`, `Schwab`, `Yahoo`). Settings has a segmented picker + per-provider setup note + API key field. **Real network calls are stubbed for now** — the gates still consume the manual tape entry. Real implementation lands when the user has API keys provisioned.
- **DeskState machine.** New `Models/DeskState.swift` enum (preMarket / betweenWindows / windowOpen / openPosition / closeWarning / hardExit / afterHours) drives screen state.
- **Notification copy.** Every body string in `SignalNotification.swift` rewritten to blunt diagnosis tone (e.g. `VXX · GO CHECK THE TAPE` / `R 1.62 · VIX 18.4 · ENTRY $X · STOP $Y · TGT $Z`). Registered `STEEL_DESK` notification category with an "Open Desk" foreground action.
- **App Store copy.** Subtitle synced to "Native Volatility Analysis Tool" (good Review cover). Promo text + description rewritten to mention the chart embed and hard-exit takeover.

## Done in the native iPhone chart redesign (May 14, 2026)

Replaced the squashed 140pt TradingView WebView on the iPhone home with an all-native Swift Charts implementation built to mirror the ToS setup from `docs/trading docs/`.

- **Two-tier layout.** Inline `PhoneCandleStrip` (~150pt on phone home) → tap → fullscreen `PhoneChartSheet` (`.large` detent). Same pattern as Robinhood / Webull / Schwab / ToS mobile / TradingView's own iOS app — nobody tries to read patterns at 140pt.
- **Chart overlays.** Candles + VWAP (cyan) + 20 SMA (amber dashed) + 50 SMA (amber solid). Client-side OHLC aggregation from Finnhub's 1-min bars into 5m / 15m via `Array<Candle>.aggregated(bucketSeconds:)`.
- **Time-window stripes.** Faint amber underlay during the 3 ToS windows (9:50-10:15 Morning, 15:10-15:25 Power, 15:45-16:10 Institutional). Subtle on the tile, more present on the sheet.
- **Volume sub-panel.** Green/red bars by candle direction, dashed amber line at 2× the 30-period average (the 200% institutional-participation threshold). "LAST X%" readout flips green when ≥200%.
- **VXX/VIX ratio tier band.** Horizontal level meter, 5 zones at strategy boundaries (1.35 / 1.45 / 1.55 / 1.60). Current ratio as a vertical marker + tier label readout ("PREMIUM FADE", "STRONG FADE", "NORMAL FADE", "WEAK · CAUTION", "NO FADE").
- **Pattern markers.** PatternRecognizer now scans the whole visible series (not just the latest candle) and surfaces Shooting Star / Doji / Hammer / Hanging Man / Bearish Engulfing hits. Bearish triggers get a down-triangle above the candle (amber, scaled by signal strength); doji gets an amber dot; hammer (bullish) gets a muted steel up-triangle below the candle — warning that open puts may be in trouble.
- **Bearish Engulfing detector.** Added to `PatternRecognizer` (wasn't in the original 4-pattern set). Requires prior candle bullish, current bearish, current body fully engulfing prior body, current body ≥40% of total range, volume >200% avg.
- **Tap-to-OHLCV.** `chartOverlay` + `DragGesture` in `PhoneCandleChart`. Tap or scrub a candle → floating row shows T · O · H · L · C · V · VOL% with tier-tiered color (close green/red by direction, VOL% green if ≥200%). X button clears selection.

## Remaining P0 — Release Blockers

1. **Strategy ↔ code alignment audit — DONE 2026-05-14.** Built `StrategySpec.swift` (canonical constants mirrored from `docs/trading docs/`) + `StrategyAuditor.swift` (runtime check service) + Settings → Strategy Audit UI. First audit run caught and fixed 7 drift items:
   - Morning window unreachable for 9:50-10:04 (case ordering)
   - Lunch flagged as VXX entry window
   - Volume threshold uniform at 200% (now 200/200/300 per window)
   - Fabricated reliability % for non-doc windows
   - Hard exit time uniform at 15:55 (now 16:05 for Institutional positions per user spec)
   - Bearish Engulfing body-size filter not in doc
   - Divergence as hard ratio gate (now soft warning)

   Going forward: any change touching strategy logic runs through `StrategySpec`. Settings → Strategy Audit verifies on demand.

2. **Market-hours test on `ZZZ` — iPhone chart + live tape.** Native Swift Charts two-tier chart shipped 2026-05-14 with VWAP + 20/50 SMA + time-window stripes + volume panel + ratio tier band + pattern markers + tap-to-OHLCV. Needs verification at live market hours:
   - **Finnhub `^VIX` symbol returns data on free tier** — if not, fall back to `TVC:VIX` or `INDEX:VIX` in `LiveTapeService.fetchAndPersist`. Per ToS doc the ratio depends on VIX.
   - **Enough 1-min bars come back** for 50 SMA to plot (50+ bars required). If Finnhub free tier truncates mid-session, document the cutoff.
   - **Pattern markers fire on real candles** — confirm Shooting Star / Hanging Man / Bearish Engulfing / Doji markers appear at the right candle when criteria match.
   - **Live-tape gate updates** still work end-to-end: desk shows "LIVE · Ns", gates flip without touching manual tape.

2. **iPhone-first UX validation on real device.** The boiler-room redesign needs market-hours testing on `ZZZ`. Verify the hard-exit takeover fires at 15:50 ET. Verify gate-detail sheets open and dismiss cleanly. Verify the ticker strip readout updates as tape entry changes. Verify Plex renders correctly (fonts now bundled).

4. **Disclaimer + privacy — DONE 2026-05-14.**
   - `FirstLaunchDisclaimerView` confirmed wired (gated by `hasAcceptedDisclaimer` UserDefaults key).
   - Disclaimer copy scrubbed of "win rate" language (4 occurrences replaced with "strategies/examples are educational").
   - Privacy Policy updated to acknowledge optional Finnhub/Polygon/Schwab/Yahoo network requests when user enables Live Mode (device → provider direct, never through us). Keychain disclosed as the API key store. iOS + macOS storage both called out (previously macOS-only).
   - `PrivacyInfo.xcprivacy` already correct (UserDefaults CA92.1, no tracking, no collected data types).
   - `AboutLegalView` hard-coded "v3.0" / "3.0.0" replaced with `Bundle.main.infoDictionary` reads.

5. **App Review compliance scrub — DONE 2026-05-14.**
   - 4 dead view files deleted: `StrategiesListView.swift` (16 fabricated win-rate rows), `ArrowSignalViews.swift` (reliability % display), `VXXTradingDashboard.swift` (legacy pre-redesign dashboard), `PatternIndicatorViews.swift` (confidence %). All only referenced by their own previews or the dead VXXTradingDashboard. pbxproj cleaned.
   - `VXXTradingWindow.winRate` getter (unused, had "highest probability" comment + fabricated 70% for lunch) removed.
   - `MarketDataEntry.ratioTier` now routes through `StrategySpec.tier(forRatio:).label` — drops the "(Rating: 1/2/3)" notation that wasn't in the doc.
   - `TechnicalIndicators.RatioTier.displayName` cleaned of "(Rating: N)".
   - `APP_STORE_CONNECT_COPY.md`, `AppStoreMetadata.md`, `MARKETING.md`, `LAUNCH_GUIDE.md`, `LAUNCH_PLAN.md` all scanned — already clean. No "win rate / highest probability / guaranteed / will spike" language in public-facing copy.

6. **Test target.**
   - Add an XCTest target.
   - Cover: time-window logic in `TimeManager`, `DeskState.current(...)` derivation across boundary times, `VXXStrategyState.firstFailingGateIndex`, ratio threshold tiers, prompt placeholder substitution.
   - One UI smoke test: launch → enter tape → see gates update → open Settings → toggle data source.

7. **App Store assets.**
   - **Screenshot capture script — DONE 2026-05-14.** `scripts/capture_app_store_screenshots.sh` ported from CloudBreak's (the only one in the family that consistently shipped clean shots). Native Swift build via `xcodebuild`; iPhone 17 Pro Max simulator UDID `AD634430-4C6A-417F-B66D-004DA65217D6`; status bar pinned to 9:41 / full battery / full wifi. Captures 6 shots into `app_store_assets/screenshots/iphone-6.9/`: desk cleared, gate detail, fullscreen chart, tape entry, hard exit, settings audit. Run with `./scripts/capture_app_store_screenshots.sh` from repo root.
   - **Still TODO:** actually run the script and curate the shots. Hard-exit shot requires being at 15:55-16:10 ET (or wiring a debug env-var time override into `DeskState.current` — optional follow-up).
   - **Still TODO:** iPad + Mac screenshots — terminal layout (left rail + chart + right rail) with a populated tape. Different script needed; CloudBreak's was iPhone-only.
   - **Still TODO:** verify icon at small sizes — the SteelDeskMark is now amber-on-black.
   - **Still TODO:** confirm support URL, marketing URL, privacy URL, subtitle, keywords, reviewer notes (live in `APP_STORE_CONNECT_COPY.md`).

8. **Signing and archive.**
   - Set team / signing / capabilities / version / build number.
   - Run archive for iOS and macOS.
   - Upload to TestFlight.
   - Fix any App Store Connect processing warnings.

## P1 — Hardening

1. **Real-device testing on iPhone, iPad, Apple silicon Mac.** Intel Mac only if still required.
2. **Build warnings.** `xcodebuild Debug` should be warning-free. Run Xcode Analyze. Review entitlements.
3. **Keychain for API keys.** Currently `FinnhubProvider`/`PolygonProvider` read from `UserDefaults` for the scaffolding. Move to `KeychainService` when network code lands.
4. **Data lifecycle.** Document what is stored locally. Add a "Reset Local Data" control in Settings if needed. Confirm uninstall behavior matches the privacy policy.
5. **Background monitoring.** Re-check the actual background behavior on iOS 18 — the existing toggle exists, but verify it actually wakes the app for the institutional window check.

## P2 — Post-launch

1. **watchOS punch list.** Companion only. Trading-window reminders, risk timer, alert glance. No order entry.
2. **iPad optimization.** The Mac terminal layout already works on iPad — review touch-target sizes.
3. **Mac App Store polish.** Confirm menu commands. Decide whether the GitHub `UpdateChecker` should be disabled for App Store builds.
4. **Docs consolidation.** `LAUNCH_GUIDE.md`, `LAUNCH_PLAN.md`, `MARKETING.md`, and `AppStoreMetadata.md` overlap with `APP_STORE_CONNECT_COPY.md`. Pick one source of truth and delete the others or mark them as superseded.
