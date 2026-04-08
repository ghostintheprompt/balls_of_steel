# Testing And Development Guide

## Launch Paths

### Fastest: Open The Built App

Double-click:

`/Users/greenplanet/Documents/balls_of_steel/Builds/Balls_of_Steel.app`

Use this when you want a clean playtest without opening Xcode.

### Best For Development: Run In Xcode

Open:

`/Users/greenplanet/Documents/balls_of_steel/Balls_of_Steel.xcodeproj`

Then run the `Balls_of_Steel` scheme on `My Mac`.

This is still the best path for active edits, debugging, and console visibility.

### CLI Build

```bash
xcodebuild \
  -project /Users/greenplanet/Documents/balls_of_steel/Balls_of_Steel.xcodeproj \
  -scheme Balls_of_Steel \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## What To Test First

The product is now a manual-first SPY and VXX desk. The first smoke test should prove that the desk helps you make better decisions without pretending to execute the whole trade for you.

### Session Smoke Test

1. Launch the app.
2. Confirm onboarding and disclaimer flow still feel clean.
3. Go to `Settings` and confirm notifications are enabled.
4. Go to `Manual Feed`.
5. Enter a SPY setup from your chart.
6. Save it and verify the `SPY Desk` updates.
7. Enter a VXX setup with VIX context.
8. Save it and verify the `VXX Desk` updates.
9. Check `Live` and verify active trade monitoring, timing warnings, and direction-aware P/L display.

## Manual Feed Test Cases

### SPY Open Test

Use a realistic open-window setup and verify:

- time window is recognized correctly
- `WATCH` can appear before `ENTRY`
- direction is clearly labeled
- price, VWAP, and volume context read cleanly
- no duplicate or stale alerts stack up

### SPY Close Test

Use a close-window setup and verify:

- late-session timing is reflected correctly
- close warning appears before any hard exit
- the app does not assume every trade must die at `3:55 PM`
- the desk still reads cleanly in a fast session

### VXX Ratio Test

Enter:

- `VXX: 29.50`
- `VIX: 19.48`
- `Volume: 340%`

Verify:

- ratio appears as about `1.51`
- the desk classifies the setup correctly
- volume and ratio context both matter
- the signal does not promote if the rest of the setup is weak

## Active Trade Test

Open a manual trade and verify:

- direction-aware target and stop
- live P/L color and progress meter
- warning time versus hard-exit time
- exit notifications are cleaner than the old stub behavior

## Design Test

The visual bar is no longer "functional enough." Test the actual feel.

Check:

- launch overlay feels intentional
- Dock icon is branded at runtime
- SPY and VXX look like sibling desks
- signal cards read instantly
- cards lift and pulse without feeling noisy
- dark mode styling feels deliberate rather than default

## Known Product Limits

- Manual chart entry is still the primary data path
- Schwab is not the product foundation
- Underlying-led signals are useful for timing, not enough for blind option execution
- Slippage and spread checks must exist before any future semi-automation

## Debugging Tips

### Stream Logs

```bash
log stream --predicate 'process == "Balls_of_Steel"' --level debug
```

### Review Crashes

```bash
log show --predicate 'process == "Balls_of_Steel" AND eventMessage CONTAINS "crash"' --last 1h
```

### Reset App Data

```bash
defaults delete com.yourcompany.Balls-of-Steel
```
