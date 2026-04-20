<img src="balls_of_steel.png" width="200">

# Balls of Steel
Native macOS trading desk for discretionary SPY and VXX options trading. — v1.0

![License](https://img.shields.io/github/license/ghostintheprompt/balls-of-steel)
![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Release](https://img.shields.io/github/v/release/ghostintheprompt/balls-of-steel)

Balls of Steel is a local-first, manual-entry desk designed to bridge the gap between chart analysis and rigorous trade management. It focuses on high-probability institutional windows around the market open and close.

## Core Features

| Feature | Description |
| :--- | :--- |
| **Setup Validation** | Multi-factor checks for time windows, volume, VWAP, and volatility. |
| **Signal Intelligence** | Direction-aware alerting (WATCH, ENTRY, EXIT) with real-time monitoring. |
| **Prompt Coach** | Context-aware AI analysis prompts pre-filled with your manual market data. |
| **Close Management** | Automated discipline warnings and hard-exit rules for the market close. |
| **Local-First** | Zero telemetry. Zero latency. All data stays on your hardware. |

## Installation

### DMG Download
1. Go to the [Releases](https://github.com/ghostintheprompt/balls-of-steel/releases) page.
2. Download the latest `Balls_of_Steel.dmg`.
3. Drag `Balls of Steel.app` to your Applications folder.

### Build from Source
1. Clone the repository: `git clone https://github.com/ghostintheprompt/balls-of-steel.git`
2. Open `Balls_of_Steel.xcodeproj` in Xcode.
3. Select the **Balls_of_Steel** scheme and target **My Mac**.
4. Press `Cmd + R` to Build and Run.

## Documentation
- [Broker Integration & Setup Guide](docs/SETUP.md)

## Usage

1. **Analyze:** Perform technical analysis on your primary brokerage platform (ThinkOrSwim, Schwab, etc.).
2. **Input:** Feed the current chart state (Price, Volume%, VIX, Arrow) into the **Manual** tab.
3. **Validate:** Check the **Desk** or **VXX** dashboards for setup validation and signal strength.
4. **Prompt:** Use the **Prompt Coach** to copy pre-filled analysis prompts into your AI of choice.
5. **Execute:** Make your decision and execute manually on your primary platform.
6. **Manage:** Monitor active risk with the **Live** tab and follow close-management alerts.

## Privacy Statement

**Local-only. No telemetry. No bullshit.**
Balls of Steel does not collect, store, or transmit any of your personal information or trading data. All data entered manually remains in your macOS local storage and is deleted when the app is removed.

---

Built by MDRN Corp — [mdrn.app](https://ghostintheprompt.com/articles/balls-of-steel)
