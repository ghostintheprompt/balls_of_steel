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

Latest signed Release installed and launched on `ZZZ` after the `NEXT MOVE` command-card pass:

```sh
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj -scheme Steel_Trading_Desk -configuration Release -destination 'platform=iOS,id=00008120-000E64960CE9A01E' -derivedDataPath /private/tmp/balls_of_steel_device_release_command DEVELOPMENT_TEAM=9TB25L4266 CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY='Apple Development' build
xcrun devicectl device install app --device DC63616F-433E-5833-9255-BE85AAFC9A7A /private/tmp/balls_of_steel_device_release_command/Build/Products/Release-iphoneos/Steel_Trading_Desk.app
xcrun devicectl device process launch --device DC63616F-433E-5833-9255-BE85AAFC9A7A app.mdrn.steel
```

## What Changed In This Pass

Boiler-room redesign per `CLAUDE_CODE_DIRECTIONS.md`. All 9 phases shipped.

- **Phase 1 — Token swap.** New palette (CRT amber `#FFB000` on near-black) and IBM Plex font stack. System fallback wired; Plex `.ttf` files pending bundling.
- **Phase 2 — Decoration killed.** Every cornerRadius → 2pt, every shadow/glow on cards removed, every bare `.purple/.orange/.yellow/.cyan/.gray` color replaced with a `DesignSystem` token, large fixed paddings collapsed.
- **Phase 3 — Mac single-window terminal.** Three-column layout (ticker strip / left rail gate spine / chart center / right rail NEXT MOVE+RAW READ+SECOND READ+ET clock / status footer). Mac TabView removed.
- **Phase 4 — iPhone gate-spine.** Phone home is ticker strip → NEXT MOVE verb → 4-gate stack with amber blocker highlight + tap-through → mini chart → ET clock + hard-stop countdown footer. Tapping a gate opens a drill-in sheet with big number + tier table + house rule.
- **Phase 5 — TradingView chart embed.** New `Views/Components/ChartWebView.swift` (cross-platform WKWebView). VWAP + SMA + Volume overlays. 15-min delayed disclosure in chart footer.
- **Phase 6 — MarketDataProvider scaffolding.** Protocol + 4 provider files (`Finnhub`, `Polygon`, `Schwab`, `Yahoo`). Settings has a segmented picker + per-provider setup note + API key field. Real network calls stubbed; gates still consume manual tape entry.
- **Phase 7 — DeskState machine.** New `Models/DeskState.swift`. iPhone hard-exit takeover (15:50–16:10 ET) drives off `DeskState.isTakeover`.
- **Phase 8 — Notification copy.** Every body string in `SignalNotification.swift` rewritten to blunt diagnosis tone. Registered `STEEL_DESK` notification category with "Open Desk" foreground action.
- **Phase 9 — App Store metadata.** Subtitle synced to "Native Volatility Analysis Tool". Promo text + description rewritten to mention chart embed and hard-exit takeover. `RELEASE_PUNCH_LIST.md` refreshed to reflect what's done vs. what remains.

## Important Findings

- The app is not a website, game, generic trading app, or AI app. It is a broker-desk utility with function and attitude.
- The practical product is simple: VXX setup, VXX/VIX ratio, VWAP/level, volume confirmation, correct time window, prompt if useful, execute on broker, manage risk. Execution belongs on the actual trading platform.
- iPhone should be the lead release surface, but the UI still needs market-hours evaluation for legibility, speed, and whether each screen earns its place.
- The app should be described as a manual, local-first trading discipline desk. It should not promise signals, win rates, financial advice, or automated execution.
- The visual system should feel like wealth, grit, and balls through utility, not through hype. Avoid website/video-game treatment, decorative cards, novelty motion, and fake authority copy.
- Remaining orange/purple accents should be audited because they read off-brand and can make the app feel like an AI template.
- There are multiple launch/metadata docs with stronger internal language than App Review should see.
- The release direction is no paywall. Keep it that way unless monetization returns later as patronage, support, or serious investor interest earned by usefulness.
- Internal monetization note: VXX stays free. If a paid trading product exists later, the SPY version is the candidate, as a separate serious offer. Do not put this in public App Store copy.
- There is no test target.
- watchOS belongs on the future punch list only.

## Suggested Next Session

1. Bundle IBM Plex `.ttf` files (Mono Regular + SemiBold, Sans Regular + SemiBold, Sans Condensed Bold + Black) into `Resources/Fonts/`, add `UIAppFonts` to `Info.plist`, flip `DesignSystem.Typography.useSystemFallback = false`.
2. Build + install signed Release on `ZZZ` and evaluate the boiler-room redesign during market hours. Verify the hard-exit takeover fires at 15:50 ET. Check ticker strip readout updates as tape entry changes.
3. Wire real Finnhub network code in `FinnhubProvider.swift` (REST `/quote`, WebSocket `wss://ws.finnhub.io`). Swap `UserDefaults`-backed key storage for `KeychainService`.
4. Refresh App Store screenshots: iPhone (Desk + gate-detail + hard-exit), iPad/Mac (terminal layout). Re-render the icon since the SteelDeskMark is now amber-on-black.
5. Add an XCTest target. Cover `TimeManager` window logic, `DeskState.current(...)` boundary times, `VXXStrategyState.firstFailingGateIndex`, ratio threshold tiers.
6. Scrub `LAUNCH_GUIDE.md` / `LAUNCH_PLAN.md` / `MARKETING.md` for any remaining "Pro/Premium/Coach/win-rate %" leakage and reconcile with `APP_STORE_CONNECT_COPY.md` as the canonical source.

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
