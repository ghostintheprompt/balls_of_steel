<p align="center">
  <img src="steel_trading_desk.png" width="520">
</p>

# Steel Trading Desk

Native multiplatform discipline desk for discretionary VXX / SPY options traders. — v1.0

![License](https://img.shields.io/github/license/ghostintheprompt/balls_of_steel)
![Platform](https://img.shields.io/badge/platform-iOS%20|%20iPadOS%20|%20macOS-blue)

Steel Trading Desk is a local-first, manual-first desk for the VXX/VIX/VWAP playbook. The whole app is one screen: a single command verb (NO TRADE / WAIT / CLEARED) on top of a four-gate sequence. No signals, no autopilot, no fantasy fills.

## Core Features

| Feature | Description |
| :--- | :--- |
| **Four-gate sequence** | Volume + window → VXX/VIX ratio + divergence direction → VWAP / key level → rejection pattern. Current blocker always highlighted. |
| **Tape entry** | Fast manual input from ThinkOrSwim, Schwab, or your primary charting platform. |
| **Live data (optional)** | Bring your own Finnhub / Polygon / Schwab / Yahoo API key. Auto-populates price + volume gates every 30s. Keys live in the platform Keychain. Never proxied. |
| **Embedded chart** | TradingView Advanced Chart (VWAP + SMA + Volume) directly in the desk. 15-min delayed disclosure built in. |
| **Hard-exit takeover** | Between 15:50 and 16:10 ET, the iPhone screen is replaced by a red countdown to 15:55, open positions, and three exit rules. |
| **Second Read** | Copy a structured prompt for outside-model sanity checks. Never the green light. |
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

1. **Tape:** Pull VXX, VIX, volume, VWAP, key level, pattern, and window from your charting platform — or configure live data in Settings → Data Source.
2. **Sequence:** Watch the four-gate spine on the Desk. Don't act until the current blocker clears.
3. **Chart:** Use the embedded TradingView chart for context.
4. **Prompt:** Use the Second Read panel only when a structured outside read helps.
5. **Execute:** Place trades manually on your broker.
6. **Manage:** Track active risk and obey the 15:55 ET hard exit (the app takes over the screen for the last 20 minutes).

## Privacy

**Local-only. No telemetry. No analytics. No tracking.**

Steel Trading Desk does not collect, store, or transmit any of your personal information or trading data. All tape entries stay in local storage; API keys live in the platform Keychain; outbound calls go directly from your device to the third-party services *you explicitly configure* (Finnhub / Polygon / Schwab / Yahoo / TradingView). See `docs/PRIVACY.md` for the full disclosure.

---

Built by MDRN Corp — [mdrn.app](https://mdrn.app/steel)
