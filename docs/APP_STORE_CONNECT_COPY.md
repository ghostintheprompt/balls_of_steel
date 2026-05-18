# App Store Connect Copy

Last updated: May 16, 2026

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

A boiler-room VXX/VIX/VWAP discipline desk. Four gates, one verb, hard exit at 15:55. No signals, no autopilot, no fantasy fills.

### Description

Steel Trading Desk is a local-first iPhone, iPad, and Mac utility for traders who want a hard discipline layer between their charts and their broker. The desk is one screen: a single command verb (NO TRADE / WAIT / CLEARED) on top of a four-gate sequence that has to clear in order before any entry is on the table.

This is not a signal seller, broker, trading bot, or magic system. Steel keeps the trade in order:

1. Volume and VXX time window
2. VXX/VIX ratio and divergence direction
3. VWAP or key level
4. Rejection pattern
5. Manual execution and risk management

Enter the tape from your charting or brokerage platform, watch the gates clear in order, view an embedded chart for context, copy a structured prompt when a second read helps, and execute manually on your broker.

Built for one purpose: fewer forced trades, cleaner entries, stricter exits.

Key features:

- **Four-gate sequence** with the current blocker always highlighted in amber.
- **Native chart on iPhone** (Swift Charts): VWAP, 20-period and 50-period SMAs, time-window stripes, volume sub-panel, VXX/VIX ratio tier band, candlestick pattern markers, tap-to-OHLCV. TradingView Advanced Chart embed on Mac and iPad with VWAP, SMA, and volume overlays.
- **Tape entry** for fast manual input of VXX, VIX, volume, VWAP, key level, pattern, time window, and news.
- **Hard-exit takeover** between 3:50 and 4:10 PM ET — the screen replaces itself with a giant countdown to 15:55, the open position summary, and the three exit rules.
- **Second Read** structured prompts to paste into the model of your choice when you want an outside check.
- **Risk discipline** — active-risk and close-management surfaces for keeping the trade honest.
- **Local-first privacy** — no accounts, no telemetry, no tracking. Platform Keychain for any future credential storage.

The full VXX/VIX/VWAP workflow, chart, prompts, and risk tools are available without an in-app purchase.

Important: Steel Trading Desk is an educational utility. It does not execute trades, manage funds, provide financial advice, or connect as a brokerage service. You are responsible for your own trading decisions and risk.

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

1. iPhone Desk default — ticker strip + NEXT MOVE verb + 4-gate stack with amber blocker highlight
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

Steel Trading Desk is a manual-entry educational utility for discretionary VXX/VIX volatility traders. It does not execute trades, manage funds, provide financial advice, or automate brokerage activity.

v1.0 ships with no live-data integration and no API key configuration required. All inputs are entered manually by the user; all execution happens on the user's own brokerage account, outside this app. The Settings → Data Source and Broker cards display informational placeholder copy explaining that a future Schwab Trader API integration (with per-user OAuth on the user's own Schwab account) is pending — these cards have no interactive controls in v1.0.

The embedded TradingView chart on Mac and iPad loads public delayed data and requires no account. The iPhone uses native Swift Charts and does not make any chart-related network calls.

Suggested review path:

1. Open the app, accept the first-launch disclaimer.
2. Go to Tape and enter sample VXX, VIX, volume, VWAP, and pattern values.
3. Return to Desk and verify the four-gate sequence updates in order; the NEXT MOVE verb cycles `WAIT` → `WAIT LEVEL` → `WAIT PATTERN` → `CLEARED`.
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
