# Build Instructions

## Prerequisites
- macOS 14.0+
- Xcode 15.0+

## Development Build
1. Clone the repo:
   ```bash
   git clone https://github.com/ghostintheprompt/balls-of-steel.git
   cd balls-of-steel
   ```
2. Open the project:
   ```bash
   open Steel_Trading_Desk.xcodeproj
   ```
3. Build and Run:
   - Select the **Steel_Trading_Desk** scheme.
   - Set destination to **My Mac**.
   - Press `Cmd + R`.

## Release Build (DMG)
To package the app for distribution:
1. Ensure the project is clean.
2. Run the DMG creation script:
   ```bash
   ./make_dmg.sh
   ```
   This will generate `Steel_Trading_Desk.dmg` in the project root.

## Troubleshooting
- **Code Signing:** If you encounter code signing errors, go to the **Signing & Capabilities** tab in Xcode and select your personal development team.
- **Dependencies:** This project uses no external dependencies (no Swift Package Manager, no CocoaPods). If build fails, ensure your Xcode command line tools are up to date: `xcode-select --install`.
