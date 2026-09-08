# Fail #1 — 2026-09-08, Afternoon Flex block

Real setup, watched live on both ThinkOrSwim and Steel Trading Desk simultaneously. Screenshots: `Screenshot 2026-09-08 at 2.48.43 PM.png` (ThinkOrSwim) and `Screenshot 2026-09-08 at 2.49.25 PM.png` (Steel Desk) — on Desktop as of this writing, not yet moved into this folder (raw `cp` of those PNGs hit a sandbox read restriction this session; move them in manually if the visual record matters).

## What both platforms showed

| | ThinkOrSwim (2:48:43 PM ET) | Steel Desk (2:49:25 PM ET) |
|---|---|---|
| VXX | 17.98 | 18.07 |
| VIX | ~15.47 (derived) | 15.60 |
| VXX/VIX ratio | 1.162 | 1.158 |
| Volume vs. 30-bar avg | 389% (96,453 / 24,784) | 889% |
| VXX change | +1.10% | +1.98% |

Real, agreed-upon move: VXX up ~1-2%, volume far past 200% on both platforms independently.

## Why Steel Desk blocked it

`TimeWindowInput.isVXXEntryWindow` (`Views/ManualDataEntryView.swift`) hard-blocks Afternoon Flex (1:30-3:45 PM) — only Morning (9:50-10:15), Power Hour (3:10-3:25), and Institutional (3:45-4:10) pass. Ratio was also below the 1.45 minimum (1.158). So two gates failed: window and ratio. Volume alone was not enough, correctly, per the doc's own zero-tolerance rule on both.

## The open question this surfaced

That same `isVXXEntryWindow` switch carries a comment dated 2026-05-14: a *previous* version of this code accepted more windows (including `.lunch`), and it was deliberately tightened because that was judged to be strategy drift away from the audited ThinkOrSwim doc. So today's block may be the system working exactly as intended after a past fix — not a new bug. Michael's read in the moment: "doesn't have to be perfect, just close" (matching the *already-built-but-unused* `ArrowSignal.TimeWindow` model, which rates Afternoon Flex at 72% reliability rather than zero). Not yet resolved which model should actually govern the live alert — see [[steel-trading-desk-time-window-gate-dispute]].

## Numbers for later reference

If Afternoon Flex is ever made alertable, this is a real example to backtest the threshold against: ratio 1.158-1.162 (well below 1.45), volume 389-889% depending on methodology, ~2% underlying move. Whatever rule gets adopted should be checked against whether it would have fired here, and whether firing here would have been *correct* given the ratio was this far below the doc's stated minimum.
