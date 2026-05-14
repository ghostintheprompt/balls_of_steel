# Steel Trading Desk — Directions for Claude Code

**For:** the next pair-programming session with Claude Code on `Steel_Trading_Desk.xcodeproj`.
**From:** design pass on May 13, 2026.
**Companion file:** `Steel Boiler Room Mockup.html` (design canvas — open it side-by-side with this doc).

---

## TL;DR — what's wrong and what we're doing about it

The app is *functionally* close. The trading method is right (gate sequence, four windows, hard exit). But three things are off:

1. **Tone drift.** The UI reads like a clean fintech SaaS — purple accents, emoji (🔥⚡🎯🧠), "Prompt Coach READY NOW", "Signals Live · ENTRY". The product's actual voice (lifted from your own copy in `VXXTradingDashboard.swift`, `ManualDataEntryView.swift`, `TradingDashboard.swift`) is *grittier*: "wait until vol actually gets loud", "manufactured entries are how people donate", "no trade until the tape earns it." The visual language has to match. Think **boiler room / Bloomberg terminal**, not Robinhood.

2. **The method isn't the UI yet.** The gate sequence (`Vol+Window → Ratio → VWAP → Pattern`) is buried inside the Tape view. It should be the *spine* of every screen. The first thing the trader sees is **which gate is the blocker right now.**

3. **No realtime chart.** A discipline desk without a live chart forces context-switching to ThinkOrSwim every 30 seconds, which is exactly when discipline fails. The chart belongs *in the app*.

---

## Part 1 — Visual / tone direction

### Palette (replace `DesignSystem.swift`)

| Token | Hex | Use |
|---|---|---|
| `bg` | `#000000` | Window background |
| `bg1` | `#050505` | Sidebars, secondary panels |
| `panel` | `#0a0a0a` | Cards |
| `hairline` | `#1a1a1a` | All borders. 1px. Always. |
| `amber` | `#FFB000` | **Primary.** CRT phosphor amber. Headers, active states, the "what to do" color. |
| `long` | `#00D26A` | Gate PASS, position WIN, long direction |
| `short` | `#FF3838` | Gate FAIL, position LOSS, hard-exit, short direction |
| `vwap` | `#67D9FF` | Chart VWAP overlay only |
| `steel` | `#7C8A99` | Neutral metric |
| `text` | `#E8E8E8` | Primary text |
| `text2` | `#A8A8A8` | Secondary |
| `muted` | `#6A6A6A` | Labels |
| `faint` | `#3A3A3A` | Inactive |

**Kill from the codebase:**
- Every purple `#A855F7` / `#8B5CF6`
- Every orange/coral accent (replace with amber)
- All `RoundedRectangle(cornerRadius: 14)` — change to **2px or square**. Boiler-room corners are sharp.
- Every `shadow` and `glow` modifier on cards — flat, hairline borders only.
- Every `.padding(20)` decorative card-in-card-in-card — collapse it.

### Type

- **Sans (UI):** `IBM Plex Sans Condensed` for headlines / display, `IBM Plex Sans` for body. (System fallback: `-apple-system`.)
- **Mono (all numbers, labels, ticker, raw read):** `IBM Plex Mono`. Tracking 1.2–1.6 on uppercase labels.
- **No serifs anywhere.** Kill the `Georgia` from the current mockup.

Font sizes (rough):
- Hero ("NEXT MOVE" command verb): 54 (mac) / 36 (phone), Plex Sans Condensed 800
- Big numbers (chart price, ratio): 16–22, Plex Mono 600
- Labels: 9–11 Plex Mono uppercase, letter-spacing 1.4
- Body: 13 Plex Sans

### Tone rules (apply to every string in the app)

**Yes:**
- Imperatives. "NO TRADE." "CLOSE IT." "WAIT." "STAND DOWN."
- Diagnosis, not exhortation. "Ratio cheap at 1.316." not "Wait for a better setup!"
- House-rule one-liners, italicized: *"Manufactured entries are how people donate."*
- ET clock time + literal countdowns ("HARD STOP IN 04:18"). No "soon", no "approaching".

**No:**
- "Coach", "Pro", "Premium", "Unlock", "Smart"
- Emoji. None. Not 🔥, not ⚡, not 🎯. Use SF Symbols sparingly (only directional/structural — `chevron`, `circle.fill`, `xmark`). No icon for decoration.
- "READY NOW", "TRADING SIGNAL", "ENTRY/WATCH/EXIT" labels — they make the app sound like a signal seller, which contradicts your App Store positioning.
- Win-rate percentages in primary UI. They survive in the docs/method explainer, not on the desk.

---

## Part 2 — Screen rebuild

Open `Steel Boiler Room Mockup.html` in the canvas. Three iPhone artboards + one Mac artboard. Match those.

### Mac terminal (`MainView.swift` regular size class)

Single window, four zones, no tabs:

```
┌─ titlebar (traffic lights + STEEL TRADING DESK · v1.0 · LOCAL) ─────────┐
├─ TICKER STRIP (VXX · VIX · R · SPY · VWAP · VOL · PHASE)  ── 34px ───────┤
│ LEFT RAIL 240w     │  CHART (flex)                  │  RIGHT RAIL 320w  │
│  STEEL DESK        │  toolbar: TF | overlays         │  NEXT MOVE        │
│  ORDER OF ATTACK   │  ───────────                    │  (the verb)       │
│   GATE 1 ✓         │  candles + VWAP + SMA20 +       │  ───────          │
│   GATE 2 ← BLOCKER │  SMA50 + volume + window bands  │  RAW READ table   │
│   GATE 3           │  ───────────                    │  ───────          │
│   GATE 4           │  src · last tick                │  SECOND READ      │
│  TODAY · WINDOWS   │                                 │  (paste-prompt)   │
│  RISK BUDGET       │                                 │  ───────          │
│  EXECUTION (ToS)   │                                 │  ET CLOCK + COUNT │
├─ status: CHART src · QUOTES src · EXEC · HARD STOP ──────── 24px ────────┤
```

**Drop these tabs from the Mac size class:** Manual, VXX, SPY, Live, Settings. Manual is replaced by inline number editors on the right rail. VXX is the default; symbol toggle goes in the chart toolbar (VXX/SPY/VIX). Live (active trades) folds into the right rail under NEXT MOVE when a position is open. Settings → gear icon in titlebar.

The tab bar is **not the navigation** here — the *gate sequence* is. The trader always knows where they are because the next blocker is highlighted on the left.

### iPhone — three states

**State 1 — Desk (default).** Ticker → NEXT MOVE verb → gate stack (full 4 gates, blocker highlighted) → mini chart (120px) → ET clock + next window countdown footer.

**State 2 — Gate detail.** Tapping a gate drills in. Big number (e.g. ratio 1.316), tier table showing where you sit, the one-line house rule, exit button at bottom. No magic. The number and the rule.

**State 3 — Hard exit (3:50–4:10 ET).** The app *takes over*. Red alert band at top, giant red countdown to 15:55 ET, open position summary with live P/L, the three exit rules. This is the only state where the UI is allowed to be loud. Triggered automatically by `TimeManager`.

### What the existing iOS tabs become

| Now | Becomes |
|---|---|
| Desk | Default home (gate-spine layout) |
| Tape | A *sheet* slid up from Desk, not a tab. Tap any gate → tape sheet pre-focused on that gate's fields. |
| Risk | Auto-replaces Desk when a position is open. Otherwise hidden. |
| Settings | Gear in nav bar, single screen, no sub-navigation. |

---

## Part 3 — Realtime chart (the Schwab question)

You asked "the Schwab API works, but is there another way." Yes. Schwab is fine but it's the wrong tool for the chart specifically — it's an execution API repurposed as a quote feed, OAuth-gated, and brittle when the dev portal cycles tokens.

**Recommended stack (tiered, do them in order):**

### Tier 1 — chart UI: TradingView Advanced Chart widget in `WKWebView`

Free, no auth, ships immediately, looks like a real desk. You embed an HTML page with the widget into a `WKWebView` and pin it in `VXXTradingDashboard`. Symbol switching from Swift → JavaScript via `evaluateJavaScript`.

```swift
// ChartWebView.swift
import SwiftUI
import WebKit

struct ChartWebView: UIViewRepresentable {
    let symbol: String  // "AMEX:VXX", "TVC:VIX", "AMEX:SPY"

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.backgroundColor = .black
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        let html = """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>html,body,#tv{height:100%;margin:0;background:#000}</style></head>
        <body><div id="tv"></div>
        <script src="https://s3.tradingview.com/tv.js"></script>
        <script>
        new TradingView.widget({
          autosize: true, symbol: "\(symbol)", interval: "5",
          timezone: "America/New_York", theme: "dark", style: "1",
          locale: "en", toolbar_bg: "#000", enable_publishing: false,
          hide_side_toolbar: true, hide_legend: false, container_id: "tv",
          studies: ["VWAP@tv-basicstudies","MASimple@tv-basicstudies","Volume@tv-basicstudies"]
        });
        </script></body></html>
        """
        web.loadHTMLString(html, baseURL: URL(string: "https://www.tradingview.com"))
    }
}
```

**Caveats:**
- TradingView free widget data is delayed 15 min for VXX (cash equity). Real-time for some forex/crypto. You disclose this in the chart footer (already shown in mockup as "SRC · TRADINGVIEW WIDGET · 15M DELAYED").
- The widget honors TradingView ToS — fine for personal/free use in a free app. If you ever monetize this specific feature you check the embed terms.
- It's an iframe — the app stays a manual desk. No execution flows through it. App Review is fine with this.

### Tier 2 — quotes for the gates: Polygon.io

Tier 1 gives you the chart. The *gates* (Ratio, Vol%, VWAP-vs-price) need a numeric feed.

- **Polygon.io Stocks Starter:** $29/mo, real-time NBBO, REST + WebSocket. Has options chains too.
- **Finnhub free tier:** 60 req/min, real-time US stocks via WebSocket. Free is enough for VXX + VIX + SPY polling every 5s. Options chain is paid.
- Both replace the simulated stubs in `SchwabService.swift`.

Drop a `MarketDataProvider` protocol; let the user pick which backend (or rotate them) in Settings:

```swift
protocol MarketDataProvider {
    func quote(_ symbol: String) async throws -> Quote
    func vwap(_ symbol: String) async throws -> Double
    func volumeVsAvg(_ symbol: String, period: Int) async throws -> Double
    func subscribe(_ symbols: [String]) -> AsyncStream<Quote>
}

struct PolygonProvider: MarketDataProvider { /* … */ }
struct FinnhubProvider: MarketDataProvider { /* … */ }
struct SchwabProvider: MarketDataProvider { /* keep what you have */ }
struct YahooProvider: MarketDataProvider { /* delayed fallback */ }
```

### Tier 3 — Schwab stays as the power-user opt-in

Don't remove it — there are users (your audience) who already have a Schwab brokerage account and want real-time without paying Polygon. The current `SchwabService` is the right home for them. Just stop treating it as the *default*.

### Tier 4 — emergency fallback: Yahoo Finance unofficial

`https://query1.finance.yahoo.com/v8/finance/chart/VXX` — no key, returns OHLCV. Terms grey area (no published commercial API), fine for personal/educational. Use only when nothing else is configured. Mark it clearly "delayed" in the data-source pill at the bottom of the chart.

### What to ship in v1.0

- TradingView widget for the chart (Tier 1).
- **Finnhub free** as the default quote feed (Tier 2). It's free, real-time, signup-required-but-painless, and 60 req/min is more than enough.
- Polygon and Schwab as alternatives in Settings → Data Source.
- Yahoo as the silent fallback.

### Latency / cost summary

| Provider | Real-time? | Auth | Cost | Notes |
|---|---|---|---|---|
| TradingView widget | 15-min delayed (cash) | None | Free | Chart UI only |
| Finnhub | Yes (US equities) | API key | Free 60/min | Best default for quotes |
| Polygon | Yes | API key | $29/mo Starter | Best when serious |
| Schwab | Yes | OAuth (brokerage) | Free w/ account | Power users |
| Yahoo unofficial | 15-min delayed | None | Free | Fallback |

---

## Part 4 — Functional changes to ship alongside the redesign

### a. Refactor `MainView.swift` around size class properly

Right now Mac and iPhone share `TabView` with different tab sets. Replace the Mac path with a **single layout** (the three-column above). Replace the iPhone path with a **single primary screen** that swaps content based on `TimeManager` state — not a tab bar.

### b. Wire `TimeManager` to drive screen state, not just data

Add a `DeskState` enum:

```swift
enum DeskState {
    case preMarket          // before 9:30
    case betweenWindows     // market open, no active window
    case windowOpen(VXXTradingWindow)
    case openPosition(Trade)
    case closeWarning       // 15:50–15:55
    case hardExit           // 15:55+
    case afterHours
}
```

The desk screen renders differently per state. This is what makes the app feel alive without being noisy.

### c. Rip out the autopilot-sounding surfaces

- `SignalMonitor` is fine internally — rename the user-facing copy. "Signals Live" → just embed the gate verdict. The user does not need a feed of "signals"; they need to know whether *now* is a trade.
- `PromptCoachView` → rename to **"Second Read"** in UI. Keep the prompt library exactly as is.
- Anywhere a string says "Pro" / "Premium" / "Unlock" — strip it. You already removed the paywall; copy needs to catch up.

### d. Notifications

Push notifications already exist (`SignalNotification.swift`). The notification copy is where the tone leaks worst — rewrite every body string:

- ❌ "VXX entry signal detected — institutional flow window"
- ✅ "INSTITUTIONAL 15:45 OPEN · R 1.62 · VOL 340% · GO CHECK THE TAPE"

Notification = the same blunt diagnosis the desk shows. Action button: "Open Desk" (not "View Signal").

### e. Things to delete

- `RoadmapArtboard`, freemium tier copy, `StoreKitService` references anywhere they linger (you said paywall is gone — make sure marketing docs match).
- Any view named `*Card` that exists solely to wrap a single value in rounded corners. Replace with bare rows.
- `LaunchOverlayView` decorative animation — keep it under 400ms; the splash is fine but make it pure black with the amber square mark.

---

## Part 5 — Order of operations (suggested)

Each chunk is sized for one Claude Code session. Build, install on `ZZZ`, evaluate at market hours, then move on.

1. **Token swap.** Replace `DesignSystem.swift` with the new palette + IBM Plex fonts. Build and look at every screen — most will already look 60% better just from the color change.
2. **Kill decoration.** Remove glows, rounded corners (≥4px → 2px), drop `Georgia`, drop all emoji from string files, scrub the purple. Single PR.
3. **Mac single-window layout.** Rebuild `TradingDashboard` regular-size-class as the three-column terminal. Use the mockup as the spec.
4. **iPhone gate-spine layout.** Rebuild `TradingDashboard` compact-size-class around the NEXT MOVE + gate stack.
5. **TradingView chart embed.** Add `ChartWebView`, swap it into both layouts.
6. **`MarketDataProvider` protocol + Finnhub.** Wire as default. Schwab stays available behind a setting.
7. **`DeskState` machine.** Implement state transitions, especially `closeWarning` / `hardExit` taking over the iPhone screen.
8. **Notification copy pass.** Rewrite every string. Add tests for the time-window logic if you're putting in a test target.
9. **App Store metadata sync.** Update screenshots, marketing copy, App Store Connect notes to match the new tone. Drop "Pro" anywhere it survives.

---

## Part 6 — App Review hazards (don't trip these)

The product positioning is sound: educational, manual-only, local-first, no execution. The redesign doesn't change that. But the tonal sharpening can read as "this app gives trading advice" if you're not careful. Guardrails:

- **No win-rate claims in UI.** Internally `VXXTradingWindow.winRate` is fine; surface it only inside the prompt copy where it's clearly *historical context for analysis*, never as a number the user sees on the desk.
- **"NO TRADE" and "CLOSE IT" are okay** because they're the *trader's* own rules surfaced back — discipline language. They're not the app recommending a position direction. Keep the framing: the app is a mirror, not an oracle.
- **Disclaimer in first-run + Settings** stays. The current `DisclaimerView` is fine; just retype-set it to match the new tone (Plex Mono labels, hairline panel, black bg).
- **The marketing subtitle ("Native Volatility Analysis Tool")** is good Review cover. Don't rename to anything that sounds like a broker or signal product.
- **Internal codename "balls of steel" stays internal.** Public surface is "Steel Trading Desk" — but the *tone* inside the app can carry the energy through copy, color, and density.

---

## Part 7 — Files most likely to touch

```
Steel_Trading_Desk/Views/Components/DesignSystem.swift     ← rewrite palette + type
Steel_Trading_Desk/Views/MainView.swift                    ← drop tabs on Mac; state-driven phone
Steel_Trading_Desk/Views/TradingDashboard.swift            ← three-column terminal + gate spine
Steel_Trading_Desk/Views/VXXTradingDashboard.swift         ← fold into TradingDashboard or remove
Steel_Trading_Desk/Views/ManualDataEntryView.swift         ← becomes a sheet, not a tab
Steel_Trading_Desk/Views/PromptCoachView.swift             ← rename "Second Read" in UI
Steel_Trading_Desk/Views/ActiveTradesView.swift            ← merges into desk right-rail
Steel_Trading_Desk/Services/SchwabService.swift            ← demote to one of several providers
Steel_Trading_Desk/Services/SignalMonitor.swift            ← internal name fine; rewrite user strings
Steel_Trading_Desk/Services/SignalNotification.swift       ← rewrite all body strings
+ NEW: Services/MarketDataProvider.swift                   ← protocol
+ NEW: Services/FinnhubProvider.swift                      ← default
+ NEW: Services/PolygonProvider.swift                      ← opt-in
+ NEW: Services/YahooProvider.swift                        ← fallback
+ NEW: Views/Components/ChartWebView.swift                 ← TradingView widget
+ NEW: Models/DeskState.swift                              ← state machine
```

---

## Part 8 — One-line gut-check before merging anything

> *If a pixel doesn't help the trader sit on their hands or take the print, cut it.*

If you can't say which of those two things a piece of UI serves, it doesn't ship.
