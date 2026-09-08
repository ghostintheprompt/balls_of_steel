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
- **Matching threshold NUMBERS is not the same as matching the STRATEGY.**
  Found 2026-09-08: `StrategySpec`'s ratio/volume-threshold/time-window
  numbers matched `docs/trading docs/thinkorswim_complete_setup_2026.md`
  exactly, but the actual live CALCULATIONS didn't — the volume gate
  compared today's cumulative volume to a 20-day daily average instead of
  the doc's real formula (current 5-min bar / 30-bar average), and pattern
  confirmation, key-level confirmation, and the arrow signal were never
  computed in live mode at all: they silently carried forward whatever was
  last typed into the Manual Tape sheet, forever, defaulting to none/false
  when nothing had ever been typed. A fully-built `ArrowSignalDetector` sat
  dead in the codebase, called from nowhere. This is worth a standing
  check: when touching any gate, ask "does this actually run against live
  data every poll, or does it silently no-op and inherit a stale/default
  value?" — a gate that only ever reads `previous?.field ?? default` is
  not live, no matter how correct its threshold number is.
- **If the UI can't independently verify a number, it isn't proof.**
  Found same day: the VWAP gate only ever stored/showed a category
  (ABOVE/BELOW/AT), never the actual dollar VWAP value, so there was no way
  to check it against ThinkOrSwim's own VWAP line — "trust me" instead of
  "here's the number, check it yourself." Same root habit as the
  `Locked until X passes` checklist text, which hid gate values the app
  had already computed (proven by the RAW READ panel showing them) behind
  vague copy instead of just showing them with a "moot for now" qualifier.
  Michael's framing: traders want cockpit instruments, not a verdict — show
  the real number and let it speak, don't just assert a conclusion.
- **Verify live-data fixes with real multi-minute evidence before saying
  "fixed."** Three separate "should be fixed now, go check" claims turned
  out false in a row on 2026-09-08 before the actual root cause (Schwab's
  `pricehistory` endpoint returning the last *complete* trading day instead
  of today's, resolving to the previous Friday right after the Labor Day
  holiday) was found via raw diagnostic logging, not guessing. Sample the
  actual persisted value 3+ times across a window long enough to guarantee
  it should have changed before calling anything fixed.
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

## Checkpoint: 2026-09-07

Everything below marked `[x]` is real, built, and either verified live by
Michael or (for the two items explicitly flagged) still pending its first
live test. Tagged in git as `checkpoint-2026-09-07-pre-first-trade` — the
known-good point to return to if anything goes sideways once real trading
starts. The next real milestone isn't a code change: it's Michael's first
actual live trade, which is also the first live test of the contract
suggestion and the alerting system under real conditions.

## Punch list

- [x] **Second Read / Prompt Desk redesign** — raised 3x by Michael. Fixed
  in two passes: (1) visual rebuild to match SystemsPanel's flat
  hairline-bordered look instead of the old generic-iOS styling, plus a
  NavigationView bug that made the sheet render as a tiny cramped box on
  macOS; (2) the real gap underneath the styling — a "CURRENT TAPE" panel
  now always shows a real, copyable prompt built from live data, not gated
  to the ~4 narrow scheduled windows/day like everything else in the
  schedule list.
- [x] Chart interactivity confirmed working live by Michael: real timeframe
  switching (1m/5m/15m/1H), VWAP/SMA20/SMA50/VOL toggles, 1D correctly shown
  disabled (no daily-candle data source exists — would need
  `fetchDailyCandles` wired into a shared snapshot to ever be real). Two
  real bugs found and fixed along the way: (1) unselected timeframe buttons
  sat on `Color.clear` backgrounds, which silently don't register taps in
  SwiftUI without `.contentShape` — every button now has one explicitly;
  (2) the chart's x-axis was the one timestamp display in the whole app
  that didn't force `America/New_York`, rendering in the device's local
  timezone instead of market time — fixed via `Date.FormatStyle(timeZone:)`.
- [x] Found and fixed a real P&L display bug (not part of the chart work,
  found while auditing the right rail field-by-field): `Trade.unrealizedPnL`
  already applies the 100-share/contract multiplier, but 4 separate display
  spots (NEXT MOVE's OPEN badge + per-trade rows, on both Mac and phone
  layouts) divided it by 100 again — a $50 real move was reading as $0.50.
  Fixed all four to match what Trade Journal shows for the same trade.
- [x] Volume panel's 200% threshold line had no direct label (only small
  header text) — added a "200%" annotation right on the dashed line.
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
- [x] Real options-chain fetch + contract suggestion wired into NEXT MOVE.
  The instant all five gates clear, the desk fetches a real Schwab chain and
  shows the actual contract (strike/expiration/delta/ask/count/cost) using
  `OptionSelector.suggest(side: .put, ...)` (fade-only, always puts) sized
  off `StrategySpec`'s own audited tier table. **Still unverified against
  live Schwab traffic as of writing** — first real "CLEARED" moment during
  market hours is the actual test. If the chain JSON doesn't match the
  assumed shape, it'll show the raw Schwab response as the error text
  (same pattern as every other Schwab error here) rather than a wrong
  contract — watch for that the first time this actually fires live.
- [ ] Confirm whether Schwab actually rotates the refresh token with a fresh
  7-day window on each silent refresh, or hard-expires 7 days after original
  auth regardless. Unconfirmed — only observable by watching real usage over
  the next week or so.
- [x] Schwab OAuth actually connects and live quotes parse correctly
  (2026-09-07) — see `docs/SCHWAB_API_READINESS.md` for the full writeup.
- [x] **2026-09-08 first live-market session — real bugs found and fixed
  while watching real trading hours, not in the abstract:**
  - Volume gate was frozen (Schwab `pricehistory` with `periodType=day,
    period=1` returns the last *complete* day, not today — resolved to the
    prior Friday right after Labor Day) and used the wrong formula (20-day
    daily average instead of the doc's 5-min-bar/30-bar-average). Both
    fixed: `fetchRecentCandles` now pins explicit `startDate`/`endDate` to
    today's real ET date plus a defensive same-day filter; volume is
    computed from the same live candles as the chart, matching the doc's
    formula exactly.
  - Pattern confirmation, key-level confirmation, and the arrow signal were
    never computed live — `LiveTapeService` silently carried forward
    whatever was last typed into Manual Tape, forever. A complete,
    well-built `ArrowSignalDetector` sat wired to nothing. All three now
    compute for real off live candles every poll.
  - VWAP only ever showed ABOVE/BELOW/AT with no underlying number to check
    against ThinkOrSwim — `MarketDataEntry.vwapValue` now carries the real
    dollar figure everywhere VWAP is shown.
  - "Locked until X passes" checklist copy hid gate values the app had
    already computed — now always shows the real number with a "moot for
    now" qualifier when an earlier gate hasn't cleared, keeping the
    priority-order discipline the doc itself recommends without hiding data.
  - Renamed the bare "R"/"RATIO" label to "VXX/VIX" everywhere (ticker
    strip, Order of Attack, RAW READ) — was ambiguous.
  - Added a real connectivity indicator + BID/ASK to the main ticker strip
    (previously buried in a tiny footer or Settings) and disabled
    `URLCache` on every Schwab market-data request (was serving stale
    cached history responses).
  - Found, not yet fixed: a real `SIGSEGV` crash in
    `MarketDataService.handleQuoteUpdate` (called from the older
    `SchwabService.subscribeToQuotes`/`subscribeToMarketData` path used by
    `SignalScanner`/`ExitSignalService`) — looks like a thread-safety bug
    from a Dictionary mutated concurrently by two independent Schwab-polling
    loops (that legacy one plus `LiveTapeService`'s own). Crashed once
    during the session at 3:02 PM; relaunched immediately, not
    investigated further under time pressure. Needs real attention before
    trusting the app to stay up unattended for a full session.
  - [x] Resolved (Michael's explicit call, later the same day):
    `TimeWindowInput.isVXXEntryWindow` no longer hard-blocks everything
    except the three anchor windows. "The time frames aren't mandatory but
    optimal... this can run as long as the market is open... but certain
    time frames are weighted differently" — now every window except
    pre-market/after-hours is alertable, and every off-anchor window
    (open/lunch/afternoonFlex/close) requires the same 300% volume bar
    Institutional already does, instead of a fabricated confidence score.
    Updated together: `TimeWindowInput` in `ManualDataEntryView.swift`,
    Angela's `windowChecks()`, and both source docs
    (`thinkorswim_complete_setup_2026.md`, `vxx_trading_prompts_2026.md`)
    with an explicit dated revision note rather than a silent rewrite.
    Real case that prompted it: `docs/trading docs/fails/
    fail-01-2026-09-08-afternoon-flex-block.md`.
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
