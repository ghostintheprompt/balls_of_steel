# Schwab Dev Portal Walkthrough

Last updated: 2026-05-25

This is the repeatable setup path for Steel Trading Desk users who have their own Schwab developer account and want to follow the same market-data-only workflow.

Product rule: Steel is not an automated trading system. The Schwab app is for live market data so the desk can validate a five-condition entry setup and issue local alerts. The user manually places any trade in Thinkorswim, Schwab, or another brokerage platform.

## Product Position

Schwab Developer Access is a selling point, not a workaround. Steel is for a narrow audience: traders with their own Schwab developer account who care enough about feed provenance to bring their own market-data credentials. Setup is intentionally small: enter two values, the Schwab app key and app secret, and the app stores them in Keychain.

The trade workflow remains human:

1. Thinkorswim/Schwab chart templates run on the trading screen.
2. Steel runs the same VXX/VIX/VWAP setup read on phone, iPad, or Mac.
3. Steel alerts only when the data is suitable and every condition clears.
4. The user checks the read and manually enters the trade in Thinkorswim/Schwab.

The only live-data question that matters after OAuth works: is Schwab's data suitable for this system? If not, the app must stay in manual-entry mode or suppress the alert.

## Portal Form Values

Use these values on Schwab Developer Portal -> Dashboard -> Apps -> Create App.

| Field | Value |
| --- | --- |
| Environment | `Production` |
| API Product | `Market Data Production` |
| Order Limit | `0` first. If Schwab rejects `0`, use the lowest accepted value and document it in the app notes. Do not choose a high throttle. |
| App Name | `Steel Trading Desk` |
| App Description | `Personal market-data-only setup checker for discretionary VXX/VIX/VWAP trading. It validates volume, time window, ratio, VWAP/key level, and pattern, then issues local alerts. No orders, balances, account management, or automated trading.` |
| Callback URL | Mac local test: `https://127.0.0.1:8182`. If the portal also lists the phone callback, Steel still sends only one active redirect URI during OAuth. |

Do not add `Accounts and Trading Production` unless the live Schwab docs or a `403` response proves the streamer bootstrap endpoint requires it. If that happens, the code must still block order placement, order preview, balances, positions, and transaction history. The only acceptable reason to touch `/trader/v1` is to retrieve Schwab's authenticated streamer metadata, such as `userPreference`, when Schwab requires it for streaming login.

## Company Registration

Use company registration only if the Schwab app should be owned by the real business entity behind Steel Trading Desk. Do not register a company profile with informal, incomplete, or aspirational business details. Schwab, Apple, tax records, and the public website should tell the same story.

For a company-owned app:

- Company Name: use the exact legal company name.
- Address / City / State / Zip: use the company's real business address.
- Website: use the public company or product website.
- D-U-N-S Number: optional. Leave blank unless the company has one and the value is known.

Use-case checkboxes:

- If the company already has commercially available apps with active users, select: `Develops our own applications which are currently commercially available with active users`.
- If Steel is not commercially available yet and there are no other active commercial apps under the company, select: `Does not yet have commercially available products`.
- Do not select `Connect third party applications to our data services` unless the company is exposing Schwab-backed data to other apps or customers. Steel's current design is device-to-Schwab for the user's own market-data read.
- Do not select `Develops applications that power other company's products` unless that is literally true.
- Use `Other` only if Schwab's options do not fit; describe the market-data-only, user-supplied Schwab developer credential model.

OAuth capability:

- `Does your Company have the ability to support refresh token rotation?` -> `Yes`, once the app implements refresh-token replacement and Keychain overwrite. If this is being submitted before implementation, do not claim support until it exists.
- `Our APIs require 3-legged OAUTH, please confirm your company can support this.` -> check `Yes` only if the app will use user authorization through Schwab's OAuth flow. Steel's intended Schwab model is 3-legged OAuth: user logs into Schwab, grants access, app receives tokens, app uses market data only.

If this is only for personal testing and the portal still allows the Individual Developer app path, use the individual app path first. If Schwab requires a company profile for Production approval or App Store distribution, register the real company profile and keep the use case narrow and honest.

## Callback URL Rules

Schwab requires an HTTPS callback URL. Do not enter `steeltradingdesk://oauth/callback` in the Schwab portal; that is an internal app return URL only, and Schwab rejects non-HTTPS callbacks.

For the first approval and tomorrow's OAuth/token test, use:

```text
https://127.0.0.1:8182
```

Use that exact value:

- `https`, not `http`.
- `127.0.0.1`, not `localhost`.
- Include port `8182`.
- No path.
- No trailing slash.

If the Schwab portal shows both callbacks in one field, for example:

```text
https://127.0.0.1:8182,https://oauth.mdrn.app/schwab/callback
```

that is a portal registration list, not the OAuth `redirect_uri` value. Steel Settings can accept the pasted list, but macOS will pick `https://127.0.0.1:8182` for the auth URL. The phone path should pick the controlled HTTPS app-link callback when that flow is wired and tested.

If Schwab still rejects `https://127.0.0.1:8182`, stop before creating the app with a throwaway callback. Public Schwab wrapper docs report intermittent Schwab portal bugs around callback validation. The next clean options are:

1. Retry the exact value in a fresh browser session.
2. Contact `traderapi@schwab.com` with the callback-validation error.
3. Use a real HTTPS domain you control, then wire it as an App Store-grade universal-link callback. Do not use a random hosted callback page for brokerage OAuth.

## After Create

The app may show a review or pending state. Once Schwab exposes credentials:

1. Copy the app key / client ID.
2. Copy the app secret.
3. Do not paste either value into git, screenshots, support tickets, or public docs.
4. For local Debug testing only, add Xcode scheme environment variables:

```sh
SCHWAB_APP_KEY=your_app_key_here
SCHWAB_APP_SECRET=your_app_secret_here
SCHWAB_CALLBACK_URL=https://127.0.0.1:8182
```

`EnvSeeder` can seed those into the platform Keychain in Debug builds. If `SCHWAB_CALLBACK_URL` is pasted from the portal as a comma-separated list, Steel normalizes it to the active redirect for the current platform. Release/TestFlight builds skip `EnvSeeder` and must not ship app credentials.

## How The Phone Gets Credentials

There is no Claude credential in the app. The only Schwab values are:

- Schwab app key / client ID.
- Schwab app secret.
- OAuth access token returned by Schwab.
- OAuth refresh token returned by Schwab.

For tomorrow's local test, prefer the macOS build first. Either put the Schwab app key/secret in the Xcode scheme's **Run -> Arguments -> Environment Variables** panel, or enter them in Settings -> Schwab Developer Access. Both paths store values in Keychain.

For iPhone/iPad/TestFlight/App Store, use Settings -> Schwab Developer Access. The app ships with no Schwab app secret; each Schwab developer user enters their own credentials locally. This is the right model for the current niche version.

`.env` is intentionally not copied into the Xcode resource phase. Do not add it back. Bundled app files can be extracted.

## Security Model

Blunt rule: a native-app client secret is not truly secret once it is distributed. Anyone with enough skill and device access can inspect an app bundle or reverse-engineer a client binary. Keychain protects values at rest on the device, but it cannot make a distributed app secret impossible to extract if the secret is baked into the app.

What the app can protect well:

- Store Schwab credentials and OAuth tokens in Keychain, not UserDefaults.
- Use `ThisDeviceOnly` Keychain storage so tokens do not sync to other devices.
- Never commit credentials to git.
- Never copy `.env` into the app bundle.
- Never ship shared Schwab credentials in TestFlight/App Store.
- Let each Schwab developer user enter their own app key and app secret locally.
- Request only market data.
- Never call Schwab order, balance, position, transaction, or order-preview endpoints.
- Suppress alerts when the feed is stale, delayed, simulated, partial, disconnected, or unverifiable.

What the app cannot honestly promise:

- It cannot make a Schwab app secret public-proof if that secret is bundled into a distributed app.
- It cannot protect against a fully compromised phone.
- It cannot make bad market data good. The correct behavior for uncertain data is no alert.

## 2026 Fintech Security Talking Points

This is the interview-grade explanation:

- Native apps are public OAuth clients. They cannot keep a shipped client secret secret. RFC 8252 says native apps that receive a client secret still have to be treated as public clients.
- OAuth Security Best Current Practice is Authorization Code + PKCE, external browser/system auth session, exact redirect validation, short-lived access tokens, and refresh-token rotation where the provider supports it.
- If Schwab requires a client secret, the safe models are either user-brings-own Schwab developer credentials stored locally in Keychain, or a backend-for-frontend where the server holds the shared secret. Do not hide a shared secret in the app bundle.
- Keychain protects stored credentials/tokens at rest. It does not protect secrets that were compiled into the app.
- Use least privilege: Market Data Production only. No order, balance, position, transaction, or preview-order scope.
- App security and data integrity are separate controls. Even with perfect OAuth storage, the alert must still fail closed on stale, delayed, simulated, partial, disconnected, or unverifiable market data.

## Tomorrow's Test Goal

The first live-data test is not "make an alert and trust it." The first test is proving the feed can be trusted.

Pass criteria:

- OAuth succeeds and tokens are stored in Keychain.
- VXX and Schwab's VIX symbol both resolve from Schwab.
- REST quote snapshots match Thinkorswim/Schwab closely enough to confirm symbol mapping.
- Streamer login succeeds.
- VXX and VIX ticks arrive with source timestamps.
- Heartbeats continue during the session.
- The app marks feed source, feed timestamp, local receipt time, and freshness.
- Phone/iPad/Mac reads match the Thinkorswim chart-template read closely enough to support synchronized alerts.
- Alerts remain suppressed until both required symbols are present and fresh.
- Disconnect, stale timestamp, missing symbol, delayed data, or parsing failure produces `NO TRADE` / blocked alert state.

Fail criteria:

- Missing VIX symbol mapping.
- Quote snapshots work but streamer does not.
- Streamer works for VXX but not VIX.
- No source timestamp.
- No heartbeat/sequence validation.
- Any code path emits a live alert from stale, simulated, delayed, partial, or unverifiable data.

## Known Strengths

- Direct Schwab path avoids a third-party market-data middleman.
- One provider means fewer cross-feed disagreements.
- User already trades in the Schwab/Thinkorswim ecosystem, so the app can be checked against the same broker stack used for execution.
- OAuth keeps credentials in the user's own Schwab account instead of a shared app-owned data account.

## Known Weaknesses

- Schwab's official docs are portal-gated; public references are not enough for final implementation.
- Some open-source clients retrieve streamer metadata through `/trader/v1/userPreference`, which may require entitlement beyond pure market data. Verify this in the logged-in docs and with real responses.
- Schwab symbols can differ from Yahoo/TradingView conventions. VIX must be verified against Schwab, not guessed.
- OAuth refresh-token expiration can interrupt unattended testing. The app must show re-auth status plainly and suppress alerts while disconnected.
- Client secrets in a distributed native app are not secret. The App Store-safe model is: every user brings their own Schwab developer app key/secret, stored locally in Keychain.
- iPhone-native OAuth needs an HTTPS callback strategy. The local `127.0.0.1` callback is the fastest Mac/local test path, but App Store-grade iPhone OAuth should use an HTTPS universal link on a domain controlled by the app owner, or a deliberately implemented local HTTPS listener that survives the auth handoff.

## Implementation Guardrails

- Market data only.
- No order placement.
- No order preview.
- No balance reads.
- No position reads.
- No transaction reads.
- No account picker unless Schwab forces an account-scoped streamer token, and even then do not display balances or positions.
- No alert unless the app can prove live, fresh, sourced, complete data for all required symbols.
- If the app is unsure, it must say so and stay quiet.

## References To Verify

- Schwab Developer Portal: `https://developer.schwab.com/` (authoritative, login required).
- Schwab OAuth host observed on 2026-05-25: `https://api.schwabapi.com/v1/oauth/authorize` and `https://api.schwabapi.com/v1/oauth/token`.
- Open-source cross-checks only, not authority:
  - RFC 8252, OAuth 2.0 for Native Apps: `https://www.rfc-editor.org/rfc/rfc8252`
  - RFC 9700, OAuth 2.0 Security Best Current Practice: `https://www.rfc-editor.org/rfc/rfc9700.html`
  - OWASP MASVS / MASTG mobile security guidance: `https://mas.owasp.org/`
  - `schwab-py` OAuth callback guidance: `https://schwab-py.readthedocs.io/en/latest/auth.html`
  - `schwabdev` client base URL and endpoint shapes: `https://github.com/tylerebowers/Schwab-API-Python`
