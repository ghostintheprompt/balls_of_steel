# Steel Trading Desk: Launch Strategy

**Status:** The original "Mobile-First / Compliance / Hardening" launch phases are largely complete after the May 2026 boiler-room redesign. This file is now the *historical* launch plan plus the live status of submission. Active P0 work lives in `docs/RELEASE_PUNCH_LIST.md`.

---

## Where we are now

- **Compliance & branding:** App is named "Steel Trading Desk" across all metadata. Subtitle "Native Volatility Analysis Tool" (good Review cover). No "Pro/Premium/Coach/Unlock" surfaces. Disclaimer wired. Privacy policy refreshed (`docs/PRIVACY.md`).
- **Technical hardening:** iOS + iPadOS + macOS targets all building. Privacy Manifest present. Keychain in use for API keys. Push notifications wired (`STEEL_DESK` notification category with "Open Desk" action).
- **iOS-first deployment:** Boiler-room redesign passes shipped (9 phases per `docs/CLAUDE_CODE_DIRECTIONS.md`). Signed Release installs cleanly on the paired iPhone (`ZZZ`). Live data wired (Finnhub default, Polygon/Schwab/Yahoo as alternatives).
- **macOS:** Three-column terminal layout shipped. macOS Debug build verified green.

---

## Free-Full-Desk posture

The release ships paywall-free. The full VXX/VIX/VWAP discipline workflow, embedded TradingView chart, prompt support, hard-exit takeover, and live-data integration are available without an in-app purchase. StoreKit / paywall code has been removed from the release path.

| Area | Release Posture |
| :--- | :--- |
| **Manual entry** | Full tape entry for VXX, VIX, volume, VWAP, key level, pattern, window, news |
| **Desk sequence** | Full four-gate sequence with divergence-aware ratio gate |
| **Embedded chart** | TradingView widget, free, 15-min delayed disclosure |
| **Live data** | Optional, bring-your-own API key, Keychain-stored, never proxied |
| **Prompt Desk** | Available without purchase prompts |
| **Risk tools** | Available without purchase prompts |
| **Brokerage** | Manual execution only — no broker integration in v1.0 |

If monetization ever returns, it is patronage / supporter tier or a separate serious product line — *not* a feature gate on this app. Internal direction lives in `STRATEGY_NOTES.md`.

---

## Critical risks remaining

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| **Financial regulation framing** | High | Public copy emphasizes "manual entry", "discipline", "educational utility". App never claims directional recommendations. |
| **`.env` accidentally archived with a real API key** | High | Pre-archive sanitize step in `docs/BUILD.md`; `EnvSeeder` is `#if DEBUG`-gated as defense-in-depth. |
| **iPhone chart squash** | Medium | Documented; see `STRATEGY_NOTES.md`. Three fix paths captured for v1.1. |
| **VIX symbol on Finnhub** | Low | `^VIX` may need adjusting once user validates against the real API. One-line edit in `LiveTapeService`. |
| **Scope creep** | Medium | Hard rule: every feature must serve the one strategy (VXX/VIX divergence fade). Don't add unrelated strategies. |

---

## Submission roadmap

1. **Real-key validation** — confirm Finnhub end-to-end, fix VIX symbol if needed.
2. **iPhone chart fit** — pick one of the three approaches in `STRATEGY_NOTES.md`.
3. **Test target** — XCTest covering time windows, `DeskState` boundaries, ratio thresholds, divergence-gate behavior.
4. **Plex license file** in app bundle (SIL Open Font License compliance).
5. **App Store assets** — screenshots in the order specified in `docs/LAUNCH_GUIDE.md`.
6. **Final sanitize** of `.env` and `/tmp` build artifacts.
7. **Archive + validate + upload** — see `docs/BUILD.md`.
8. **TestFlight** external review.
9. **App Store** submission with the canonical paste sheet (`docs/APP_STORE_CONNECT_COPY.md`).

The day-to-day P0 list lives in `docs/RELEASE_PUNCH_LIST.md`.
