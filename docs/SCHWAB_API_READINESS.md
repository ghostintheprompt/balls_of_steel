# Schwab Trader API — Readiness Assessment

Last updated: 2026-09-07

## 2026-09-07 — First live Schwab connection (historic)

After being stuck since the ~2025 prototype and every session since this doc's
May 2026 audit, Steel Trading Desk successfully signed in to Schwab, exchanged
a real OAuth token, and pulled a real, parsed VXX quote over the live Trader
API today. Recorded here because it took a full year and the actual causes
were never what they looked like at first glance. Three separate, unrelated
bugs were stacked on top of each other:

1. **OAuth was routing through a website instead of staying on-device.**
   `AppConfig.Schwab.oauthCallbackURL` could resolve to the `mdrn.app`
   universal-link callback on macOS depending on whatever was cached from a
   prior Settings edit or a pasted portal callback list — even though the Mac
   build has its own local HTTPS loopback listener (`127.0.0.1:8182`) built
   specifically so sign-in never has to leave the machine. Fixed by hard-
   locking the macOS getter/setter to always return the loopback URL,
   unconditionally, regardless of anything stored or pasted. See
   `SchwabOAuthSessionCoordinator.swift` and `AppConfig.swift`'s
   `oauthCallbackURL`.

2. **Errors were being silently paraphrased instead of shown.**
   `SchwabService.tokenExchangeFailureMessage` pattern-matched Schwab's raw
   HTTP response body into one of a few canned category guesses and then
   **discarded the actual response text** before it ever reached a screen.
   Every failed sign-in across every session (this one included, at first)
   was being debugged from a guess, never Schwab's literal answer. Fixed to
   always append `Schwab said: <literal response body>` to every error
   message, for both the OAuth token exchange and the market-data quote
   parser. This is what actually broke the loop — once the real text was
   visible, both root causes below were found within minutes instead of
   months.

3. **`$VIX.X` was never a valid Schwab symbol.** This doc's own May 2026
   entry flagged the VIX symbol as an unverified guess ("Confirm at
   implementation") and it was never actually confirmed. Once real HTTP
   traffic was visible, Schwab's quote endpoint responded with
   `{"invalidSymbols":["$VIX.X"]}` — a direct, unambiguous answer. Schwab's
   Trader API wants `$VIX` (no `.X` suffix; that suffix was a legacy
   thinkorswim-desktop convention, not this REST API's). Fixed in
   `SchwabService.schwabSymbol(for:)`.

**A fourth, non-code lesson worth keeping:** partway through this session,
pasted Schwab App Key/Secret values came out corrupted with Cyrillic
lookalike characters (В/Т/С/А/Р/Х/Е substituted for visually identical Latin
letters) because they'd been copied via OCR off a screenshot of the portal
page rather than as real selectable text. The symptom looked exactly like a
bad/stale credential and briefly re-triggered the whole "invalid_client"
misdiagnosis. **Always copy Schwab App Key/Secret using the portal's own
copy-to-clipboard icon, never via screenshot or OCR.**

**Workflow added as part of this fix:** `.env` (gitignored) + `.env.example`
+ `scripts/run_local.sh`. Xcode's Run button does not read `.env`, and
`open Steel_Trading_Desk.app` does not forward shell environment variables to
the launched process (a macOS LaunchServices quirk) — `run_local.sh` builds
and then execs the binary directly from a shell that has sourced `.env`, so
`EnvSeeder` actually sees `SCHWAB_APP_KEY`/`SCHWAB_APP_SECRET` for that
session without needing to hand-edit Settings or touch the permanent Keychain
value.

**Also cleaned up as real dead code while auditing the surrounding paths**
(not part of the fix, but found in the process): `AppConfig.apiKey` (written
in 3 places, read in zero — a phantom Keychain write on every token event),
the `AppConfig.baseURL`/`.streamURL`/`.clientId` legacy aliases (waiting on a
rewrite that had already happened), and `.env.example`'s unused
`FINNHUB_API_KEY`/`POLYGON_API_KEY` lines (zero references anywhere in the
app). Also collapsed the Settings → Schwab card's always-visible manual
fallback controls (Copy OAuth URL / paste-callback / Connect — only needed
when automatic capture fails) behind a closed-by-default disclosure, and
removed a fully redundant "DATA" card whose four rows duplicated facts
already shown in the header status pill and the SCHWAB card itself.

**State as of today:** OAuth connects, tokens persist, live VXX/VIX quotes
parse correctly, and the poll loop writes real market data every ~30 seconds
during market hours. The five-condition alert gate (volume/window/ratio/
VWAP/pattern) has been verified end-to-end against real live data — watched
it correctly show "NO TRADE" with the real reason (volume below threshold,
outside an alert window) rather than firing on a setup that didn't qualify.

**Also shipped the same day, once the connection itself was solid:** a real
Schwab options-chain fetch (`SchwabService.fetchOptionsChain(_:)`, hits
`/marketdata/v1/chains`) feeding the already-audited `OptionSelector.suggest`
logic, wired to fire the instant all five gates clear — NEXT MOVE now shows
an actual contract (strike/expiration/delta/ask/count/cost), not just a
price level, sized off `StrategySpec`'s own tier table. **This one specific
piece is unverified against live Schwab traffic as of writing** — same
category of risk `$VIX.X` was. It fails loudly with Schwab's raw response
attached if the assumed chain shape is wrong, rather than silently
suggesting a bad contract; the first real "CLEARED" moment during market
hours is the actual test. See `CLAUDE.md`'s punch list for current status.

Also added since: a real Trade Journal (auto-records entry + a screenshot
of the desk at that moment, tracks win/loss/P&L on close — both were
previously dead code that nothing called), hardened live-feed alerting
(debounced disconnect/reconnect notifications, sleep prevention while Live
Tape is on), and a full visual/functional redesign of Prompt Desk (was
built against an older, mismatched visual language and only had a copyable
prompt during ~4 narrow scheduled windows/day — now always has one, built
from live data).

---

## Why this doc exists

The desk's live-data destination is Schwab Trader API market-data streaming. User had a working developer registration ~2025 and an earlier prototype that pulled live quotes before the project retreated to manual-entry mode. This doc inventories what's in the repo today, what the real Schwab Trader API actually requires, and a concrete plan for a market-data-only integration.

Non-negotiable product posture: Steel Trading Desk is not an automated trading system. It does not place orders, read balances, manage positions, or require Schwab account/trading permissions. The intended workflow is phone alert → quick human review to confirm the read is not bad → manual execution in Thinkorswim/Schwab or another brokerage platform.

Core value: a personal five-condition setup checker with accuracy-gated alerting. The app exists so the trader can multitask while it watches volume, time window, VXX/VIX ratio, VWAP/key level, and rejection pattern. A live alert is valid only when the app can prove the data is live, fresh, sourced, and complete. If market data is stale, delayed, simulated, partial, disconnected, or unverifiable, the app must label the condition and suppress the alert.

This is a **readiness audit**, not a completed implementation. Implementation grounds in the official Schwab developer docs at the time of work — **do not** rely on the endpoint/protocol claims in this doc without re-verifying at implementation time.

Portal walkthrough: `docs/SCHWAB_DEV_PORTAL_WALKTHROUGH.md`.

---

## Current state of the code (HEAD)

`Steel_Trading_Desk/Services/SchwabService.swift` is an educational-mode stub:

- `fetchQuote(_:)` sleeps 800ms then returns hardcoded sample prices (`VXX $42.15`, `VIX $18.50`).
- `placeOrder`, `streamQuotes`, `subscribeToQuotes`, `exchangeCodeForToken` all `throw .educationalModeOnly` (or return `Empty()` publishers).
- `SchwabProviderAdapter` in `MarketDataProvider.swift` wraps `SchwabService` but every protocol method `throw .notImplemented`.

`Steel_Trading_Desk/Config/AppConfig.swift` now has a Schwab section with:
- `apiBaseURL = "https://api.schwabapi.com"`.
- OAuth authorize/token URLs under `/v1/oauth`.
- Market-data and trader base paths under `/marketdata/v1` and `/trader/v1`.
- Schwab portal callback for local testing: `https://127.0.0.1:8182`. If the Schwab portal displays multiple callbacks in one comma-separated field, Steel must still send exactly one registered callback as the OAuth `redirect_uri`; the app picks the Mac loopback callback from the list on macOS.
- Internal native return URL: `steeltradingdesk://oauth/callback`. Do not register this with Schwab; the portal requires HTTPS.
- Keychain slots for Schwab app key, app secret, access token, and refresh token.

The old `apiKey` getter/setter remains as a legacy alias until the Schwab service rewrite removes the single-bearer-token shape.

After 2026-05-16 cleanup, **the Settings UI no longer exposes any of this** — both the Data Source card and Broker card show "RESTORING" / "INTEGRATION PENDING" copy. The underlying stubs are still callable from code but no view surfaces them.

---

## Historical Schwab code (commit `0115bf5`)

Pre-strip `Balls_of_Steel/Services/SchwabService.swift` was 266 lines with REST + WebSocket scaffolding. Inspected via `git show 0115bf5:Balls_of_Steel/Services/SchwabService.swift`.

**What's there:**
- `fetchQuote(_:)` GETs `<baseURL>/markets/quotes/<symbol>` and decodes JSON to a `Quote`.
- `placeOrder(order:)` POSTs to `<baseURL>/trading/orders` with JSON body.
- `streamQuotes(symbols:)` opens a `URLSessionWebSocketTask` and sends a base64-encoded `{"type":"auth","token":<apiKey>}` frame.
- `receiveMessages()` async loop that decodes per-message `Quote` and publishes on a per-symbol `PassthroughSubject`.
- `authenticatedRequest(for:)` adds `Authorization: Bearer <AppConfig.apiKey>` to every request.
- Rate-limit handling (HTTP 429) + auth-failure (HTTP 401) error cases.

**What's salvageable:**
- URLSession / WebSocketTask wiring patterns (boilerplate).
- The `PassthroughSubject<Quote, Never>` per-symbol fanout pattern.
- The receive-loop control flow.
- The error enum shape (`SchwabError.authenticationFailed`, `.rateLimitExceeded`, `.invalidURL`).

**What needs to be replaced wholesale:**
- The auth model. Static `Bearer <apiKey>` is not how Schwab Trader API works. Real auth is OAuth 2.0: redirect-based authorization grant → access token (30-min TTL) → refresh token (7-day TTL) → re-auth.
- The URL constants (`api.schwab.com/v1` is wrong base).
- The WebSocket auth handshake (Schwab Streamer has its own QOS-based admin/login frame format, not a generic `{"type":"auth"}`).
- The response decoders — Schwab quote/order JSON shapes are specific and not generic `Quote`/`OrderResponse`.

**Honest assessment:** The historical code is a *generic REST+WS scaffold*, not a verified-working Schwab integration. The user's recollection of "Schwab dev was working" likely refers to a hand-modified state that didn't fully land in git, OR to a Schwab developer-portal sandbox response, not the production trader API. Treat the historical code as 30% reusable plumbing, 70% rewrite.

---

## Schwab Trader API reality

**⚠️ Confirm against current docs at implementation time. This section reflects 2026-05-16 understanding.**

### Authentication

- OAuth 2.0 Authorization Code grant.
- Dev portal app registration produces `client_id` + `client_secret` + registered redirect URI.
- User flow: app opens `https://api.schwabapi.com/v1/oauth/authorize?client_id=...&redirect_uri=...` in `ASWebAuthenticationSession`. User logs into their Schwab account, grants consent.
- Callback to registered redirect URI delivers an `authorization_code`.
- Exchange `authorization_code` for `access_token` (30-min TTL) + `refresh_token` (7-day TTL) at `/v1/oauth/token`.
- Refresh flow: POST `refresh_token` to `/v1/oauth/token` to get a new `access_token` before TTL expires.
- All API requests carry `Authorization: Bearer <access_token>`.

### REST endpoints (market data — bootstrap/fallback only)

- `GET /marketdata/v1/quotes?symbols=VXX,VIX` — current quote snapshot for one or more symbols.
- `GET /marketdata/v1/<symbol>/pricehistory?frequencyType=minute&frequency=1&period=1&periodType=day` — intraday candles (1-min bars for today).
- `GET /marketdata/v1/<symbol>/pricehistory?frequencyType=daily&frequency=1&period=30&periodType=month` — daily candles for the 20-day average-volume calculation.
- `GET /marketdata/v1/chains?symbol=VXX&...` — options chain (for SPY/VXX call/put selection).
- `GET /marketdata/v1/markets?markets=equity` — market hours.

REST is not the primary alert feed. It is useful for OAuth validation, initial snapshots, historical candles, and recovery. The live alert path must be streaming-first.

### Streaming

- WebSocket endpoint should come from the authenticated `streamerInfo` payload returned by Schwab, not a hardcoded URL. Confirm the exact field names in the logged-in docs.
- Login frame: ADMIN service with `command=LOGIN`, carries access token + credential payload.
- Subscribe frames: SERVICE-specific (e.g., `LEVELONE_EQUITIES`, `CHART_EQUITY`) with `command=SUBS` and a comma-separated symbol list.
- Receive frames: JSON payloads keyed by service, with field maps that need to be decoded against Schwab's documented field index.
- Heartbeats, sequence numbers, source timestamps, stale-tick detection, and reconnect on disconnect are required for production.
- Alerts must fail closed when the streamer disconnects, heartbeats stop, sequence/timestamp validation fails, or either required symbol is missing.

### VIX symbol on Schwab

Real Schwab Trader API uses `$VIX.X` for the VIX index (CBOE Volatility Index). Not `^VIX` (Yahoo convention), not `VIX` (which would be ambiguous). Confirm at implementation. Same for `$SPX.X` for the S&P 500 index if ever needed.

---

## Gap analysis

| Need | Have | Gap |
| --- | --- | --- |
| OAuth 2.0 flow | Nothing | Full implementation: `ASWebAuthenticationSession`, code-exchange POST, token refresh logic, Keychain storage of refresh token. |
| Client ID + redirect URI | App key/app secret Keychain slots + HTTPS loopback callback | User creates the Schwab portal app, copies credentials, and registers `https://127.0.0.1:8182` for local testing. If the portal also lists a web callback, Steel normalizes the list and sends one active redirect URI. |
| REST quote endpoint | `fetchQuote` shape from `0115bf5` | Rewrite for correct URL + auth header + response shape. Use for bootstrap/fallback, not primary alerts. |
| Intraday candles | Nothing usable (Finnhub provider doesn't apply) | New `fetchPriceHistory` method. |
| Daily candles for vol average | Nothing usable | Same method, different params. |
| WebSocket streamer | Generic WS scaffold from `0115bf5` | Replace handshake + subscribe + frame parsing entirely against Schwab Streamer spec. This is the primary alert feed. |
| Alert integrity | Nothing | Add feed source, feed timestamp, local receipt timestamp, freshness threshold, complete-symbol checks, delayed/simulated flags where available, and fail-closed suppression. |
| VIX symbol | `^VIX` literal in `LiveTapeService` | Change to `$VIX.X` (verify). |
| Provider integration | `SchwabProviderAdapter` throws `.notImplemented` | Wire the new SchwabService through the adapter so the rest of the strategy engine doesn't change. |
| Rate-limit handling | 429 handler from `0115bf5` | Keep; Schwab's actual limits documented in dev portal. |
| Multi-account / per-user OAuth | Not designed for | Decide: single-user-per-install (simpler, matches the niche) or multi-account-per-install. |

---

## The plan

Sequenced. Each step blocks the next.

1. **Create the Schwab portal app.** Use `docs/SCHWAB_DEV_PORTAL_WALKTHROUGH.md`: Market Data Production, order limit `0` if accepted, market-data-only description, and HTTPS callback `https://127.0.0.1:8182`. If a phone universal-link callback is also present in the portal, Steel must send only the active platform callback during OAuth.
2. **Capture the integration parameters.** Client ID / app key, client secret, registered callback URLs. For local Debug tests, Xcode scheme environment variables can seed Keychain. For normal app use, enter credentials in Settings -> Schwab Developer Access. Never commit credentials or ship a shared secret.
3. **Read the live Schwab docs.** Confirm: OAuth flow shape, REST base URL, market-data endpoints, streamer URL + protocol, current rate limits, VIX symbol convention. Reconcile against this doc; update this doc if anything's drifted.
4. **OAuth flow first, REST sanity check second, streamer third.** REST proves tokens and symbols; streaming is the product path.
5. **Wire through `SchwabProviderAdapter`.** Replace the `.notImplemented` stubs so the rest of `MarketDataRegistry` + `LiveTapeService` works without changes. Keep the protocol clean so a future provider could be swapped in.
6. **Re-enable the Live Feed UI in Settings.** Replace the "RESTORING" placeholder with the real toggle. Add OAuth status and feed-integrity rows.
7. **Audit pass.** Run the existing `StrategyAuditor`. Verify gates still trip on real data the same way they did on manual entry. Fix any drift.
8. **TestFlight.** Send a build to user device, run during market hours, confirm tape ticks match Thinkorswim/Schwab side-by-side. Force airplane-mode/disconnect/stale-feed cases and verify alerts are suppressed.

---

## Open questions / blockers for the next session

These need user input before code work begins:

1. **Single-user-per-install or multi-account?** The niche audience plus the boiler-room positioning suggests single-user (the trader uses their own Schwab account). Multi-account adds complexity (per-account token storage, account picker UI) for marginal value.
2. **Refresh-token storage policy.** Keychain with biometric gate (Face ID / Touch ID), or Keychain without? Biometric is more secure but adds a launch-time friction step.
3. **What happens when the refresh token expires?** Force re-auth interactively, or show a passive "RE-AUTHENTICATE" card in Settings? The latter is gentler; the former is more boiler-room.
4. **Does the streamer subscribe to options chains too**, or only the underlying quotes? Options chain subscriptions consume more streamer quota; underlyings + on-demand chain pulls might be enough.
5. **What is the App Store-grade iPhone callback?** Schwab requires HTTPS. Local Mac testing should use `https://127.0.0.1:8182`; the app starts a loopback HTTPS listener for that callback and exchanges the code after Schwab redirects. `https://127.0.0.1` with no port maps to privileged port 443 and cannot be auto-captured by a normal macOS app. Native iPhone OAuth still needs a controlled HTTPS app link such as `https://mdrn.app/steel/oauth/callback`, with both the Schwab Developer Portal callback and Apple's Associated Domains/AASA file matching that exact host/path. If the portal displays both callbacks in one field, the OAuth request still uses only one member of that list.

---

## Files referenced

- `Steel_Trading_Desk/Config/AppConfig.swift` — constants to fix.
- `Steel_Trading_Desk/Services/SchwabService.swift` — current educational-mode stub.
- `Steel_Trading_Desk/Services/MarketDataProvider.swift` — `SchwabProviderAdapter` to wire through.
- `Steel_Trading_Desk/Services/KeychainService.swift` — token storage.
- `Steel_Trading_Desk/Services/LiveTapeService.swift` — consumer of provider, currently auto-start disabled.
- `Steel_Trading_Desk/Views/SettingsView.swift` — `dataSourceCard` + `brokerCard`, both currently placeholder.
- Pre-strip historical code: `git show 0115bf5:Balls_of_Steel/Services/SchwabService.swift`.
