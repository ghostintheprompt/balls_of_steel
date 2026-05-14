# Steel Trading Desk Release Punch List

Last updated: May 13, 2026 (after the boiler-room redesign pass).

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

## Remaining P0 — Release Blockers

1. **Validate live-tape end-to-end with a real Finnhub key.** The provider + LiveTapeService are wired but unverified against the actual Finnhub API. Drop a key into Settings → Data Source, flip "Auto-populate from provider", confirm the desk shows a "LIVE · Ns" indicator and gates update without touching manual tape. Likely friction: VIX symbol (`^VIX` may need to be `TVC:VIX` or similar on Finnhub; quick fix in `LiveTapeService.fetchAndPersist` if so).

2. **iPhone-first UX validation on real device.** The boiler-room redesign needs market-hours testing on `ZZZ`. Verify the hard-exit takeover fires at 15:50 ET. Verify gate-detail sheets open and dismiss cleanly. Verify the ticker strip readout updates as tape entry changes. Verify Plex renders correctly (fonts now bundled).

4. **Disclaimer + privacy.**
   - Confirm the first-run `DisclaimerView` still appears and matches the new tone.
   - Confirm "not financial advice" + "manual execution only" remain in the on-app disclaimer and the App Store description.
   - Confirm `PrivacyInfo.xcprivacy` matches actual API usage (UserDefaults Category CA92.1).

5. **App Review compliance scrub.**
   - Search Strings/Views for any remaining "win rate %", "highest probability", "ready to execute", "signal" framing in primary UI. Helper internals can keep these names; visible labels cannot.
   - Confirm the App Store description never claims a directional recommendation ("VXX is going to fade") — only describes the discipline layer.

6. **Test target.**
   - Add an XCTest target.
   - Cover: time-window logic in `TimeManager`, `DeskState.current(...)` derivation across boundary times, `VXXStrategyState.firstFailingGateIndex`, ratio threshold tiers, prompt placeholder substitution.
   - One UI smoke test: launch → enter tape → see gates update → open Settings → toggle data source.

7. **App Store assets.**
   - iPhone screenshots (required sizes): Desk default, gate-detail sheet, hard-exit takeover.
   - iPad + Mac screenshots: terminal layout (left rail + chart + right rail), with a populated tape.
   - Verify icon at small sizes — the SteelDeskMark is now amber-on-black.
   - Confirm support URL, marketing URL, privacy URL, subtitle, keywords, reviewer notes.

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
