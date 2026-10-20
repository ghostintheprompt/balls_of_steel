# Recording a demo

A screen recording of Steel Trading Desk live — the setup check gating in
real time, an alert actually clearing, the chart and trade journal doing
their jobs — is worth more for promotion than any screenshot. Screenshots
show a static UI; a recording shows the fail-closed behavior that's the
actual point of the app. Use this for LinkedIn, the README, or anywhere else
the public release gets promoted.

## Privacy first, every time

This repo already had one real incident: an early screenshot in
`docs/trading docs/` showed a live ThinkOrSwim account balance and had to be
scrubbed from git history with `git-filter-repo`. Don't repeat it in a
recording, where it's easier to miss because it's one frame among thousands
instead of a single static image.

Before recording, and again before publishing:

- **Account balance / buying power / P&L figures** — anywhere Schwab or
  ThinkOrSwim renders them (the native chart's account overlay, any broker
  window you tab to for "manual execution," a second-monitor ThinkOrSwim
  session visible in a multi-window capture). Cover them, blur them in the
  edit, or don't put them on screen during the take.
- **Symbols/position sizes mid-trade** aren't sensitive by themselves — the
  README already says this is fine to share — but a live, identifiable
  position size *combined with* account size is the same balance leak in a
  different shape. Don't show both in the same frame.
- **Schwab Developer Portal tabs, API keys, `.env` contents, Keychain
  prompts** — never on screen. `run_local.sh`'s terminal output only prints
  `set`/not `set` for the credential env vars, never the values, so the
  terminal pane is safe to include if you want to show the launch.
- Do one full pass of the raw file before cutting anything, specifically
  looking for anything in the list above in a frame you didn't mean to keep
  on screen.

## What to actually capture

The five-condition setup check only means something if the recording shows
it changing state, not sitting on one static read. A good take has:

1. **Launch** — `./scripts/run_local.sh` in a visible terminal (safe, see
   above), then the app opening to the cleared/idle desk state.
2. **A real setup forming** — the five conditions ticking from incomplete to
   complete, or deliberately staying incomplete (stale data, wrong window,
   missing condition) so the fail-closed behavior is visible, not just
   claimed. Showing a false alarm correctly *not* firing is as convincing as
   a real alert firing.
3. **An alert clearing** — the one moment the whole app exists for: NO
   TRADE / WAIT flipping to CLEARED.
4. **The native chart**, Schwab-gated, showing a live candle feed — this is
   the thing that doesn't work at all without your own Schwab dev
   credentials, worth 10-15 seconds to prove it's real.
5. **Trade Journal entry** — opening the journal to show an automatically
   logged trade (entry price, VWAP, ratio, VIX, window, screenshot). This is
   the feature the README flags as "wired and real, not yet fully proven
   live" — showing a real entry is the actual proof, better than the words.

Don't force all five into one unbroken take. Record longer than you need,
cut to the clean moments in the edit.

## How to record

### macOS (the real target — this is a native Mac app)

`screencapture` is the system to use (uses modern ScreenCaptureKit's and
honors Screen Recording permission for the terminal you run it from — grant
that once under System Settings -> Privacy & Security -> Screen Recording
if macOS prompts):

```bash
# Interactive: click the window to record, stop with the stop button
# in the menu bar, or Cmd+Ctrl+Esc.
screencapture -v -w steel_demo_raw.mov

# Or capture a fixed region instead of a window:
screencapture -v -R x,y,width,height steel_demo_raw.mov
```

QuickTime Player's File -> New Screen Recording works the same way and is
easier if you want a visible countdown and a mouse-click highlight option
(Options menu in the recording control bar) — use that if `screencapture`
feels too bare for a take you're going to publish raw.

Either way, launch the app from the terminal with `./scripts/run_local.sh`
*before* you start the recording, so your capture window opens onto a clean,
already-credentialed desk instead of catching the build/launch spin-up.

### iOS / iPadOS (device or simulator)

On a real paired device, QuickTime can record it directly: connect over USB,
open QuickTime Player, File -> New Movie Recording, then pick the iPhone as
the camera source in the dropdown next to the record button. This captures
the device's screen with real Schwab streaming data, the most honest version
of a mobile demo.

On the simulator, `simctl` records directly to a file — useful if you want
a scripted, repeatable capture instead of narrating live:

```bash
xcrun simctl io <device-id> recordVideo steel_demo_sim.mov
# Ctrl+C in the terminal to stop the recording
```

`xcrun simctl list devices available` gets you the device id; the same
booted-simulator setup `scripts/capture_app_store_screenshots.sh` already
uses (UDID `AD634430-4C6A-417F-B66D-004DA65217D6` by default) works here too.
The simulator won't have real Schwab data unless you've seeded dev
credentials into it the same way `run_local.sh` seeds the Mac build, so a
device recording is the stronger choice when live data matters more than
repeatability.

## Editing and export

QuickTime Player's Edit menu (Trim, or Split Clip plus Delete) is enough for
a straight cut-down — no need to reach for anything heavier unless you want
callout text pointing at the five-condition gate or the CLEARED transition.
Export via File -> Export As, 1080p is plenty for LinkedIn and the README;
don't export at the Mac's full native resolution, it's larger than any
platform needs and makes small on-screen text (the five-condition labels in
particular) read worse after their player recompresses it.

For LinkedIn specifically: native video upload (not a YouTube link) gets
real autoplay in-feed, which is the whole reason this is worth doing over a
screenshot carousel. Keep the final cut under two minutes — the moment that
sells the app (NO TRADE -> CLEARED) should land in the first 15 seconds, not
the last.

## Where it goes after

Drop the final file in `app_store_assets/` alongside the screenshots if it's
going in front of App Review eventually, and link or embed it from the
README's top section once it exists — a 20-second clip of the gate actually
gating does more for this repo than the whole feature table under it.
