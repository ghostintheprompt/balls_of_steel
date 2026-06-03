# Steel Trading Desk: Privacy Policy

**Effective Date:** May 25, 2026

## 1. What we collect

Nothing. Steel Trading Desk does not collect, store, or transmit personal information, trading data, account credentials, telemetry, analytics, crash reports, or device identifiers to any server we control.

## 2. Local-only storage

All data you enter into the app is stored exclusively on your device:

- **Tape entries** (VXX/VIX/volume/VWAP/level/pattern/window/news) live in `UserDefaults` on the device.
- **API keys and Schwab developer credentials** are stored in the platform Keychain, scoped to this app and your device. Steel ships with no shared Schwab secret; users with Schwab developer access enter their own app key and app secret.
- **Trade history / journal** lives in local app storage.

When you delete the app, all of this is removed by the operating system.

## 3. Outbound network calls (third-party services)

The app makes outbound HTTPS calls only to services *you explicitly configure* in Settings → Data Source. We never proxy these calls through our servers; they go directly from your device to the provider:

| Provider | Endpoint | Purpose | Required? |
|---|---|---|---|
| TradingView | `s3.tradingview.com`, `tradingview.com` | Embedded chart widget (15-min delayed quotes) | Used whenever the chart is visible. No account / no auth. |
| Finnhub | `finnhub.io`, `ws.finnhub.io` | Real-time VXX / VIX quote data | Only if you provide a Finnhub API key |
| Polygon.io | `api.polygon.io`, `socket.polygon.io` | Real-time quote data (alternative provider) | Only if you provide a Polygon API key |
| Schwab | `api.schwabapi.com`, Schwab streamer endpoint | Real-time market-data quotes for accuracy-gated alerts | Only if you complete the Schwab OAuth flow |
| Yahoo Finance (unofficial) | `query1.finance.yahoo.com` | Delayed quote fallback | Only if you select Yahoo as your provider |

Each provider's privacy policy governs how *they* handle the requests they receive. We do not share your API keys with anyone, ever.

Steel Trading Desk does not use broker APIs to place orders, read balances, manage positions, or automate trading. Any live-data provider is used only to evaluate the app's on-device entry gates and alert freshness. You place any trade manually in your own brokerage platform.

## 4. No telemetry, no third-party analytics

We do not embed Google Analytics, Mixpanel, Firebase, Sentry, App Center, Crashlytics, or any other tracking or analytics SDK. Apple's standard, opt-in crash reporting (which goes to Apple, not to us) is the only diagnostic flow.

## 5. App Tracking Transparency

The app does not track you across other apps or websites. We do not request permission under Apple's App Tracking Transparency framework because we have nothing to track.

## 6. Children

This app is for adult traders. We do not knowingly collect or process information from anyone under 18.

## 7. Changes to this policy

If material changes are made (e.g., adding a new third-party data provider), this document will be updated and the Effective Date bumped. Continuing to use the app after a material change constitutes acceptance.

## 8. Contact

Questions about this policy: `support@mdrn.app` (placeholder — confirm/replace with the address you want surfaced before App Store submission).
