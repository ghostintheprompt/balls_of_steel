# 🚀 Steel Trading Desk: Release & Submission Guide

This document consolidates all MDRN-standard technical details and submission steps for the **Steel Trading Desk** (app.mdrn.steel) launch.

## 1. Technical Identity
*   **App Name:** Steel Trading Desk
*   **Bundle Identifier:** `app.mdrn.steel` (Multiplatform)
*   **Version:** 1.0.0
*   **Platforms:** iOS 17.0+ / macOS 14.0+
*   **Privacy Manifest:** Included (`PrivacyInfo.xcprivacy`) — **Zero Data Collection**.

## 2. Institutional Pro (Freemium Split)
The app uses a "Educational Mode" by default. The following features are gated behind the **Institutional Pro** one-time IAP (`app.mdrn.steel.pro_unlock`):
*   **Schwab API Integration:** Real-time data streaming (currently in broker placeholder mode).
*   **Supreme Prompt Library:** High-level Institutional Flow and Power Hour prompts in the Prompt Coach.
*   **Unlimited Journaling:** Access to complete historical data and P&L analytics.

## 3. Final Playtest Checklist
Before hitting "Submit" in App Store Connect, verify these flows in the Simulator:
- [ ] **Gating Check:** Ensure **Settings > Institutional Pro** says "LOCKED" and Prompt Coach is obscured.
- [ ] **Purchase Flow:** Tap "Unlock" and simulate a success. Verify the Schwab API card appears in Settings.
- [ ] **Tape Logic:** Enter `350% Volume` in the Manual tab; verify the **VXX Dashboard** triggers the high-contrast Institutional Flow glow.
- [ ] **Data Freshness:** Verify the "Open first. Close honest." tagline is visible on the main desk.

## 4. App Store Submission Assets
All metadata drafts are located in `docs/AppStoreMetadata.md`.

### Screenshot Requirements
*   **iPhone 6.7":** 1290 x 2796 pixels (or 1284 x 2778)
*   **iPhone 6.5":** 1242 x 2688 pixels
*   **iPad Pro 12.9":** 2048 x 2732 pixels
*   **macOS:** 1280 x 800 pixels (min)

### Reviewer Note (The Compliance Guard)
> "This app is an Educational Utility for market analysis. It does not manage funds or provide regulated financial advice. All trading is manual or via user-initiated API. A 'Demo Mode' with sample data is enabled by default to allow full UI inspection without a brokerage account."

## 5. Build & Upload Procedure
1.  **Xcode:** Open `Steel_Trading_Desk.xcodeproj`.
2.  **Target:** Select `Steel_Trading_Desk` > `Any iOS Device (arm64)`.
3.  **Archive:** `Product > Archive`.
4.  **Validate:** Run the App Store validation in the Organizer.
5.  **Distribute:** Upload to App Store Connect.

---
**Status:** Code is hardened. Assets are drafted. Ready for launch.
