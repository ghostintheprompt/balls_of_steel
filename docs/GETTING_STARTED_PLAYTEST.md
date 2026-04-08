# Getting Started For Playtest

This is the fastest way to understand Balls of Steel and test it without guessing.

## What The App Does

Balls of Steel is a native Mac trading desk for discretionary SPY and VXX options trading.

It does not place trades for you.

It helps you:

- feed in the chart setup you are seeing
- validate whether the setup is weak, worth watching, or ready for entry
- monitor active trades with targets, stops, and close-management timing
- stay sharper around the open, the close, and now the flexible afternoon session

## What You Need

- A Mac
- The app bundle or Xcode project
- A charting or broker platform such as ThinkOrSwim or Schwab
- Your own judgment

## Launch The App

### Easiest

Open:

`/Users/greenplanet/Documents/balls_of_steel/Builds/Balls_of_Steel.app`

### Development Path

Open:

`/Users/greenplanet/Documents/balls_of_steel/Balls_of_Steel.xcodeproj`

Then run the `Balls_of_Steel` scheme on `My Mac`.

## First Run

1. Review onboarding.
2. Accept the disclaimer.
3. Open `Settings`.
4. Confirm notifications are enabled.
5. Review the close warning and hard-exit times.

## The Core Flow

1. Watch your chart on ThinkOrSwim or your broker.
2. Open `Manual Feed` in the app.
3. Choose `SPY` or `VXX`.
4. Enter the live setup:
   - price
   - volume percent
   - VWAP position
   - arrow direction
   - trading window
   - news risk
   - VIX level for VXX
5. Save the entry.
6. Read the corresponding desk:
   - `SPY Desk`
   - `VXX Desk`
7. Check whether the app is showing:
   - `WATCH`
   - `ENTRY`
   - `EXIT`
8. If you take the trade on your broker, monitor it in `Live`.

## How The Time Logic Works

The app now treats time as structured, not rigid.

### Anchor Windows

These are still the strongest windows:

- SPY open drive
- SPY close drive
- VXX power hour
- VXX institutional flow

### Afternoon Flex

From roughly `1:30 PM` into the late session, the app can now recognize valid setups before the official close window if the chart actually earns it.

That means:

- `WATCH` can appear earlier
- `ENTRY` still needs stronger confirmation
- volume and VWAP alignment matter more in the flex zone

This keeps the app realistic without making it loose.

## Fast Tester Scenarios

### SPY Open

Use a clean open setup and confirm:

- the app reads the open window correctly
- the bias matches the arrow
- VWAP alignment is clear
- `WATCH` can promote to `ENTRY`

### SPY Afternoon Flex

Use a setup between `1:30 PM` and `3:30 PM` and confirm:

- the desk does not dismiss the whole session as dead
- a clean arrow plus VWAP agreement can trigger a real watch
- weaker volume does not over-promote the setup

### SPY Close

Use a close setup and confirm:

- the close window is still treated as stronger than the flex zone
- close warning appears before hard exit

### VXX Ratio

Use:

- `VXX: 29.50`
- `VIX: 19.48`
- `Volume: 340%`

Confirm:

- ratio is about `1.51`
- the setup reads as tradable
- volume still acts as a gate

## What Testers Should Watch For

- alerts that feel too early
- alerts that feel too late
- duplicate or stale alerts
- any setup that should be `WATCH` but becomes `ENTRY`
- any setup that should be tradable but gets ignored
- anything in the copy that feels confusing under pressure

## Important Limits

- This is manual-first right now.
- The app is not live broker automation.
- Underlying price is useful for setup timing, not enough for blind options execution.
- Slippage and spread still matter in the real trade.

## Best Way To Give Feedback

When reporting a test, include:

- symbol
- approximate time
- market window
- arrow direction
- volume multiple
- whether price was above or below VWAP
- what the app showed
- what you think it should have shown

## Related Docs

- [Project README](/Users/greenplanet/Documents/balls_of_steel/README.md)
- [Testing Guide](/Users/greenplanet/Documents/balls_of_steel/docs/TESTING.md)
- [Product Strategy 2026](/Users/greenplanet/Documents/balls_of_steel/docs/PRODUCT_STRATEGY_2026.md)
- [Playtest And Direct Release Checklist](/Users/greenplanet/Documents/balls_of_steel/docs/PRE_LAUNCH_CHECKLIST.md)
