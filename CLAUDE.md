# Steel Trading Desk

Native SwiftUI (macOS + iOS) personal trading-alert desk. Watches VXX/VIX
live via Schwab market data and tells Michael when his own five-condition
VXX fade setup is actually live — volume, time window, ratio, VWAP/level,
pattern. It never places orders, reads balances, or manages positions.
Manual execution stays on Thinkorswim/Schwab; this app's only job is
"should I even be looking right now."

## The main goal

Already heavily documented — read these before assuming something isn't
written down:
- `docs/SCHWAB_API_READINESS.md` — the full Schwab integration story,
  including the 2026-09-07 root-cause writeup (routing, masked errors, wrong
  VIX symbol) for the first real live connection since the ~2025 prototype.
- `docs/HANDOFF.md`, `docs/SETUP.md`, `docs/BUILD.md` — project setup.
- `docs/WIDGET_SCOPE.md` — macOS widget, scoped, not started.
- The trading strategy itself lives in `StrategySpec.swift` /
  `StrategyAuditor.swift` — the audited canonical thresholds. Settings →
  AUDIT → Run checks code against them for real, deterministically. Last run
  by Michael: all pass.

## Rules for working in this repo

- **Don't ask permission repeatedly. Execute.** Michael is the director; make
  the call, build it, and let him redirect if it's wrong. Re-asking "do you
  want A or B" after he's already told you to build something is a tangent,
  not caution.
- **This project is a plain, manually-maintained `.xcodeproj`, not
  XcodeGen.** There is no `project.yml` here (that pattern is from a
  different, unrelated project). Any new Swift file must be explicitly
  registered in `Steel_Trading_Desk.xcodeproj/project.pbxproj` or the build
  will fail with "cannot find X in scope" even though the file exists on
  disk. Use the `xcodeproj` Ruby gem (`gem install xcodeproj --user-install`
  if not already present) to add file references + target membership safely
  — do not hand-edit `project.pbxproj` text directly.
- **Verify the build after every real code change**, via
  `./scripts/run_local.sh` (builds, kills any running instance, relaunches
  with `.env` credentials actually inherited — `open`-ing the `.app` does not
  forward shell env vars, a real macOS quirk, not a bug to "fix").
- **Show the real error, never a paraphrase.** This was the root cause of a
  year of stuck OAuth debugging — `SchwabService` was pattern-matching
  Schwab's actual response into a canned guess and discarding the real text.
  Any new error-surfacing code in this app follows the same rule going
  forward: always include Schwab's (or whatever service's) literal response
  text, not a category label.
- **Verify Schwab claims against live traffic, not memory.** Symbol
  conventions, field names, and endpoint shapes drift or were guessed wrong
  originally (`$VIX.X` was never valid; `$VIX` is). When something looks
  like a Schwab data-shape problem, get the raw response body into an error
  message and read it, don't guess again.
- **One punch list.** Not a hierarchy of them scattered across docs — see
  below. Add to it, check items off it, don't spin up parallel tracking.
- **Design preferences (Michael's calls, keep applying these):**
  - Whole containers are the tap target, not a boxed pill/button floating
    inside one. "SECOND READ" / "TRADE JOURNAL" style sections: the entire
    row opens the thing on click; a trailing chevron is the only affordance
    needed. Don't write "OPEN" as a bordered label — it reads as decoration,
    not a control.
  - Watch the `Color.clear` hit-testing trap: a `Button` label with a
    transparent background does not reliably register taps in SwiftUI
    without an explicit `.contentShape(Rectangle())`. Add it to every custom
    button whose unselected/inactive state has no real background fill —
    this bit the chart timeframe buttons on first pass.
  - Settings (dense, text-heavy) gets bumped type size
    (`settingsLabelFont`/`settingsValueFont` in `DesignSystem.swift`) for
    readability. The main TradingDashboard's density is deliberate and
    already praised as good — don't casually bump its base `labelFont`
    globally; scope any dashboard-specific size bump narrowly (e.g. the
    chart toolbar got bumped to `captionFont` on its own, not the whole
    dashboard).

## Punch list

- [x] **Second Read / Prompt Desk redesign** — raised 3x by Michael. Fixed
  in two passes: (1) visual rebuild to match SystemsPanel's flat
  hairline-bordered look instead of the old generic-iOS styling, plus a
  NavigationView bug that made the sheet render as a tiny cramped box on
  macOS; (2) the real gap underneath the styling — a "CURRENT TAPE" panel
  now always shows a real, copyable prompt built from live data, not gated
  to the ~4 narrow scheduled windows/day like everything else in the
  schedule list.
- [ ] Verify chart interactivity actually works on screen: real timeframe
  switching (1m/5m/15m/1H), VWAP/SMA20/SMA50/VOL toggles, 1D correctly shown
  disabled (no daily-candle data source exists — would need
  `fetchDailyCandles` wired into a shared snapshot to ever be real). First
  pass had unselected timeframe buttons on `Color.clear` backgrounds, which
  silently don't register taps in SwiftUI without `.contentShape` — fixed,
  but re-verify live since this is money-affecting if it's wrong.
- [ ] Verify Trade Journal end-to-end with a real trade: entering a trade
  should now record a `JournalEntry` (`TradeJournal.record`, previously dead
  code — nothing ever called it) and capture a real screenshot of the desk
  (`TradeEvidenceCapture`, paired by `idempotencyKey`). Closing a trade
  should mark win/loss + P&L (`TradeJournal.close(idempotencyKey:)`, also
  previously dead). Settings → rail → TRADE JOURNAL → OPEN to review.
- [ ] Add a general-purpose screenshot command (top menu bar item, not tied
  to trade entry) — Michael asked for this separately from the trade-journal
  auto-capture; not yet built.
- [ ] macOS widget next to Weather — scoped in `docs/WIDGET_SCOPE.md`, needs
  an App Group + new Widget Extension target, not started.
- [ ] **Wire the real options-chain fetch into the live UI.**
  `SchwabService.fetchOptionsChain(_:)` is real and built (hits
  `/marketdata/v1/chains`), but nothing calls it yet. Next: call it +
  `OptionSelector.suggest(side: .put, chain:, budget:)` when
  `VXXStrategyState.ready` flips true (this is a fade-only setup, always
  puts), using `StrategySpec`'s audited tier sizing table
  (`RatioTier.maxPositionDollars` — $250/$400/$500/$500) as the budget, and
  show the resulting contract right in NEXT MOVE. **Unverified against live
  Schwab traffic** — the chain JSON parsing follows the documented TD
  Ameritrade-heritage shape Schwab inherited, but exactly like `$VIX.X`,
  don't trust it until a real live call confirms the field names. It fails
  loudly with the raw response attached if wrong, on purpose.
- [ ] Confirm whether Schwab actually rotates the refresh token with a fresh
  7-day window on each silent refresh, or hard-expires 7 days after original
  auth regardless. Unconfirmed — only observable by watching real usage over
  the next week or so.
- [x] Schwab OAuth actually connects and live quotes parse correctly
  (2026-09-07) — see `docs/SCHWAB_API_READINESS.md` for the full writeup.
- [x] Hardened live-feed alerting: debounced disconnect/reconnect
  notifications (2 consecutive failed polls before alerting, not 1) +
  `ProcessInfo.beginActivity` to stop the Mac sleeping while Live Tape is on.
- [x] Dead code removed: `AppConfig.apiKey` (written 3x, read 0x),
  `AppConfig.baseURL`/`.streamURL`/`.clientId` legacy aliases,
  `.env.example`'s unused Finnhub/Polygon lines.
- [x] Settings screen decluttered: removed a fully redundant DATA card
  (duplicated the header pill + SCHWAB card's own status), collapsed the
  Schwab manual-fallback controls behind a closed-by-default disclosure,
  bumped Settings-only type size for readability.
- [x] Prompt Desk had no close button on macOS (`.sheet` doesn't auto-add
  one) — fixed. Strategy Audit's "RUNNING" state flashed for one frame and
  looked fake since the check is instant — added a real minimum-visible
  duration.
