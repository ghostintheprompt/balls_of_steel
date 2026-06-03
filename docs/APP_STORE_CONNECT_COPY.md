# App Store Connect Copy

Last updated: May 25, 2026

Canonical paste sheet for App Store Connect version `1.0`. **Single source of truth for App Store metadata.** `MARKETING.md` and `AppStoreMetadata.md` were merged into this file on 2026-05-16 and deleted. Companion runbook: `docs/LAUNCH_GUIDE.md`.

## App Information

| Field | Value |
| :--- | :--- |
| App Name | Steel Trading Desk |
| Subtitle | Native Volatility Analysis Tool |
| SKU | MDRN-STEEL-DESK-001 |
| Bundle ID | app.mdrn.steel |
| Primary Category | Finance |
| Secondary Category | Education |
| Content Rights | The app does not contain, show, or access third-party content. |
| Age Rating Direction | No unrestricted web access. No gambling. Finance/education utility only. |

## Version Information

### Promotional Text

Accuracy-first VXX/VIX/VWAP entry desk. Five-condition setup check, one verb, hard exit at 15:55. No brokerage automation, no fantasy fills, no alert unless the data is live, fresh, sourced, and complete.

### Description

Steel Trading Desk is a local-first iPhone, iPad, and Mac utility for traders who want an accuracy-first discipline layer between live market data and manual broker execution. It is intentionally narrow: a VXX/VIX/VWAP setup checker for traders who already use their own chart templates and want a phone/iPad/Mac desk running the same read in parallel. The desk is one screen: a single command verb (NO TRADE / WAIT / CLEARED) on top of a five-condition setup check. All conditions have to clear before any entry is worth a human look.

This is not a signal seller, broker, trading bot, or magic system. Its value is data honesty plus attention management: the app watches a personal VXX/VIX/VWAP setup so the trader can multitask, then interrupts only when the full read is worth checking manually. If data is stale, delayed, simulated, partial, or unverifiable, the app must say so and block the alert rather than pretend.

Steel keeps the trade in order:

1. Volume and VXX time window
2. VXX/VIX ratio and divergence direction
3. VWAP or key level
4. Rejection pattern
5. Manual execution and risk management

Enter the tape from your charting or brokerage platform, or configure Schwab Developer Access with your own Schwab developer app key and app secret. Watch the conditions clear in order, view an embedded chart for context, copy a structured prompt when a second read helps, take a quick look to reject bad reads, and execute manually on your broker.

Built for one purpose: fewer forced trades, cleaner entries, stricter exits, and alerts that fail closed when the data is not good enough.

Key features:

- **Five-condition setup check** — volume, valid window, VXX/VIX ratio, VWAP/key level, and rejection pattern. Every condition is visible; nothing is hidden inside a summary row.
- **Accuracy-gated alerts** — alerts are valid only when the app can verify the feed source, timestamp freshness, and required VXX/VIX/VWAP inputs. No stale, delayed, simulated, partial, or unverifiable data is allowed to masquerade as actionable.
- **Native chart on iPhone** (Swift Charts): VWAP, 20-period and 50-period SMAs, time-window stripes, volume sub-panel, VXX/VIX ratio tier band, candlestick pattern markers, tap-to-OHLCV. TradingView Advanced Chart embed on Mac and iPad with VWAP, SMA, and volume overlays.
- **Tape entry** for fast manual input of VXX, VIX, volume, VWAP, key level, pattern, time window, and news.
- **Schwab Developer Access** — optional user-supplied Schwab app key and app secret stored in the device Keychain. Steel ships with no shared Schwab secret.
- **Feed suitability checks** — live data must prove correct symbols, source timestamps, freshness, complete VXX/VIX/VWAP inputs, and connection health before it can matter.
- **Hard-exit takeover** between 3:50 and 4:10 PM ET — the screen replaces itself with a giant countdown to 15:55, the open position summary, and the three exit rules.
- **Second Read** structured prompts to paste into the model of your choice when you want an outside check.
- **Risk discipline** — active-risk and close-management surfaces for keeping the trade honest.
- **Local-first privacy** — no accounts, no telemetry, no tracking. User-supplied Schwab developer credentials are stored in the platform Keychain.

The full VXX/VIX/VWAP workflow, chart, prompts, and risk tools are available without an in-app purchase.

Important: Steel Trading Desk is an educational entry-discipline utility. It does not execute trades, manage funds, provide financial advice, automate brokerage activity, or connect as a brokerage service. You are responsible for your own trading decisions, order placement, and risk.

### Keywords

VXX,VIX,VWAP,SPY,options,trading,volatility,tape,risk,journal,finance,stocks

### URLs

| Field | Value |
| :--- | :--- |
| Support URL | https://mdrn.app/steel/support |
| Marketing URL | https://mdrn.app/steel |
| Privacy Policy URL | https://mdrn.app/steel/privacy |

### Version And Copyright

| Field | Value |
| :--- | :--- |
| Version | 1.0 |
| Copyright | © 2026 MDRN Corporation |
| Routing App Coverage File | Leave blank |

## Previews And Screenshots

Upload iPhone screenshots first. The first three should tell the actual workflow, not a marketing story. Screenshot capture script: `scripts/capture_app_store_screenshots.sh` (iPhone-only currently; iPad + Mac shots are manual).

Suggested order:

1. iPhone Desk default — ticker strip + NEXT MOVE verb + five-condition stack with amber blocker highlight
2. iPhone gate-detail sheet — big number + tier table + house rule
3. iPhone fullscreen chart sheet — native chart with VWAP / SMA / window stripes / volume panel / ratio tier band / pattern markers
4. iPhone hard-exit takeover — red countdown + open positions + 3 exit rules
5. iPad / Mac terminal — three-column layout with gate spine + chart center + right rail

Screenshot specs:

- **iPhone 6.7":** 1290 × 2796 (or 1284 × 2778)
- **iPhone 6.5":** 1242 × 2688
- **iPad Pro 12.9" (6th gen and later):** 2048 × 2732
- **macOS:** 1280 × 800 minimum

Apple Watch is punch-list only; do not upload Watch screenshots until there is a real watchOS target.

## App Review Information

### Sign-In Information

Uncheck `Sign-in required`. The app has no account system.

### Contact Information

Fill with MDRN Corporation contact details in App Store Connect.

### Review Notes

Steel Trading Desk is an accuracy-first entry-discipline utility for discretionary VXX/VIX volatility traders. It does not execute trades, manage funds, provide financial advice, or automate brokerage activity.

The strategy implemented here is the developer's personal five-condition VXX/VIX/VWAP setup checker. Manual tape entry works without credentials. Settings also includes Schwab Developer Access for users who have their own Schwab developer account; the user can enter an app key/client ID and app secret, which are stored locally in Keychain. The app ships with no shared Schwab secret. All execution happens on the user's own brokerage account, outside this app.

Future live-data builds must fail closed: if the feed is stale, delayed, simulated, partial, disconnected, or unverifiable, the app must label the condition and suppress alerts. The intended workflow is phone alert → quick human review to confirm it is not a bad read → user manually places any order in Thinkorswim/Schwab or another brokerage platform.

The embedded TradingView chart on Mac and iPad loads public delayed data and requires no account. The iPhone uses native Swift Charts and does not make any chart-related network calls.

Suggested review path:

1. Open the app, accept the first-launch disclaimer.
2. Go to Tape and enter sample VXX, VIX, volume, VWAP, and pattern values.
3. Return to Desk and verify the five-condition check updates in order; the NEXT MOVE verb cycles `WAIT` → `WAIT LEVEL` → `WAIT PATTERN` → `CLEARED`.
4. Open Risk to inspect active-risk and close-management surfaces.
5. (Optional) Open Settings → Strategy Audit to verify the in-code rules match the documented strategy.

## Privacy Manifest (PrivacyInfo.xcprivacy)

| Field | Value |
| :--- | :--- |
| Tracking | No |
| Data Collection | None |
| Required Reasons API | UserDefaults (Category CA92.1) — local user preferences only (alert volume, time settings, last tape entry). |
| Outbound third-party calls | TradingView (Mac/iPad chart embed, no auth, no user data sent). No other outbound calls in v1.0. Future: Schwab Trader API (per-user OAuth on user's own account, not yet integrated). |

Full privacy disclosure: `docs/PRIVACY.md`.

## Build

Select the uploaded `1.0` build after Xcode/TestFlight processing completes. Archive procedure in `docs/LAUNCH_GUIDE.md` §7.

## App Store Version Release

Select `Manually release this version` until market-hours testing and final screenshot review are complete. Switch to automatic release only after TestFlight and App Review copy are final.

## Toggles And Sections

| Section | Direction |
| :--- | :--- |
| App Clip | Leave off |
| iMessage App | Leave off |
| Game Center | Leave off |
| Sign-in Required | Off |
| Apple Watch | Punch list only, no target yet |
