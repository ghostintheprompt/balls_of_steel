# Testing & Development Guide

## Quick Launch Options

### Option 1: Double-Click the App (Easiest)

After building, you can double-click **Balls_of_Steel.app** in the project root.

**Note:** This is a copy of the built app. If you make code changes, you need to rebuild.

---

### Option 2: Build & Launch Script

Run the automated build and launch script:

```bash
./launch_app.sh
```

This will:
1. Build the latest code
2. Copy the app to project root
3. Launch the app automatically

---

### Option 3: Xcode Run

Open `Balls_of_Steel.xcodeproj` in Xcode and press **⌘R** (Run).

This is best for active development with debugging.

---

### Option 4: Manual Build & Open

```bash
# Build
xcodebuild -scheme Balls_of_Steel -configuration Debug build

# Copy to project root
cp -R ~/Library/Developer/Xcode/DerivedData/Balls_of_Steel-*/Build/Products/Debug/Balls_of_Steel.app .

# Launch
open Balls_of_Steel.app
```

---

## Testing the VXX/VIX Ratio Feature

1. Launch the app
2. Go to **Manual Data Entry**
3. Enter test data:
   - **VXX:** 29.50
   - **VIX:** 19.48
   - **Volume:** 340%

4. Watch the **VXX/VIX Ratio** section appear automatically:
   - Should show: **Ratio: 1.51**
   - Tier: **Normal Fade ⭐**
   - Position: **$350**
   - Visual threshold guide with position marker

5. Try different ratios:
   - **1.62** (Premium Fade) = Green, $500 position
   - **1.58** (Strong Fade) = Yellow, $450 position
   - **1.48** (Normal Fade) = Cyan, $350 position
   - **1.38** (Weak Fade) = Orange, $200 position
   - **1.32** (No Fade) = Red, $0 position (skip trade)

---

## Debugging Tips

### View Console Logs

While the app is running:

```bash
log stream --predicate 'process == "Balls_of_Steel"' --level debug
```

### Check for Crashes

```bash
log show --predicate 'process == "Balls_of_Steel" AND eventMessage CONTAINS "crash"' --last 1h
```

### Reset App Data

To clear UserDefaults and start fresh:

```bash
defaults delete com.yourcompany.Balls-of-Steel
```

---

## Known Issues

- App is in educational mode (manual data entry only)
- No live API integration
- StoreKit (in-app purchase) requires Apple Developer account for testing

---

## Build Artifacts

- Built app: `Balls_of_Steel.app` (in project root)
- Xcode build: `~/Library/Developer/Xcode/DerivedData/Balls_of_Steel-*/Build/Products/Debug/`

The `.app` bundle is excluded from git (see `.gitignore`).
