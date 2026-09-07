# macOS Widget — Scope

Not started. This is a planning doc from a 2026-09-07 discussion, written
before any widget code exists.

## What it's for

A small always-visible surface next to Weather/Calendar in macOS's widget
stack (desktop widgets, macOS 14+ Sonoma) or Notification Center — VXX/VIX/
ratio and the current gate status (Volume/Window/Ratio/VWAP/Pattern) at a
glance, without opening the app.

**Out of scope for the widget itself:** alerts. Notifications stay owned by
the main app (`SignalNotification` + the live poll loop). A widget process
cannot run a persistent 30-second poll loop or reliably fire time-sensitive
alerts — trying to make it do that would be fighting the platform instead of
using it.

## Why this isn't a drop-in — the real gap

Everything Steel reads/writes today (`AppConfig.Schwab.*` in Keychain,
`lastMarketDataEntry` in `UserDefaults.standard`, `liveTape.enabled`, etc.)
lives in the main app's private container. A widget extension is a
**separate process** and cannot see any of that as-is. Two things have to
change before a widget can show anything real:

1. **Add an App Group** (`group.app.mdrn.steel` or similar) — a new
   entitlement on both the main app target and the new widget extension
   target, added in `project.yml` (this project uses XcodeGen, so the
   entitlement and the new target both go there, not hand-edited in Xcode).
2. **Move the fields the widget needs into that App Group's shared
   `UserDefaults` suite.** Not everything — just a small, deliberate summary
   struct (see below), written by `LiveTapeService` alongside its existing
   `UserDefaults.standard` write. OAuth tokens and credentials stay exactly
   where they are (Keychain, main app only) — a widget has no reason to ever
   see those.

## Refresh model — set expectations correctly

WidgetKit does not let an app dictate a live refresh cadence. The OS owns a
per-widget "refresh budget" (battery/resource-conscious, typically on the
order of minutes, not seconds) and decides when a timeline actually reloads,
regardless of what the code requests.

The realistic, honest version: `LiveTapeService.fetchAndPersist()` calls
`WidgetCenter.shared.reloadTimelines(ofKind:)` after every successful live
tick (already polling every 30s while the app is open and Live is on). This
*nudges* WidgetKit to refresh promptly while Steel is running — in practice
this reads as "close to live" during market hours — but the OS can still
throttle it, and when Steel isn't running at all, the widget shows whatever
the last snapshot was, stale-labeled, not a live feed. That staleness must be
visible in the widget's own UI (a timestamp, not just a number), or it
misrepresents itself exactly the way this doc's own "Why this doc exists"
section says a live alert must never be allowed to.

## Shape of the shared data

A small, purpose-built `WidgetSnapshot: Codable` (not the full
`MarketDataEntry` — the widget doesn't need candles, patterns, or anything
not rendered):

```swift
struct WidgetSnapshot: Codable {
    let vxxPrice: Double
    let vixPrice: Double
    let ratio: Double
    let volumePercent: Double
    let gateStatus: String   // "NO TRADE", "LIVE", etc. — the same label the dashboard shows
    let gateReason: String   // "Volume 78%. Need >200%..." — same text as NEXT MOVE
    let asOf: Date           // required — this is what makes staleness honest in the UI
}
```

Written to the App Group suite by `LiveTapeService` right next to its
existing `persist(_:)` call. Read by the widget's `TimelineProvider`.

## Sizes / layout (draft, not decided)

- **Small**: VXX price, ratio, one-word gate status (LIVE / NO TRADE),
  "as of" timestamp.
- **Medium** (maybe, not committed): adds VIX and the volume/window/ratio
  breakdown row, matching the dashboard's ORDER OF ATTACK list at a glance.

No interactivity planned (no buttons inside the widget) — tapping it should
just open the app, standard widget behavior.

## Sequenced plan

1. Add the Widget Extension target via `project.yml`, run `xcodegen
   generate`. Confirm it builds empty (just a placeholder widget) before
   touching data sharing — isolates "does the target exist correctly" from
   "does data flow correctly."
2. Add the App Group entitlement to both targets.
3. Add `WidgetSnapshot`, write it from `LiveTapeService.fetchAndPersist()`
   (both the success and failure paths — the widget should be able to show
   "feed down" too, not just silently keep the last good number forever).
4. Build the small-size `TimelineProvider` + view against real shared data.
5. Wire `WidgetCenter.reloadTimelines()` into the live-tick success path.
6. Verify what it actually looks like with the app quit — this is the
   asymmetric case (stale data, no updates) that's easy to forget to design
   for and easy to get visually wrong (must not look like a live number).

## Open questions — need Michael's call before starting

1. **Symbol scope**: VXX only, or VXX+VIX both visible in the small size?
2. **Does tapping the widget need to deep-link anywhere specific** (straight
   to the dashboard, fine) **or is default "just open the app" enough?**
3. **Should the widget render *anything* before OAuth is connected**, or
   should it show a clean "not connected" state? (Given the manual-tape
   fallback exists, there's a real question of whether an un-connected
   widget should show manually-entered tape data too, or only ever show live
   Schwab data.)
