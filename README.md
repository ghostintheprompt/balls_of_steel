# Balls of Steel

Native macOS trading desk for discretionary SPY and VXX options trading.

Balls of Steel is a local-first desk for traders who require precise timing, clear safeguards, and rigorous entry/exit discipline. It is designed to bridge the gap between chart analysis and disciplined execution, focusing on the high-probability windows around the market open and close.

## Core Capabilities

### Setup Validation
- Native macOS interface for SPY and VXX setup monitoring.
- Manual-first data entry: Input chart context directly from your primary brokerage platform (e.g., ThinkOrSwim, Schwab).
- Multi-factor validation: Automated checks for time windows, volume confirmation, VWAP alignment, and volatility context.

### Signal Intelligence
- Direction-aware alerting system (WATCH, ENTRY, EXIT).
- Real-time trade monitoring with dynamic targets and stops.
- Built-in timing safeguards and close-management alerts to prevent emotional overrides.

### Execution Discipline
- Designed for aggressive, small-position trading with strict risk management.
- Local-first architecture ensures data privacy and zero latency from external feeds.
- Explicit focus on setup detection rather than automated black-box execution.

## Operational Workflow

1. Analysis: Perform technical analysis on your primary brokerage platform.
2. Integration: Feed the current chart state into the desk via the Manual Feed.
3. Validation: The desk validates the setup against institutional flow requirements and historical reliability.
4. Action: Utilize the signal system to confirm entry or exit timing.
5. Management: Monitor active trades with automated discipline warnings and hard-exit rules.

## Technical Requirements

### Installation
1. Open Balls_of_Steel.xcodeproj in Xcode.
2. Select the Balls_of_Steel scheme.
3. Target: My Mac.
4. Build and Run.

## Documentation

- [Documentation Index](docs/README.md)
- [ThinkOrSwim Integration Guide](docs/thinkorswim_complete_setup_2026.md)
- [Trading Philosophy and Discipline](docs/vxx_trading_philosophy_discipline.md)
- [System Prompts and Checklists](docs/vxx_trading_prompts_2026.md)

## Principles

- Local-first: All data and logic remain on your hardware.
- Manual-first: Maintains the trader's connection to the tape; no automated orders.
- Integrity: No black-box indicators; every signal is based on transparent, verifiable criteria.
