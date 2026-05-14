# App Store Metadata: Steel Trading Desk

## App Information
*   **App Name:** Steel Trading Desk
*   **Subtitle:** Native Volatility Analysis Tool
*   **Category:** Finance / Education
*   **SKU:** `MDRN-STEEL-DESK-001`
*   **Bundle ID:** `app.mdrn.steel`
*   **Copyright:** © 2026 MDRN Corporation

## Marketing Text
*   **Promotional Text:** A boiler-room VXX/VIX/VWAP discipline desk. Four gates, one verb, hard exit at 15:55. No signals, no autopilot, no fantasy fills.
*   **Keywords:** VXX,VIX,VWAP,SPY,options,trading,volatility,tape,risk,journal,finance,stocks
*   **Support URL:** https://mdrn.app/steel/support
*   **Marketing URL:** https://mdrn.app/steel
*   **Privacy Policy URL:** https://mdrn.app/steel/privacy

## App Description
Steel Trading Desk is a local-first iPhone, iPad, and Mac discipline desk for discretionary traders who fade stretched VXX/VIX premium expansion.

The desk is one screen: a single command verb (NO TRADE / WAIT / CLEARED) on top of a four-gate sequence that has to clear in order before any entry is on the table.

This is not a signal seller, broker, trading bot, or magic system. Steel keeps the trade in order:

1. Volume and VXX time window
2. VXX/VIX ratio and divergence direction
3. VWAP or key level
4. Rejection pattern
5. Manual execution and risk management

Enter the tape from your charting or brokerage platform, watch the gates clear, embed a TradingView chart for context, copy a structured prompt when a second read helps, and execute manually on your broker. Optional live-data integration via your own Finnhub, Polygon, Schwab, or Yahoo API key auto-populates the price and volume gates every 30 seconds; pattern, level, and news stay manual.

Built for one purpose: fewer forced trades, cleaner entries, stricter exits.

Key features:

- **Four-gate sequence**, with the current blocker always highlighted.
- **Embedded TradingView chart** with VWAP, SMA, and Volume overlays.
- **Hard-exit takeover** automatically replaces the screen 15:50-16:10 ET with a giant countdown to 15:55 and your open position summary.
- **Live-data integration** optional, BYO API key, never proxied.
- **Second Read** structured prompts for outside-model sanity checks.
- **Local-first privacy:** no accounts, no telemetry, no tracking.

The full workflow, chart, prompts, and risk tools are available without an in-app purchase.

Important: Steel Trading Desk is an educational utility. It does not execute trades, manage funds, provide financial advice, or connect as a brokerage service. You are responsible for your own trading decisions and risk.

## Reviewer Notes
Steel Trading Desk is an educational discipline utility. It does not manage funds, provide financial advice, execute trades, or automate brokerage activity.

The app is manual-first. On first launch, no external service is configured and the entire desk is exercised by manual tape entry. The reviewer can verify the full gate sequence and hard-exit behavior without any account.

Optional live data uses user-supplied API keys (Finnhub / Polygon / Schwab / Yahoo) stored in the platform Keychain. There is no proxy server; all calls go directly from the device to the provider. Embedded TradingView chart loads delayed public data and requires no account.

Suggested review path:
1. Open the app, accept the disclaimer.
2. Go to Tape and enter sample VXX/VIX/VWAP/volume values.
3. Return to Desk and verify the four-gate sequence updates in order.
4. Open Settings → Data Source to inspect the provider picker (no key needed for review).
5. Open Risk to inspect active-risk and close-management surfaces.

## App Store Connect Paste Sheet
Use `docs/APP_STORE_CONNECT_COPY.md` for the field-by-field paste sheet matching the version page.

## Privacy Manifest (PrivacyInfo.xcprivacy)
*   **Tracking:** No
*   **Data Collection:** None
*   **Required Reasons API:** UserDefaults (Category CA92.1) — used only for local user preferences (alert volume, time settings, last tape entry).
*   **Outbound third-party calls:** TradingView (chart, no auth), and optionally Finnhub / Polygon / Schwab / Yahoo when the user provides an API key. Disclosed in `docs/PRIVACY.md`.
