# Build Instructions

## Prerequisites

- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+ (Xcode 16 recommended)
- Apple Developer account (free is fine for local installs; paid required for TestFlight / App Store)

## Clone

```bash
git clone https://github.com/ghostintheprompt/balls_of_steel.git
cd balls_of_steel
open Steel_Trading_Desk.xcodeproj
```

The repo is private. Internal codename is "balls of steel"; the public-facing app is **Steel Trading Desk**.

## First-time setup

### 1. IBM Plex fonts (already bundled)

Five `.ttf` files live in `Steel_Trading_Desk/Resources/Fonts/` and are wired into the Xcode target via `Info.plist > UIAppFonts`:

- `IBMPlexSans-Regular.ttf`
- `IBMPlexSans-SemiBold.ttf`
- `IBMPlexSans_Condensed-Bold.ttf`
- `IBMPlexMono-Regular.ttf`
- `IBMPlexMono-SemiBold.ttf`

Source: [github.com/IBM/plex/releases](https://github.com/IBM/plex/releases). Bundled under SIL Open Font License.

### 2. Optional: Debug credentials

The app's live-data roadmap is Schwab Trader API market-data streaming. Live credentials are only for market data and alert accuracy; the app must never place orders, read balances, manage positions, or automate brokerage activity.

For dev, `EnvSeeder.swift` (`#if DEBUG` only) reads process environment variables and seeds platform Keychain values on launch. Add these values to the Xcode scheme's **Run -> Arguments -> Environment Variables** panel, or pass them through a local launch wrapper:

```bash
#   SCHWAB_APP_KEY=your_schwab_app_key
#   SCHWAB_APP_SECRET=your_schwab_app_secret
```

`.env` is gitignored and may be useful as a local note, but it is not copied into the app bundle and the app does not read it directly. Do not add `.env` back to the Xcode resource phase.

The product path is Schwab streaming with fail-closed alerting. Stale, delayed, simulated, partial, disconnected, or unverifiable data must not trigger a live alert or unlock the chart.

Schwab portal setup lives in `docs/SCHWAB_DEV_PORTAL_WALKTHROUGH.md`. Use that doc for the exact Market Data Production, callback URL, and order-limit choices.

## Run on simulator

```
Scheme: Steel_Trading_Desk
Destination: any iPhone simulator
Cmd + R
```

## Run on Mac

```
Scheme: Steel_Trading_Desk
Destination: My Mac
Cmd + R
```

## Run on physical iPhone

The Mac/simulator paths are good for most dev. For market-hours real-device testing on the paired iPhone (named `ZZZ` in our setup):

```bash
# Build (Release works reliably; Debug is sometimes flaky on this device)
xcodebuild -quiet -project Steel_Trading_Desk.xcodeproj \
  -scheme Steel_Trading_Desk -configuration Release \
  -destination 'platform=iOS,id=00008120-000E64960CE9A01E' \
  -derivedDataPath /private/tmp/balls_of_steel_device \
  DEVELOPMENT_TEAM=9TB25L4266 \
  CODE_SIGN_STYLE=Automatic \
  build

# Install
xcrun devicectl device install app \
  --device DC63616F-433E-5833-9255-BE85AAFC9A7A \
  /private/tmp/balls_of_steel_device/Build/Products/Release-iphoneos/Steel_Trading_Desk.app

# Launch
xcrun devicectl device process launch \
  --device DC63616F-433E-5833-9255-BE85AAFC9A7A \
  app.mdrn.steel
```

Tradeoff: Release builds skip `EnvSeeder` (it's `#if DEBUG`-gated), so Schwab developer credentials must be entered through Settings -> Schwab Developer Access. After that, they persist in the device Keychain.

Signing note: do not force `CODE_SIGN_IDENTITY` for real-device Release builds. Let Xcode pair the installed signing identity with the MDRN wildcard development profile automatically; forcing `Apple Development` can select the wrong identity/profile path and make signing flaky.

## Release archive (App Store / TestFlight)

1. **Verify `.env` is not in the Xcode resource phase.** It should not appear under Copy Bundle Resources. Do not ship a real key in the IPA.
2. Open the project in Xcode.
3. **Set version + build number** in the project's General tab.
4. **Set destination** to `Any iOS Device (arm64)` for iOS, or `Any Mac` for macOS.
5. **Product > Archive.**
6. **Validate** in the Organizer (catches most App Store Connect issues early).
7. **Distribute** to App Store Connect.

The full submission checklist lives in `docs/LAUNCH_GUIDE.md`. App Store metadata (description, keywords, review notes, privacy manifest) is in `docs/APP_STORE_CONNECT_COPY.md` — the canonical paste sheet.

## Troubleshooting

- **Code Signing.** If you hit signing errors, open Signing & Capabilities in Xcode and select your personal Developer team. The repo defaults to MDRN's team ID; override locally.
- **Dependencies.** Zero external dependencies — no SPM packages, no CocoaPods. If a build fails, run `xcode-select --install` to refresh command-line tools.
- **SourceKit phantom errors.** The Xcode SourceKit-LSP throws constant "Cannot find DesignSystem in scope" / "Cannot find SignalMonitor in scope" diagnostics that are stale. Trust `xcodebuild`, not the live LSP indicator.
- **Stale build artifacts in `/tmp`.** The xcodebuild commands above use `/private/tmp/balls_of_steel_*` derived-data paths. Old runs accumulate. `rm -rf /private/tmp/balls_of_steel_*` cleans them all.
