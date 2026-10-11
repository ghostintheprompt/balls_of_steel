<p align="center">
  <img src="steel_trading_desk.png" width="520">
</p>

# Steel Trading Desk

Native multiplatform discipline desk for discretionary VXX / SPY options traders.

![License](https://img.shields.io/github/license/ghostintheprompt/balls_of_steel)
![Platform](https://img.shields.io/badge/platform-iOS%20|%20iPadOS%20|%20macOS-blue)

**Public release — 2026-10-11.** First built and verified live against real Schwab
market data, during actual trading hours, on 2026-09-08 — not just compiled and assumed
correct. Made public a month later, after a real security/accuracy pass (no committed
secrets, no account-balance screenshots, docs checked against what the code actually
does). This is a personal tool, not a product: running it requires your
own Schwab Developer Portal registration (app key/secret entered locally,
stored in Keychain), since Schwab doesn't allow a shared credential to ship
inside an app. That's a real limitation on distributing this as something
other than source code — and it's not really a gap worth closing. A
modifiable shell that does nothing more than what building your own already
proves doesn't add anything; the point was building a real alert system for
one specific setup, disciplined enough to stop second-guessing a trade in
the moment, not shipping a product.

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
| **Trade Journal** | Every trade you take is logged automatically the moment you take it: entry price, VWAP, ratio, VIX, trading window, and a screenshot of the desk at that exact moment — a real record to check against later, not a memory of what you thought you saw. Wired and real in code (`SignalMonitor` calls it directly); not yet confirmed end-to-end against a live trade, so watch your first real entry/close to make sure it behaves as described. |
| **Boiler-room visual system** | CRT amber on near-black, IBM Plex everything, hairline borders, sharp corners. |
| **Local-first privacy** | Zero telemetry. Zero analytics. All data stays on your hardware. |

## Known issues

Disclosed on purpose, not hidden — this is a real personal tool, traded with for real, not a finished product:

- **Crash bug, audited and likely fixed, not yet re-proven live:** a `SIGSEGV` in `MarketDataService.handleQuoteUpdate` hit once during a live session (2026-09-08) — a thread-safety issue from concurrent Schwab-polling loops mutating a shared dictionary. Code audit (2026-10-11) found every caller that touches `MarketDataService`'s state (`SchwabService`, `LiveTapeService`, `SignalScanner`, `ExitSignalService`, `SignalMonitor`) is `@MainActor`-isolated, and `SchwabService.subscribeToQuotes` explicitly hops via `MainActor.run` before delivering quotes. The race this crash needed shouldn't be reachable anymore. Not re-confirmed against a live multi-hour session, since a one-time race isn't reproducible on demand — if you hit it again, that's a real finding, open an issue.
- **Schwab quirks you'll likely hit yourself:** masked error responses, symbol drift (`$VIX` not `$VIX.X`), and date-range gotchas around incomplete trading days — see `docs/SCHWAB_API_READINESS.md` for the real debugging history. Building this out meant pushing through each one by hand; running your own fork means you may have to do the same.
- **Refresh-token rotation unconfirmed:** whether Schwab actually rotates the refresh token with a fresh 7-day window on each silent refresh, or hard-expires 7 days after original auth regardless, hasn't been confirmed — only observable by watching real usage over time.

## Installation

There's no App Store listing — this only runs built from source, on your
own machine, with your own Schwab developer credentials.

```bash
git clone https://github.com/ghostintheprompt/balls_of_steel.git
cd balls_of_steel
cp .env.example .env   # then fill in your Schwab app key/secret
```

### Launching (macOS)

```bash
./scripts/run_local.sh
```

This builds, kills any already-running instance, and launches the built
binary directly — **not** `open Steel_Trading_Desk.app` and not Xcode's own
`Cmd + R`. Neither of those forwards this shell's `.env` variables to the
launched process (a real macOS quirk, not a bug here), so a Cmd+R launch
starts the app with no Schwab credentials seeded and live mode silently
never connects. `run_local.sh` is the only launch path that actually seeds
`SCHWAB_APP_KEY` / `SCHWAB_APP_SECRET` on first run.

Xcode itself is still where you'd open the project to browse or edit code
(`open Steel_Trading_Desk.xcodeproj`), and iOS/iPadOS builds do go through
Xcode's own Run button as normal — this launch-script requirement is
specific to getting live Schwab data working on macOS. See `docs/BUILD.md`
for full dev setup including IBM Plex font bundling.

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

Built by Michael Subrizi — [github.com/ghostintheprompt](https://github.com/ghostintheprompt)
