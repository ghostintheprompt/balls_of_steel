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

1. Open `Balls_of_Steel.xcodeproj` in Xcode.
2. Choose the `Balls_of_Steel` scheme.
3. Run on `My Mac`.

## Documentation

- [Docs Index](docs/README.md)
- [ThinkOrSwim Setup](docs/thinkorswim_complete_setup_2026.md)
- [VXX Trading Philosophy](docs/vxx_trading_philosophy_discipline.md)
- [VXX Trading Prompts](docs/vxx_trading_prompts_2026.md)

## Near-Term Optimization Priorities

- Decouple market data from any one broker
- Add explicit spread and slippage-aware confirmation before any future semi-automated option flow
- Keep improving open and close window quality
- Tighten launch, packaging, and direct-distribution workflow
- Stay narrow enough that the product never turns into clutter
