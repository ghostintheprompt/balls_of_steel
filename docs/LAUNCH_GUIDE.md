# 🚀 Steel Trading Desk: Release & Submission Guide

This document consolidates all MDRN-standard technical details and submission steps for the **Steel Trading Desk** (app.mdrn.steel) launch.

## 1. Technical Identity
*   **App Name:** Steel Trading Desk
*   **Bundle Identifier:** `app.mdrn.steel` (Multiplatform)
*   **Version:** 1.0.0
*   **Platforms:** iOS 17.0+ / macOS 14.0+
*   **Privacy Manifest:** Included (`PrivacyInfo.xcprivacy`) — **Zero Data Collection**.

## 2. Free Full Desk
The release direction is no paywall. The VXX/VIX/VWAP workflow, prompt support, and risk tools are available without an in-app purchase. StoreKit/paywall code has been removed from the release path.

## 3. Final Playtest Checklist
Before hitting "Submit" in App Store Connect, verify these flows in the Simulator:
- [ ] **Access Check:** Ensure the desk is fully usable without purchase prompts.
- [ ] **Tape Logic:** Enter `350% Volume`, VXX/VIX ratio above `1.45`, VWAP/key-level confirmation, and rejection pattern; verify the Desk sequence clears only after every gate passes.
- [ ] **Data Freshness:** Verify the Desk starts with the VXX sequence, not a marketing page or generic dashboard.

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
**Status:** Release build path is real. Phone workflow still needs market-hours field testing before TestFlight.
