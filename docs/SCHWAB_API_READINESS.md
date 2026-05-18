# Schwab Trader API — Readiness Assessment

Last updated: 2026-05-16

## Why this doc exists

The desk's automation destination is the Schwab Trader API. User had a working developer registration ~2025 and an earlier prototype that pulled live quotes before the project retreated to manual-entry mode. This doc inventories what's in the repo today, what the real Schwab Trader API actually requires, and a concrete plan for when dev-portal access is restored.

This is a **readiness audit**, not an implementation. No code is written here. Implementation grounds in the official Schwab developer docs at the time of work — **do not** rely on the endpoint/protocol claims in this doc without re-verifying at implementation time.

---

## Current state of the code (HEAD)

`Steel_Trading_Desk/Services/SchwabService.swift` is an educational-mode stub:

- `fetchQuote(_:)` sleeps 800ms then returns hardcoded sample prices (`VXX $42.15`, `VIX $18.50`).
- `placeOrder`, `streamQuotes`, `subscribeToQuotes`, `exchangeCodeForToken` all `throw .educationalModeOnly` (or return `Empty()` publishers).
- `SchwabProviderAdapter` in `MarketDataProvider.swift` wraps `SchwabService` but every protocol method `throw .notImplemented`.

`Steel_Trading_Desk/Config/AppConfig.swift` has:
- `baseURL = "https://api.schwab.com/v1"` — **wrong base, real API is `api.schwabapi.com`**.
- `streamURL = "wss://api.schwab.com/v1/stream"` — also wrong, real streamer base is different.
- `clientId = ""` — empty, needs to come from dev portal after account recovery.
- `apiKey` getter/setter persists a single string in Keychain at `app.mdrn.steel.schwabApiKey` — wrong shape (Schwab is OAuth, not a single bearer key).

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

### REST endpoints (market data — what the desk needs)

- `GET /marketdata/v1/quotes?symbols=VXX,VIX` — current quote snapshot for one or more symbols.
- `GET /marketdata/v1/<symbol>/pricehistory?frequencyType=minute&frequency=1&period=1&periodType=day` — intraday candles (1-min bars for today).
- `GET /marketdata/v1/<symbol>/pricehistory?frequencyType=daily&frequency=1&period=30&periodType=month` — daily candles for the 20-day average-volume calculation.
- `GET /marketdata/v1/chains?symbol=VXX&...` — options chain (for SPY/VXX call/put selection).
- `GET /marketdata/v1/markets?markets=equity` — market hours.

### Streaming

- WebSocket endpoint at `wss://streamer-api.schwabapi.com/ws` (confirm).
- Login frame: ADMIN service with `command=LOGIN`, carries access token + credential payload.
- Subscribe frames: SERVICE-specific (e.g., `LEVELONE_EQUITIES`, `CHART_EQUITY`) with `command=SUBS` and a comma-separated symbol list.
- Receive frames: JSON payloads keyed by service, with field maps that need to be decoded against Schwab's documented field index.
- Heartbeats, sequence numbers, and reconnect on disconnect are required for production.

### VIX symbol on Schwab

Real Schwab Trader API uses `$VIX.X` for the VIX index (CBOE Volatility Index). Not `^VIX` (Yahoo convention), not `VIX` (which would be ambiguous). Confirm at implementation. Same for `$SPX.X` for the S&P 500 index if ever needed.

---

## Gap analysis

| Need | Have | Gap |
| --- | --- | --- |
| OAuth 2.0 flow | Nothing | Full implementation: `ASWebAuthenticationSession`, code-exchange POST, token refresh logic, Keychain storage of refresh token. |
| Client ID + redirect URI | `AppConfig.clientId = ""` | User restores dev-portal access; copies client ID; registers/confirms redirect URI matches what code uses. |
| REST quote endpoint | `fetchQuote` shape from `0115bf5` | Rewrite for correct URL + auth header + response shape. |
| Intraday candles | Nothing usable (Finnhub provider doesn't apply) | New `fetchPriceHistory` method. |
| Daily candles for vol average | Nothing usable | Same method, different params. |
| WebSocket streamer | Generic WS scaffold from `0115bf5` | Replace handshake + subscribe + frame parsing entirely against Schwab Streamer spec. |
| VIX symbol | `^VIX` literal in `LiveTapeService` | Change to `$VIX.X` (verify). |
| Provider integration | `SchwabProviderAdapter` throws `.notImplemented` | Wire the new SchwabService through the adapter so the rest of the strategy engine doesn't change. |
| Rate-limit handling | 429 handler from `0115bf5` | Keep; Schwab's actual limits documented in dev portal. |
| Multi-account / per-user OAuth | Not designed for | Decide: single-user-per-install (simpler, matches the niche) or multi-account-per-install. |

---

## The plan (when dev-portal access is restored)

Sequenced. Each step blocks the next.

1. **Recover dev-portal access.** User logs into `developer.schwab.com`. Confirms the app registration from ~2025 is still active. If not, re-register.
2. **Capture the integration parameters.** Client ID, client secret (regenerate if lost — store in `.env` or a non-tracked secrets file, never in git), registered redirect URI. Update `AppConfig.swift` constants. Add a `clientSecret` Keychain entry.
3. **Read the live Schwab docs.** Confirm: OAuth flow shape, REST base URL, market-data endpoints, streamer URL + protocol, current rate limits, VIX symbol convention. Reconcile against this doc; update this doc if anything's drifted.
4. **OAuth flow first, REST second, streamer third.** Build in that order so each lands on top of the previous. Don't try to do streaming before REST quotes are confirmed working.
5. **Wire through `SchwabProviderAdapter`.** Replace the `.notImplemented` stubs so the rest of `MarketDataRegistry` + `LiveTapeService` works without changes. Keep the protocol clean so a future provider could be swapped in.
6. **Re-enable the Live Feed UI in Settings.** Replace the "RESTORING" placeholder with the real toggle. Add an OAuth status row ("Connected as <Schwab account>").
7. **Audit pass.** Run the existing `StrategyAuditor`. Verify gates still trip on real data the same way they did on manual entry. Fix any drift.
8. **TestFlight.** Send a build to user device, run during market hours, confirm tape ticks match the user's Schwab platform display side-by-side.

---

## Open questions / blockers for the next session

These need user input before code work begins:

1. **Single-user-per-install or multi-account?** The niche audience plus the boiler-room positioning suggests single-user (the trader uses their own Schwab account). Multi-account adds complexity (per-account token storage, account picker UI) for marginal value.
2. **Refresh-token storage policy.** Keychain with biometric gate (Face ID / Touch ID), or Keychain without? Biometric is more secure but adds a launch-time friction step.
3. **What happens when the refresh token expires?** Force re-auth interactively, or show a passive "RE-AUTHENTICATE" card in Settings? The latter is gentler; the former is more boiler-room.
4. **Does the streamer subscribe to options chains too**, or only the underlying quotes? Options chain subscriptions consume more streamer quota; underlyings + on-demand chain pulls might be enough.
5. **What's the dev-portal app's current registered redirect URI?** This determines whether the iOS app uses a custom scheme (e.g. `steeldesk://oauth-callback`) or a registered universal link. Code can't be written until this is confirmed.

---

## Files referenced

- `Steel_Trading_Desk/Config/AppConfig.swift` — constants to fix.
- `Steel_Trading_Desk/Services/SchwabService.swift` — current educational-mode stub.
- `Steel_Trading_Desk/Services/MarketDataProvider.swift` — `SchwabProviderAdapter` to wire through.
- `Steel_Trading_Desk/Services/KeychainService.swift` — token storage.
- `Steel_Trading_Desk/Services/LiveTapeService.swift` — consumer of provider, currently auto-start disabled.
- `Steel_Trading_Desk/Views/SettingsView.swift` — `dataSourceCard` + `brokerCard`, both currently placeholder.
- Pre-strip historical code: `git show 0115bf5:Balls_of_Steel/Services/SchwabService.swift`.
