# Steel Trading Desk Handoff

Last updated: May 11, 2026

## Current State

The repo is a native SwiftUI Xcode project with one app target: `Steel_Trading_Desk`. The target supports `macosx`, `iphoneos`, and `iphonesimulator`. There is no watchOS target yet.

Verified builds:

```sh
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Debug -destination generic/platform=iOS -derivedDataPath /private/tmp/balls_of_steel_ios_build CODE_SIGNING_ALLOWED=NO build
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Debug -destination platform=macOS -derivedDataPath /private/tmp/balls_of_steel_mac_build CODE_SIGNING_ALLOWED=NO build
```

Both commands pass as of this handoff.

## What Changed In This Pass

- Added the missing `VXXTradingWindow.swift` build phase reference so the target compiles cleanly.
- Cleaned small Swift warnings:
  - `Date+Trading.swift`: removed an unused time zone local.
  - `TechnicalIndicators.swift`: changed an immutable sorted list from `var` to `let`.
  - `SettingsView.swift`: updated `onChange` to the iOS/macOS 17 form.
- Confirmed the current iOS and macOS build paths pass.
- Removed workspace `.DS_Store` files from the project folder.
- Added this handoff and the release punch list.

## Important Findings

- iPhone should be the lead release surface. The app has enough shared SwiftUI structure to support that, but it still needs a real phone UX review.
- The app should be described as a manual, local-first trading discipline desk. It should not promise signals, win rates, financial advice, or automated execution.
- The visual system is not brown-first. It is mostly obsidian/electric cyan with green/red/yellow status colors. Remaining orange accents should be audited because they can read off-brand if overused.
- There are multiple launch/metadata docs with stronger internal language than App Review should see.
- StoreKit exists in code, but product configuration and purchase/restore testing still need App Store Connect verification.
- There is no test target.
- watchOS belongs on the future punch list only.

## Suggested Next Session

1. Run the app on an iPhone simulator or device and screenshot every primary flow.
2. Fix phone layout issues first: tab count, clipped text, dense cards, paywall, settings, onboarding, and manual entry.
3. Scrub public-facing copy in UI and docs for App Review safety.
4. Add a test target and cover time windows, signal/watch logic, prompt substitution, daily risk, and persistence.
5. Prepare App Store metadata and screenshots only after the phone UX is stable.

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
- The iPhone UI may be too dense without a compact information architecture pass.
- Background monitoring on iOS needs a stricter review before it is described as a release feature.
- Mac App Store builds may need different update-checker behavior than direct-distribution builds.
- External TestFlight should wait until first-run disclaimer, privacy copy, and manual-only positioning are clear.
