# Product Strategy 2026

## Product Truth

Balls of Steel should not become another subscription-heavy trading app that promises precision while hiding slippage and brokerage reality behind a pretty feed.

The strongest version of this product is a native Mac trading desk for discretionary SPY and VXX options traders who want:

- sharper setup validation
- cleaner entry and exit alerts
- stronger discipline around the open and close
- less broker dependency
- less noise

## What The Product Owns

The app should own:

- setup validation
- time-window awareness
- alert quality
- risk framing
- close management
- active trade monitoring
- review discipline

The app should not pretend to own:

- perfect fill quality
- option chain microstructure from the underlying alone
- blind auto-execution without spread and slippage checks
- one-broker permanence

## Why Direct Distribution Wins

The App Store is not the natural home for this product.

Direct macOS distribution is the cleaner path because it lets the product stay narrow, sharp, and serious:

- no forced mass-market positioning
- no pressure to pretend it is a consumer finance toy
- easier private testing with serious users
- easier to keep the tone and design aligned with the actual trading audience
- simpler path to a premium tool instead of an app-store-shaped compromise

The App Store can remain an optional future channel, not the identity of the business.

## Data And Execution Architecture

### Layer 1: Setup Detection

The desk can use manual input today and adapters later.

Inputs that matter:

- underlying price
- direction
- volume context
- VWAP position
- time window
- news risk
- VIX and ratio context for VXX

This layer is enough to decide whether a setup is garbage, worth watching, or ready for entry.

### Layer 2: Options Confirmation

This is where most trading apps lie.

A valid SPY or VXX setup on the underlying does not guarantee a valid option fill. Before any future semi-automated execution, the app needs explicit confirmation of:

- bid/ask spread
- liquidity
- slippage tolerance
- contract selection rules
- acceptable fill distance from theoretical value

If those checks are not present, the app should stay human-confirmed.

### Layer 3: Broker Adapters

Brokers should be adapters, not the product.

That means:

- no single-broker lock-in at the strategy layer
- signal generation should survive a broker outage
- manual operation should still be possible when APIs fail
- future integrations should slot into a stable internal model

## Real Constraints

### Underlying-Only Data Is Useful

Underlying price is enough for:

- timing alerts
- setup validation
- window management
- direction framing
- manual execution support

### Underlying-Only Data Is Not Enough

Underlying price alone is not enough for:

- safe unattended options execution
- realistic fill assumptions
- slippage control
- robust performance claims

If the product ever ignores that, it becomes theater.

## Product Positioning

The best positioning is:

`A local, discretionary options desk for SPY and VXX traders who want disciplined alerts, cleaner timing, and broker-neutral workflow.`

Not:

- social trading platform
- generic retail scanner
- meme alert feed
- full auto-trader with fake precision

## Near-Term Optimization Priorities

### 1. Reliability Around Open And Close

The product edge is strongest when timing is compressed and the setup is clear. That means the open and close deserve the most tuning, the most guardrails, and the least clutter.

### 2. Better Signal Promotion Logic

`WATCH` should arrive early enough to create awareness.

`ENTRY` should only fire when the tape earns it.

`EXIT` should be direct, non-ambiguous, and direction-aware.

### 3. Slippage-Aware Future Design

If the product ever moves toward broker-assisted execution, it needs a slippage model first, not after.

### 4. Direct Release Workflow

Keep the app bundle polished, repeatable, and easy to replace. The release path should feel like a serious Mac product, not a dev artifact.

### 5. Narrow Scope

SPY and VXX are enough.

Adding more symbols before the current desks are obvious and brutal would dilute the whole product.

## Business Shape

The natural order of operations is:

1. personal trading desk
2. private tool for a small serious circle
3. higher-ticket customization or workflow tuning

That is stronger than trying to chase scale through a sea of disposable finance apps.

## Decision Rules

When choosing features, keep these rules:

- if it increases alert quality, keep it
- if it improves discipline, keep it
- if it reduces broker dependency, keep it
- if it requires fake certainty about option fills, slow down
- if it smells like generic app-store finance clutter, kill it
