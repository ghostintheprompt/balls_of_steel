# Steel Trading Desk: Release & Submission Guide

This document consolidates the technical details and submission steps for the **Steel Trading Desk** (`app.mdrn.steel`) launch.

## 1. Technical Identity

*   **App Name:** Steel Trading Desk
*   **Bundle Identifier:** `app.mdrn.steel` (multiplatform: iOS + macOS)
*   **Version:** 1.0
*   **Platforms:** iOS 17.0+, iPadOS 17.0+, macOS 14.0+
*   **Privacy Manifest:** Included (`PrivacyInfo.xcprivacy`) — zero data collection
*   **App Tracking Transparency:** Not requested (we don't track)

## 2. Free Full Desk

The release is no-paywall. The full VXX/VIX/VWAP discipline workflow, embedded TradingView chart, prompt support, risk tools, and live-data integration (when a user-provided API key is present) are available without an in-app purchase. StoreKit / paywall code has been removed from the release path.

## 3. Final Playtest Checklist

Before hitting "Submit" in App Store Connect, verify these flows on real device (`ZZZ`) and a fresh simulator:

- [ ] **Disclaimer.** First-run `DisclaimerView` appears before any trading workflow.
- [ ] **Tape logic.** Enter `volume 350%`, `VXX/VIX ratio 1.62`, VWAP/key-level confirmation, and a rejection pattern. Verify the gate sequence clears in order; the NEXT MOVE verb cycles `WAIT` → `WAIT LEVEL` → `WAIT PATTERN` → `CLEARED`.
- [ ] **Divergence gate.** Toggle live data on. When VIX is outpacing VXX (negative divergence), gate 2 (Ratio) fails with explicit copy ("Ratio is compressing — do not fade"), even at a stretched ratio.
- [ ] **Hard-exit takeover.** Between 15:50 and 16:10 ET, the iPhone screen is fully replaced by the red countdown takeover. (For testing outside that window, temporarily adjust the time check in `TradingDashboard.currentDeskState`.)
- [ ] **Live data + Plex.** With a Finnhub key configured, the Mac status footer shows "QUOTES · LIVE · Ns" and the iPhone shows the small green LIVE pulse. IBM Plex renders correctly throughout (Mono numbers, Sans body, Sans Condensed Bold hero verb).
- [ ] **Embedded chart.** TradingView widget loads in the chart center (Mac/iPad) and the iPhone mini-chart. Chart footer shows "TRADINGVIEW · 15M DELAYED."
- [ ] **No-key fallback.** With no API key configured, "Auto-populate from provider" is off and the manual tape entry is the source of truth. The desk works fully on manual entry alone.

## 4. App Store Submission Assets

All metadata drafts live in `docs/APP_STORE_CONNECT_COPY.md` (canonical paste sheet) and `docs/AppStoreMetadata.md` (companion summary).

### Screenshot Requirements

*   **iPhone 6.7":** 1290 × 2796 (or 1284 × 2778)
*   **iPhone 6.5":** 1242 × 2688
*   **iPad Pro 12.9" (6th gen and later):** 2048 × 2732
*   **macOS:** 1280 × 800 (minimum)

### Suggested screenshot order

1. iPhone Desk default — ticker strip + NEXT MOVE verb + 4-gate stack with amber blocker highlight
2. iPhone gate-detail sheet — big number + tier table + house rule
3. iPhone hard-exit takeover — red countdown + open positions + 3 exit rules
4. iPad / Mac terminal — three-column layout populated with live tape
5. Settings → Data Source — provider picker + API key field + auto-populate toggle

### Reviewer Note (the compliance guard)

> Steel Trading Desk is an educational utility for discretionary traders. It does not execute trades, manage funds, or provide regulated financial advice. All trade entries are made manually by the user on their broker.
>
> The app accepts manual tape entries (VXX, VIX, volume, VWAP, key level, pattern, time window) and evaluates them against a fixed discipline framework (four gates in order). Optional live-data integration uses *user-provided* API keys for Finnhub, Polygon, Schwab, or Yahoo — no proxy, no shared keys, no account required to use the app.
>
> The default state on first launch is fully manual: the reviewer can exercise the entire app without configuring any external service. The TradingView chart embed loads with public delayed data and requires no account.

## 5. Build & Upload Procedure

1. **Sanitize** `.env` at repo root before archiving (clear `FINNHUB_API_KEY` / `POLYGON_API_KEY`). The file IS bundled in the IPA; the loader is `#if DEBUG`-gated, but defense-in-depth.
2. **Xcode** → open `Steel_Trading_Desk.xcodeproj`.
3. **Target** → `Steel_Trading_Desk` > `Any iOS Device (arm64)` (then repeat for `Any Mac`).
4. **Archive** → `Product > Archive`.
5. **Validate** → run App Store validation in the Organizer.
6. **Distribute** → upload to App Store Connect.

---

**Status:** Boiler-room redesign complete (9 phases shipped). Live-data plumbing real. Pending before TestFlight: Plex license inclusion, real-key validation against Finnhub API, screenshots, test target. See `docs/RELEASE_PUNCH_LIST.md` for the full P0 list.
