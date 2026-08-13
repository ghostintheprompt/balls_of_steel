# Steel Trading Desk — Launch Guide

**Single source for v1.0 release & submission.** Merged from former `LAUNCH_GUIDE.md` + `LAUNCH_PLAN.md` on 2026-05-16. Day-to-day P0 work lives in `docs/RELEASE_PUNCH_LIST.md`; canonical App Store metadata in `docs/APP_STORE_CONNECT_COPY.md`. This file is the runbook + status.

---

## 1. Where we are now (2026-05-25)

- **Boiler-room redesign complete.** All 9 phases shipped. Both iOS + macOS Debug builds verified green via `xcodebuild` (last verified 2026-05-14). Signed Release installed on paired iPhone `ZZZ` 2026-05-13.
- **Compliance + branding clean.** App named "Steel Trading Desk", subtitle "Native Volatility Analysis Tool". No "Pro/Premium/Coach/Unlock" surfaces anywhere. Disclaimer wired. Privacy policy refreshed (`docs/PRIVACY.md`). Privacy Manifest present. App Tracking Transparency not requested.
- **Schwab live tape is the only live-data path.** The old third-party provider scaffolding was removed. Live alerts and the chart fail closed unless the user enters Schwab developer credentials, completes OAuth, and the feed returns fresh VXX/VIX data.
- **Schwab OAuth/live tape is wired for market data only.** The app stores user-supplied developer credentials locally, completes OAuth, enables the live tape after token exchange, and keeps Schwab order/account APIs out of scope.
- **All targets building** — iOS, iPadOS, macOS. Three-column terminal layout on macOS, native Swift Charts on iPhone (tile + fullscreen sheet with VWAP / 20-50 SMA / window stripes / volume panel / ratio tier band / pattern markers / tap-to-OHLCV).

---

## 2. Technical identity

- **App name:** Steel Trading Desk
- **Bundle ID:** `app.mdrn.steel` (multiplatform: iOS + macOS)
- **Version:** 1.0
- **Platforms:** iOS 17.0+, iPadOS 17.0+, macOS 14.0+
- **Privacy manifest:** `PrivacyInfo.xcprivacy` — zero data collection
- **App Tracking Transparency:** not requested

---

## 3. Release posture

The release is no-paywall. Full VXX/VIX/VWAP discipline workflow, Schwab-gated native chart, prompt support, session-close takeover, and manual tape entry are available without in-app purchase. StoreKit / paywall code is not in the release path.

| Area | Release Posture |
| :--- | :--- |
| Manual entry | Full tape entry for VXX, VIX, volume, VWAP, key level, pattern, window, news |
| Desk sequence | Full five-condition setup check: volume, valid window, ratio, VWAP/key level, rejection pattern. Each condition is visible on phone, iPad, and desktop. |
| Accuracy posture | Alerts must fail closed. Stale, delayed, simulated, partial, disconnected, or unverifiable data is labeled and cannot trigger a live alert. |
| Chart | Native chart on all platforms, unlocked only by verified Schwab live candles; otherwise a locked source state is shown |
| Live data | Schwab market data only. Requires the user's own Schwab developer app key/secret plus OAuth; stale or disconnected data fails closed. |
| Prompt Desk | Available without purchase prompts |
| Risk tools | Available without purchase prompts |
| Brokerage | Manual execution only — phone alert, quick human review, user fires any order in Thinkorswim/Schwab or another broker |

Monetization is the separate **Steel SPY Desk** paid app planned alongside this free VXX app — never a feature gate on this build. See `STRATEGY_NOTES.md` "Paid product" section.

---

## 4. Critical risks

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| Financial-regulation framing | High | Public copy emphasizes "manual entry", "discipline", "educational utility". App never claims directional recommendations or win rates. |
| Bad-data alert | High | Live alerts require verified source, freshness timestamp, complete VXX/VIX/VWAP inputs, and explicit non-delayed/non-simulated status. Otherwise the app fails closed and suppresses the alert. |
| Value-prop drift | Medium | Position as a personal five-condition setup checker for multitasking and fast human review, not a generic trading dashboard or automated system. |
| Schwab credentials accidentally bundled | High | `.env` is not in Copy Bundle Resources. Pre-archive check: no credential files in app bundle, no real credentials in scheme/archive settings. |
| Scope creep | Medium | Hard rule: every feature must serve the one strategy (VXX/VIX divergence fade). |
| Schwab portal approval / callback drift | Medium | Keep the callback URL exactly matched between Settings and the Schwab Developer Portal. OAuth/token failures must remain visible and fail closed. |
| Two-app shipping plan (free VXX + paid SPY) | Medium | Not a v1.0 risk. Re-check App Review guidelines around paid trading-adjacent apps before SPY submission, especially around anything that could read as a signals subscription. |

---

## 5. Final playtest checklist

Verify on real device (`ZZZ`) and a fresh simulator before "Submit":

- [ ] **Disclaimer.** First-run `DisclaimerView` appears before any trading workflow.
- [ ] **Tape logic.** Enter `volume 350%`, valid time window, `VXX/VIX ratio 1.62`, VWAP/key-level confirmation, and a rejection pattern. The five-condition check clears in order; the NEXT MOVE verb cycles `WAIT` → `WAIT LEVEL` → `WAIT PATTERN` → `CLEARED`.
- [ ] **Divergence read.** Live data showing VIX outpacing VXX at a stretched ratio surfaces explicit caution copy ("VIX is leading VXX — wait for a cleaner read or size down").
- [ ] **Session-close takeover.** From 16:10 to 16:15 ET, the iPhone screen is fully replaced by the red close-management countdown. (For testing outside that window, temporarily adjust the time check in `TradingDashboard.currentDeskState`.)
- [ ] **Settings -> Systems.** Schwab credentials paste/save cleanly, OAuth opens in-app, the diagnostics row shows a clean client_id, alerts can be enabled after permission, and no labels are cropped on phone or Mac.
- [ ] **Chart.** Without Schwab OAuth, the chart shows the locked Schwab-live-required state. With OAuth/live tape, native candles and all overlays render.
- [ ] **Plex fonts.** IBM Plex renders correctly throughout (Mono numbers, Sans body, Sans Condensed Bold hero verb).
- [ ] **Strategy Audit.** Settings → Strategy Audit runs end-to-end and returns PASS for all categories.

---

## 6. App Store submission assets

Canonical paste sheet for App Store Connect: `docs/APP_STORE_CONNECT_COPY.md`.

### Screenshot specs

- **iPhone 6.7":** 1290 × 2796 (or 1284 × 2778)
- **iPhone 6.5":** 1242 × 2688
- **iPad Pro 12.9" (6th gen and later):** 2048 × 2732
- **macOS:** 1280 × 800 minimum

### Suggested screenshot order

1. iPhone Desk default — ticker strip + NEXT MOVE verb + five-condition stack with amber blocker highlight
2. iPhone gate-detail sheet — big number + tier table + house rule
3. iPhone fullscreen chart sheet — native chart with VWAP / SMA / window stripes / volume panel / ratio tier band / pattern markers
4. iPhone session-close takeover: red countdown + open positions + 3 close-management rules
5. iPad / Mac terminal — three-column layout with gate spine + chart center + right rail

### Reviewer note (compliance guard)

> Steel Trading Desk is an accuracy-first setup-checking utility for discretionary VXX/VIX volatility traders. It does not execute trades, manage funds, or provide regulated financial advice. It implements a personal five-condition entry checklist so the user can multitask, receive a phone alert, quickly review the read, and manually execute on their own brokerage platform.
>
> Manual tape entry works without credentials. Settings also includes Schwab Developer Access for users who have their own Schwab developer account; the user enters an app key/client ID and app secret, stored locally in Keychain. Steel ships with no shared Schwab secret. Schwab order placement, account balances, positions, and automated execution are out of scope.
>
> The core value of the app is accuracy-gated alerting. The live-data path suppresses alerts when data is stale, delayed, simulated, partial, disconnected, or unverifiable. The workflow is phone alert, quick human review to confirm the read is not bad, manual execution in Thinkorswim/Schwab or another broker.
>
> The reviewer can exercise the manual-entry workflow on first launch with no external service configuration. The chart clearly states Schwab live data is required until OAuth/live tape is connected.

---

## 7. Build & upload procedure

1. **Credential check** before archiving — `.env` must not be in Copy Bundle Resources, no real Schwab credentials in archive scheme settings, no credential file in the app bundle.
2. **Xcode** → open `Steel_Trading_Desk.xcodeproj`.
3. **Target** → `Steel_Trading_Desk` > `Any iOS Device (arm64)` (then repeat for `Any Mac`).
4. **Archive** → `Product > Archive`.
5. **Validate** → run App Store validation in the Organizer.
6. **Distribute** → upload to App Store Connect.

Full `xcodebuild` matrix for headless verification: `docs/HANDOFF.md` "Current State" block.

---

## 8. Submission roadmap

1. **Plex license in app bundle** — `Steel_Trading_Desk/Resources/Fonts/license.txt` exists on disk (4360 bytes) but is not registered in `Steel_Trading_Desk.xcodeproj/project.pbxproj`. Tiny pbxproj edit. SIL Open Font License compliance.
2. **Test target** — XCTest covering `TimeManager` window logic, `DeskState.current(...)` boundary times, ratio threshold tiers, `VXXStrategyState.firstFailingGateIndex`, candle aggregation rollup math, divergence-gate behavior.
3. **App Store assets refresh** — screenshots reflect the new native chart tile; re-render icon (SteelDeskMark is amber-on-black).
4. **Build verification on `ZZZ`** — install signed Release, walk the full §5 checklist on device during market hours.
5. **Final credential check** + `/tmp` build-artifact cleanup.
6. **Archive + validate + upload** — per §7.
7. **TestFlight external** review.
8. **App Store submission** with `docs/APP_STORE_CONNECT_COPY.md` as paste source.

Day-to-day P0 work tracked in `docs/RELEASE_PUNCH_LIST.md`.

---

Schwab portal setup remains documented in `docs/SCHWAB_DEV_PORTAL_WALKTHROUGH.md`; implementation status lives in the source and this guide.
