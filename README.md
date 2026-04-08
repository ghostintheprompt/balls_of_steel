# Balls of Steel

Native macOS trading desk for discretionary SPY and VXX options trading.

This app is built around a simple truth: the chart setup matters more than a broker logo, and a clean alert at the right moment is worth more than a noisy stream of fake opportunity. Balls of Steel is a local-first desk for traders who already know how they want to trade and want better timing, clearer safeguards, and stronger entry/exit discipline around the open and close.

## What It Is

- A native Mac desk for SPY and VXX setup validation
- Manual-first by design: you feed the chart context from ThinkOrSwim, Schwab, or another platform
- Direction-aware alerts for `WATCH`, `ENTRY`, and `EXIT`
- Active trade monitoring with targets, stops, timing warnings, and close-management rules
- Built for aggressive but small positions with real safeguards

## What It Is Not

- Not a black-box auto-trading bot
- Not dependent on the App Store to make sense as a product
- Not safe to auto-execute option orders from the underlying price alone without spread and slippage checks
- Not trying to be a generic retail trading feed

## Current Product Position

The strongest version of this app is a direct-distributed Mac product, not an App Store-first finance app.

The product direction for 2026 is:

- Direct-distributed macOS app first
- Broker-agnostic architecture
- Underlying-led setup detection
- Human-confirmed options execution
- SPY and VXX only until reliability is brutal and obvious

That keeps the app honest. The underlying is enough to identify timing and setup quality. It is not enough to blindly send option orders without validating spread, liquidity, and slippage.

## Core Workflow

1. Read the chart in ThinkOrSwim or your broker platform.
2. Enter the live setup into the app through `Manual Feed`.
3. Let the desk validate time window, direction, volume, VWAP alignment, news risk, and volatility context.
4. Use the alert system to decide whether a setup is only worth watching, ready for entry, or ready for exit.
5. Execute on your broker platform and let the app handle discipline, monitoring, and review context.

## Current Features

- Dedicated `SPY Desk`
- Dedicated `VXX Desk`
- `Manual Feed` for chart-state entry
- `Live` trade monitoring
- Configurable close warnings and hard-exit timing
- Local notifications and cleaner alert messaging
- Branded, high-contrast interface designed for fast sessions

## Build And Launch

### Run In Xcode

```bash
open /Users/greenplanet/Documents/balls_of_steel/Balls_of_Steel.xcodeproj
```

Choose the `Balls_of_Steel` scheme and run on `My Mac`.

### Open The Built App Bundle

The current release-style app bundle lives here:

`/Users/greenplanet/Documents/balls_of_steel/Builds/Balls_of_Steel.app`

That is the easiest way to launch without opening Xcode every time.

## Documentation

- [Docs Index](/Users/greenplanet/Documents/balls_of_steel/docs/README.md)
- [Getting Started For Playtest](/Users/greenplanet/Documents/balls_of_steel/docs/GETTING_STARTED_PLAYTEST.md)
- [Product Strategy 2026](/Users/greenplanet/Documents/balls_of_steel/docs/PRODUCT_STRATEGY_2026.md)
- [Testing Guide](/Users/greenplanet/Documents/balls_of_steel/docs/TESTING.md)
- [Playtest And Direct Release Checklist](/Users/greenplanet/Documents/balls_of_steel/docs/PRE_LAUNCH_CHECKLIST.md)
- [ThinkOrSwim Setup](/Users/greenplanet/Documents/balls_of_steel/docs/thinkorswim_complete_setup_2026.md)
- [App Store Checklist (Secondary Path)](/Users/greenplanet/Documents/balls_of_steel/docs/APP_STORE_RELEASE_CHECKLIST.md)

## Near-Term Optimization Priorities

- Decouple market data from any one broker
- Add explicit spread and slippage-aware confirmation before any future semi-automated option flow
- Keep improving open and close window quality
- Tighten launch, packaging, and direct-distribution workflow
- Stay narrow enough that the product never turns into clutter
