# Playtest And Direct Release Checklist

**Date:** April 8, 2026
**Current Focus:** direct macOS distribution, private playtesting, product truth

## Release Position

Balls of Steel is now a direct-distributed Mac desk first.

That means the immediate goal is not "survive the App Store." The immediate goal is:

- make the app easy to run
- make the app easy to trust
- make the app hard to misunderstand
- make the open and close workflows feel sharp

## Product Truth Checklist

Before sharing this with anyone, make sure the product story is honest:

- [ ] It is presented as a discretionary trading desk, not a black-box auto trader
- [ ] SPY and VXX are described as the only active focus
- [ ] Manual chart input is described clearly
- [ ] Broker dependency is downplayed rather than hidden
- [ ] Slippage and option-spread limits are acknowledged
- [ ] The app does not imply guaranteed fill quality or guaranteed returns

## Private Playtest Checklist

### Core Desk Flow

- [ ] Launch the app from the built bundle
- [ ] Launch the app from Xcode
- [ ] Confirm onboarding and disclaimer still feel clean
- [ ] Confirm runtime Dock icon appears correctly
- [ ] Confirm launch overlay feels deliberate and smooth

### SPY Desk

- [ ] Enter a realistic SPY open setup
- [ ] Enter a realistic SPY close setup
- [ ] Verify `WATCH` can appear before `ENTRY`
- [ ] Verify direction, target, and stop are clear
- [ ] Verify close warning appears before hard exit

### VXX Desk

- [ ] Enter a VXX setup with VIX context
- [ ] Verify ratio, volume, and direction all read clearly
- [ ] Verify weak setups do not promote too easily
- [ ] Verify VXX close-management timing reflects the updated extended-hours logic

### Live Trade Monitoring

- [ ] Open a trade manually
- [ ] Confirm live P/L reads correctly for direction
- [ ] Confirm target/stop progress displays correctly
- [ ] Confirm exit notifications are cleaner than the old stub behavior
- [ ] Confirm duplicate scanner subscriptions are not occurring

### Settings And Alerts

- [ ] Notification status is visible and accurate
- [ ] Close warning and hard-exit times can be edited
- [ ] Alert wording is readable under pressure
- [ ] No obvious stale or duplicate alerts remain on screen

## Product Quality Checklist

- [ ] The UI feels authored, not generic
- [ ] SPY and VXX look like one branded system
- [ ] Manual Feed still feels true to your actual workflow
- [ ] Nothing in the copy sounds fake, overpromised, or retail-app dumbed down
- [ ] The app can be shown off without apologizing for the design

## Distribution Checklist

- [ ] `Builds/Balls_of_Steel.app` launches cleanly
- [ ] The bundle is in a stable location
- [ ] The app can be replaced cleanly after a rebuild
- [ ] The direct-distribution path is documented in the README
- [ ] A future signing/notarization pass is tracked but not blocking playtest

## Risks That Still Matter

- [ ] No future execution feature should ship without spread/slippage awareness
- [ ] No product copy should imply live broker integration where it does not exist
- [ ] No future data dependency should hard-wire the strategy to one broker
- [ ] No new symbol should be added before SPY and VXX are obviously reliable

## Showcase Angle

When you show the app, the strongest angle is:

`This is a native Mac trading desk for timing and discipline, not another finance app pretending to solve execution with a noisy feed.`

That is the lane.
