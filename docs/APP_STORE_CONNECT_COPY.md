# App Store Connect Copy

Last updated: May 13, 2026

Use this as the paste sheet for App Store Connect version `1.0`.

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
2. VXX/VIX ratio
3. VWAP or key level
4. Rejection pattern
5. Manual execution and risk management

Enter the tape from your charting or brokerage platform, check the gates in sequence, embed a TradingView chart for context, copy a structured prompt when a second read helps, and execute manually on your broker.

Built for a simple purpose: fewer forced trades, cleaner entries, stricter exits.

Key features:

- VXX sequence: volume/window, VXX/VIX ratio, VWAP/key level, and pattern gates in order, with a clearly marked blocker on whichever gate is failing right now.
- Tape entry: fast manual input for the chart values that matter.
- Embedded chart: TradingView Advanced Chart with VWAP, SMA, and volume overlays directly in the desk.
- Hard-exit takeover: between 3:50 and 4:10 PM ET the screen replaces itself with a giant countdown to 15:55, your open position summary, and the three exit rules.
- Second Read: structured prompts you paste into the model of your choice when you want an outside check.
- Risk discipline: active-risk and close-management surfaces for keeping the trade honest.
- Local-first privacy: no accounts, no telemetry, no tracking.

The full VXX/VIX/VWAP workflow, chart, prompts, and risk tools are available without an in-app purchase.

Important: Steel Trading Desk is an educational utility. It does not execute trades, manage funds, provide financial advice, or connect as a brokerage service. You are responsible for your own trading decisions and risk.

### Keywords

VXX,VIX,VWAP,SPY,options,trading,volatility,tape,risk,journal,finance,stocks

### URLs

| Field | Value |
| :--- | :--- |
| Support URL | https://github.com/ghostintheprompt/steel-trading-desk/issues |
| Marketing URL | https://mdrn.app/steel |

### Version And Copyright

| Field | Value |
| :--- | :--- |
| Version | 1.0 |
| Copyright | © 2026 MDRN Corporation |
| Routing App Coverage File | Leave blank |

## Previews And Screenshots

Upload iPhone screenshots first. The first three should tell the actual workflow, not a marketing story.

1. Desk sequence: volume/window, ratio, VWAP/key level, pattern, decision.
2. Tape entry: manual VXX/VIX/VWAP inputs with key level and pattern toggles.
3. Risk discipline: active risk or close-management surface.

Add iPad and Mac screenshots after the iPhone flow is locked. Apple Watch is only a punch-list item for now; do not upload Watch screenshots until there is a real watchOS target.

## App Review Information

### Sign-In Information

Uncheck `Sign-in required`. The app has no account system.

### Contact Information

Fill with MDRN Corporation contact details in App Store Connect.

### Review Notes

Steel Trading Desk is an educational market-analysis and trading-discipline utility. It does not manage funds, provide financial advice, execute trades, or automate brokerage activity.

The app is manual-first. Users enter chart context themselves, including VXX, VIX, volume, VWAP/key level, time window, and pattern confirmation. The app then presents a local checklist-style workflow and risk-management reminders.

No account is required. No purchase is required. No brokerage credentials are required for review.

Suggested review path:
1. Open the app.
2. Go to Tape and enter sample VXX/VIX/VWAP values.
3. Return to Desk and verify the sequence gates update.
4. Open Risk to inspect active-risk and close-management behavior.

## Build

Select the uploaded `1.0` build after Xcode/TestFlight processing completes.

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
