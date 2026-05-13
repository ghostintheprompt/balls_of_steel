# Steel Trading Desk Handoff

Last updated: May 13, 2026

## Current State

The repo is a native SwiftUI Xcode project with one app target: `Steel_Trading_Desk`. The target supports `macosx`, `iphoneos`, and `iphonesimulator`. There is no watchOS target yet.

Verified builds:

```sh
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Debug -destination generic/platform=iOS -derivedDataPath /private/tmp/balls_of_steel_ios_build CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Debug -destination platform=macOS -derivedDataPath /private/tmp/balls_of_steel_mac_build CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Release -destination generic/platform=iOS -derivedDataPath /private/tmp/balls_of_steel_ios_release_function CODE_SIGNING_ALLOWED=NO build
```

All commands pass as of this handoff. A signed `Release-iphoneos` build was also built and installed on the paired iPhone named `ZZZ` using the local MDRN wildcard development profile:

```sh
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Release -destination 'platform=iOS,id=00008120-000E64960CE9A01E' -derivedDataPath /private/tmp/balls_of_steel_device_release_function_retry DEVELOPMENT_TEAM=9TB25L4266 CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY='Apple Development' build
xcrun devicectl device install app --device DC63616F-433E-5833-9255-BE85AAFC9A7A /private/tmp/balls_of_steel_device_release_function_retry/Build/Products/Release-iphoneos/Steel_Trading_Desk.app
xcrun devicectl device process launch --device DC63616F-433E-5833-9255-BE85AAFC9A7A app.mdrn.steel
```

## What Changed In This Pass

- Reframed the iPhone app around function-first desk workflow. The compact phone tab bar is now only `Desk`, `Tape`, and `Risk`; VXX rules and prompts are actions inside the Desk rail instead of top-level pages.
- Changed the installed display name to `Steel Desk` so the home screen is not the underscored target name.
- Replaced the fake release banner value `v1.0.0 Release` with `Field Test`.
- Added a compact phone Desk surface with a direct strategy rail: tape, VXX rules, prompt, risk.
- Moved Settings out of the primary phone tab bar and into a gear on the Desk.
- Stripped decorative hover/pulse behavior and reduced the visual system toward a flatter obsidian/steel utility.
- Rewrote key copy away from generic AI/product language:
  - Manual feed now explicitly says ThinkOrSwim/Schwab are the execution platforms.
  - Prompt Coach is now framed as a window prompt desk, not an AI authority surface.
- Removed premium gating posture for the current app direction. `StoreKitService.hasProUnlock` now defaults to true, and Settings presents the app as a free full desk.
- Built and installed signed Release builds on the paired iPhone `ZZZ`. The latest installed build uses the three-tab strategy rail direction. The final launch command disconnected after install, but the install completed successfully.

## Important Findings

- The app is not a website, game, generic trading app, or AI app. It is a broker-desk utility with function and attitude.
- The practical product is simple: VXX setup, VXX/VIX ratio, VWAP/level, volume confirmation, correct time window, prompt if useful, execute on broker, manage risk. Execution belongs on the actual trading platform.
- iPhone should be the lead release surface, but the UI still needs market-hours evaluation for legibility, speed, and whether each screen earns its place.
- The app should be described as a manual, local-first trading discipline desk. It should not promise signals, win rates, financial advice, or automated execution.
- The visual system should feel like wealth, grit, and balls through utility, not through hype. Avoid website/video-game treatment, decorative cards, novelty motion, and fake authority copy.
- Remaining orange/purple accents should be audited because they read off-brand and can make the app feel like an AI template.
- There are multiple launch/metadata docs with stronger internal language than App Review should see.
- StoreKit code still exists, but the release direction is no paywall. It should be removed or isolated later rather than shipped as a monetization promise.
- There is no test target.
- watchOS belongs on the future punch list only.

## Suggested Next Session

1. Test the installed Release build on `ZZZ` during market hours. Judge it by speed, legibility, and whether it helps with VXX/VWAP/time-window decisions.
2. Continue stripping any UI that has no function. Big text, direct controls, fewer surfaces.
3. Collapse old inherited screens into the strategy rail where possible. The app should not feel like many pages.
4. Audit VXX, Tape, Prompts, and Risk screens for phone readability and remove decorative/card-heavy sections that do not help the trade workflow.
5. Scrub public-facing copy in UI and docs for App Review safety, including removal of premium/pro/unlock promises.
6. Add a test target and cover time windows, VXX/VIX ratio thresholds, VWAP logic, prompt substitution, daily risk, and persistence.
7. Prepare App Store metadata and screenshots only after the phone workflow feels like a real desk.

## Files To Start With

- `docs/RELEASE_PUNCH_LIST.md`
- `docs/AppStoreMetadata.md`
- `docs/MARKETING.md`
- `Steel_Trading_Desk/Views/MainView.swift`
- `Steel_Trading_Desk/Views/TradingDashboard.swift`
- `Steel_Trading_Desk/Views/VXXTradingDashboard.swift`
- `Steel_Trading_Desk/Views/ManualDataEntryView.swift`
- `Steel_Trading_Desk/Views/PromptCoachView.swift`
- `Steel_Trading_Desk/Views/Components/DesignSystem.swift`

## Open Risks

- App Review may object to performance claims or language that sounds like actionable financial advice.
- The iPhone UI may still be too dense in VXX, Tape, Prompt, and Risk flows.
- Some screens may still contain UI without enough function. These should be cut or rewritten before TestFlight.
- Background monitoring on iOS needs a stricter review before it is described as a release feature.
- Mac App Store builds may need different update-checker behavior than direct-distribution builds.
- External TestFlight should wait until first-run disclaimer, privacy copy, and manual-only positioning are clear.
