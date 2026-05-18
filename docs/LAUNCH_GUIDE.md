# Steel Trading Desk — Launch Guide

**Single source for v1.0 release & submission.** Merged from former `LAUNCH_GUIDE.md` + `LAUNCH_PLAN.md` on 2026-05-16. Day-to-day P0 work lives in `docs/RELEASE_PUNCH_LIST.md`; canonical App Store metadata in `docs/APP_STORE_CONNECT_COPY.md`. This file is the runbook + status.

---

## 1. Where we are now (2026-05-16)

- **Boiler-room redesign complete.** All 9 phases shipped. Both iOS + macOS Debug builds verified green via `xcodebuild` (last verified 2026-05-14). Signed Release installed on paired iPhone `ZZZ` 2026-05-13.
- **Compliance + branding clean.** App named "Steel Trading Desk", subtitle "Native Volatility Analysis Tool". No "Pro/Premium/Coach/Unlock" surfaces anywhere. Disclaimer wired. Privacy policy refreshed (`docs/PRIVACY.md`). Privacy Manifest present. App Tracking Transparency not requested.
- **Live tape pulled for v1.0.** The third-party provider path (Finnhub default, Polygon/Yahoo alternatives) was broken — Finnhub paywalled `/stock/candle` mid-2024 — and was pulled from the Settings UI in the 2026-05-16 session. Both Settings → Data Source and Broker cards now render placeholder copy ("MANUAL ENTRY — FALLBACK" / "LIVE FEED — RESTORING" / "SCHWAB — INTEGRATION PENDING") in the same design. `LiveTapeService` no longer auto-starts.
- **Future provider = Schwab Trader API.** See `docs/SCHWAB_API_READINESS.md` for the full restoration plan. v1.0 ships manual-first with placeholder framing; Schwab integration is v1.1, gated on `developer.schwab.com` account recovery.
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

The release is no-paywall. Full VXX/VIX/VWAP discipline workflow, embedded chart, prompt support, hard-exit takeover, and manual tape entry available without in-app purchase. StoreKit / paywall code is not in the release path.

| Area | Release Posture |
| :--- | :--- |
| Manual entry | Full tape entry for VXX, VIX, volume, VWAP, key level, pattern, window, news |
| Desk sequence | Full four-gate sequence with divergence-aware ratio gate |
| Embedded chart | TradingView widget on Mac/iPad, native Swift Charts on iPhone, 15-min delayed disclosure |
| Live data | None in v1.0 — placeholder card explains restoration in progress. Schwab Trader API integration lands in v1.1. |
| Prompt Desk | Available without purchase prompts |
| Risk tools | Available without purchase prompts |
| Brokerage | Manual execution only — desk fires the read, user fires the order on their broker |

Monetization is the separate **Steel SPY Desk** paid app planned alongside this free VXX app — never a feature gate on this build. See `STRATEGY_NOTES.md` "Paid product" section.

---

## 4. Critical risks

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| Financial-regulation framing | High | Public copy emphasizes "manual entry", "discipline", "educational utility". App never claims directional recommendations or win rates. |
| `.env` accidentally archived with a real API key | High | Pre-archive sanitize step (§7); `EnvSeeder` is `#if DEBUG`-gated as defense-in-depth. |
| Scope creep | Medium | Hard rule: every feature must serve the one strategy (VXX/VIX divergence fade). |
| Schwab dev-portal account recovery (v1.1 long-pole) | Medium | Not blocking v1.0. See `docs/SCHWAB_API_READINESS.md`. |
| Two-app shipping plan (free VXX + paid SPY) | Medium | Not a v1.0 risk. Re-check App Review guidelines around paid trading-adjacent apps before SPY submission, especially around anything that could read as a signals subscription. |

---

## 5. Final playtest checklist

Verify on real device (`ZZZ`) and a fresh simulator before "Submit":

- [ ] **Disclaimer.** First-run `DisclaimerView` appears before any trading workflow.
- [ ] **Tape logic.** Enter `volume 350%`, `VXX/VIX ratio 1.62`, VWAP/key-level confirmation, and a rejection pattern. Gate sequence clears in order; the NEXT MOVE verb cycles `WAIT` → `WAIT LEVEL` → `WAIT PATTERN` → `CLEARED`.
- [ ] **Divergence gate.** Manual entry showing VIX outpacing VXX (negative divergence at a stretched ratio) fails gate 2 with explicit copy ("Ratio is compressing — do not fade").
- [ ] **Hard-exit takeover.** Between 15:50 and 16:10 ET, the iPhone screen is fully replaced by the red countdown takeover. (For testing outside that window, temporarily adjust the time check in `TradingDashboard.currentDeskState`.)
- [ ] **Settings → Data Source + Broker.** Both cards render the placeholder copy ("MANUAL ENTRY — FALLBACK" / "LIVE FEED — RESTORING" / "SCHWAB — INTEGRATION PENDING"). No broken API key field, no broken Connect button, no errors logged.
- [ ] **Embedded chart.** TradingView widget loads on Mac/iPad. iPhone shows native Swift Charts (tile + fullscreen sheet, all 7 overlays present).
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

1. iPhone Desk default — ticker strip + NEXT MOVE verb + 4-gate stack with amber blocker highlight
2. iPhone gate-detail sheet — big number + tier table + house rule
3. iPhone fullscreen chart sheet — native chart with VWAP / SMA / window stripes / volume panel / ratio tier band / pattern markers
4. iPhone hard-exit takeover — red countdown + open positions + 3 exit rules
5. iPad / Mac terminal — three-column layout with gate spine + chart center + right rail

### Reviewer note (compliance guard)

> Steel Trading Desk is a manual-entry educational utility for discretionary VXX/VIX volatility traders. It does not execute trades, manage funds, or provide regulated financial advice. All inputs are entered manually by the user; all execution happens on the user's own brokerage account, outside this app.
>
> v1.0 ships with no live-data integration and no API key configuration required. A future build will integrate the Schwab Trader API with per-user OAuth on the user's own Schwab account; until then, the Settings → Data Source and Broker cards display informational placeholder copy explaining the live feed and broker handoff are pending.
>
> The reviewer can exercise the entire app on first-launch state with no external service configuration. The embedded TradingView chart loads with public delayed data and requires no account.

---

## 7. Build & upload procedure

1. **Sanitize** `.env` at repo root before archiving — clear any keys. `EnvSeeder` is `#if DEBUG`-gated but the file IS bundled in the IPA. Defense in depth.
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
5. **Final `.env` sanitize** + `/tmp` build-artifact cleanup.
6. **Archive + validate + upload** — per §7.
7. **TestFlight external** review.
8. **App Store submission** with `docs/APP_STORE_CONNECT_COPY.md` as paste source.

Day-to-day P0 work tracked in `docs/RELEASE_PUNCH_LIST.md`.

---

**v1.1 roadmap** (post-launch, gated on Schwab developer-portal account recovery): `docs/SCHWAB_API_READINESS.md`.
