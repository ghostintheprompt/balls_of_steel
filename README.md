<p align="center">
  <img src="steel_trading_desk.png" width="520">
</p>

# Steel Trading Desk

Native multiplatform discipline desk for discretionary VXX / SPY options traders. — v1.0

![License](https://img.shields.io/github/license/ghostintheprompt/balls_of_steel)
![Platform](https://img.shields.io/badge/platform-iOS%20|%20iPadOS%20|%20macOS-blue)

Steel Trading Desk is a local-first, accuracy-first desk for a personal VXX/VIX/VWAP playbook. The whole app is one screen: a single command verb (NO TRADE / WAIT / CLEARED) on top of a five-condition setup check. Its value is attention management plus data honesty: let the app watch the setup while you multitask, then alert only when the feed is live, fresh, sourced, complete, and worth a human look. The intended workflow is phone alert plus Thinkorswim/Schwab chart templates side by side, then manual execution after a fast human check. No brokerage automation, no autopilot, no fantasy fills.

## Core Features

| Feature | Description |
| :--- | :--- |
| **Five-condition setup check** | Volume → valid time window → VXX/VIX ratio + divergence direction → VWAP / key level → rejection pattern. Every condition is visible; nothing is hidden inside a summary row. |
| **Accuracy-gated alerts** | Alerts fail closed. Stale, delayed, simulated, partial, disconnected, or unverifiable data must be labeled and blocked. |
| **Tape entry** | Fast manual input from ThinkOrSwim, Schwab, or your primary charting platform. |
| **Schwab dev access** | Narrow-audience by design: enter your own Schwab developer app key and app secret, stored locally in Keychain. Schwab market-data streaming is the target feed. No shared secret ships with the app. |
| **Feed suitability checks** | Live data has to prove it is suitable for this system: correct symbols, source timestamps, freshness, heartbeats, complete VXX/VIX/VWAP inputs, and fail-closed alert behavior. |
| **Schwab-gated chart** | Native chart surface uses verified Schwab live candles only. Without Schwab OAuth it shows a locked source state, not public delayed data. |
| **Session-close takeover** | From 16:10 to the 16:15 ET extended close, the phone prioritizes close-management rules, open risk, and the alert-session countdown. |
| **Second Read** | A structured prompt for outside-model sanity checks, always available from live tape data — not just during scheduled windows. Never the green light. |
| **Trade Journal** | Every trade you take is logged automatically the moment you take it: entry price, VWAP, ratio, VIX, trading window, and a screenshot of the desk at that exact moment — a real record to check against later, not a memory of what you thought you saw. |
| **Boiler-room visual system** | CRT amber on near-black, IBM Plex everything, hairline borders, sharp corners. |
| **Local-first privacy** | Zero telemetry. Zero analytics. All data stays on your hardware. |

## Installation

### App Store (Recommended)
1. Download **Steel Trading Desk** from the iOS or Mac App Store.
2. The desk is free. No paywall.

### Build from Source

```bash
git clone https://github.com/ghostintheprompt/balls_of_steel.git
cd balls_of_steel
open Steel_Trading_Desk.xcodeproj
```

In Xcode, select the **Steel_Trading_Desk** scheme, target **Any iOS Device** or **My Mac**, and press `Cmd + R`. See `docs/BUILD.md` for full dev setup including IBM Plex font bundling and optional `.env` for API key seeding.

## Usage

1. **Tape:** Pull VXX, VIX, volume, VWAP, key level, pattern, and window from your charting platform — or use verified live market data when available.
2. **Sequence:** Watch the setup check on the Desk. Don't act until every condition clears.
3. **Chart:** Use the native chart only when Schwab live candles are connected; otherwise the chart explicitly shows what is missing.
4. **Prompt:** Use the Second Read panel only when a structured outside read helps.
5. **Execute:** Take a quick look to reject nonsense, then place trades manually in Thinkorswim, Schwab, or your own broker. Steel never places orders.
6. **Manage:** Track active risk through the 16:15 ET extended close; the app takes over the phone screen during the final close-management window.

## Privacy

**Local-only. No telemetry. No analytics. No tracking.**

Steel Trading Desk does not collect, store, or transmit any of your personal information or trading data. All tape entries stay in local storage; user-supplied Schwab developer credentials and API keys live in the platform Keychain; outbound calls go directly from your device to the services *you explicitly configure*. See `docs/PRIVACY.md` for the full disclosure.

---

Built by MDRN Corp — [mdrn.app](https://mdrn.app/steel)
