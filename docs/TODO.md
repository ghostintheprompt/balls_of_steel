# TODO

**Updated:** April 8, 2026
**Current Phase:** optimize the direct-distributed Mac desk, not the App Store story

## Highest Priority

### 1. Private Playtest Loop

- [ ] run repeated SPY open tests
- [ ] run repeated SPY close tests
- [ ] run repeated VXX ratio tests
- [ ] tune alert promotion so `WATCH` feels early and `ENTRY` feels earned
- [ ] note any false positives around heavy-news sessions

### 2. Data Architecture

- [ ] keep strategy logic independent from any one broker
- [ ] design a stable quote/input adapter layer
- [ ] decide what a future market-data integration must provide before it earns a place
- [ ] preserve manual workflow even if future APIs exist

### 3. Execution Reality

- [ ] define future spread checks for option confirmation
- [ ] define slippage tolerance rules before any semi-automated flow
- [ ] keep execution human-confirmed until those rules exist

## Product And UX

- [ ] keep polishing the SPY and VXX desks as one branded system
- [ ] make sure the first-run experience feels as strong as the live desk
- [ ] generate a real bundled app icon, not just the runtime Dock icon
- [ ] review any remaining generic copy and tighten the voice

## Release Workflow

- [ ] make rebuild-and-replace flow painless for `Builds/Balls_of_Steel.app`
- [ ] prepare a signing and notarization pass for direct release
- [ ] keep release notes simple and honest

## Things To Avoid

- [ ] do not add more symbols before SPY and VXX are obviously reliable
- [ ] do not build around Schwab-only assumptions
- [ ] do not imply auto-trading quality without option-spread awareness
- [ ] do not shape the product around App Store expectations unless that path proves itself
