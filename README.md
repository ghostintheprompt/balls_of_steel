<p align="center">
  <img src="steel_trading_desk.png" width="520">
</p>

# Steel Trading Desk
Native multiplatform utility for discretionary SPY and VXX options trading. — v1.0

![License](https://img.shields.io/github/license/ghostintheprompt/steel-trading-desk)
![Platform](https://img.shields.io/badge/platform-iOS%20|%20macOS-blue)

Steel Trading Desk is a local-first, manual-entry desk for the VXX/VIX/VWAP playbook. It keeps the trade in order: volume and window, ratio, VWAP/key level, rejection pattern, then manual execution on your broker.

## Core Features

| Feature | Description |
| :--- | :--- |
| **VXX Sequence** | Volume/window, VXX/VIX ratio, VWAP/key level, and pattern gates in order. |
| **Tape Entry** | Fast manual entry from ThinkOrSwim, Schwab, or your primary charting setup. |
| **Prompt Desk** | Copy a structured question when it helps; no magic, no autopilot. |
| **Risk Discipline** | Close-management and active-risk surfaces for keeping the trade honest. |
| **Local-First** | Zero telemetry. Zero latency. All data stays on your hardware. |

## Installation

### App Store (Recommended)
1. Download **Steel Trading Desk** from the iOS or Mac App Store.
2. The desk is free. No paywall and no locked trading workflow.

### Build from Source
1. Clone the repository: `git clone https://github.com/ghostintheprompt/steel-trading-desk.git`
2. Open `Steel_Trading_Desk.xcodeproj` in Xcode.
3. Select the **Steel_Trading_Desk** scheme.
4. Target **Any iOS Device** or **My Mac** and press `Cmd + R`.

## Usage

1. **Tape:** Pull VXX, VIX, volume, VWAP, level, pattern, and window from your charting platform.
2. **Sequence:** Check the gates in order on the **Desk**.
3. **Prompt:** Use the **Prompt Desk** only when a structured second read helps.
4. **Execute:** Place trades manually on your broker.
5. **Manage:** Track active risk and obey the time exit.

## Privacy Statement

**Local-only. No telemetry. No bullshit.**
Steel Trading Desk does not collect, store, or transmit any of your personal information or trading data. All data entered manually remains in your local storage and is deleted when the app is removed.

---

Built by MDRN Corp — [mdrn.app](https://mdrn.app/steel)
