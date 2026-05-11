# Steel Trading Desk Release Punch List

Last updated: May 11, 2026

## Product Position

Steel Trading Desk should be positioned as a local-first, manual trading discipline utility for SPY and VXX options traders. The app helps a trader enter market context manually, check setup quality against time windows, volume, VWAP, volatility, and risk rules, copy structured analysis prompts, journal decisions, and receive user-enabled alerts.

It should not be positioned as financial advice, automated trading, managed execution, guaranteed signals, or a brokerage replacement.

## Current Release Posture

The current app is not App Store ready, but it is now organized enough to move into a focused release pass. Generic iOS and macOS Debug builds pass with code signing disabled. There is still no watchOS target, no dedicated test target, and no completed App Store submission package.

Practical estimate: closer to 60-70% release-ready than 75%, mostly because build hygiene is now in better shape but phone UX, compliance language, screenshots, signing, and device testing still need concentrated work.

## P0: Release Blockers

1. iPhone-first UX pass
   - Treat iPhone as the primary product surface.
   - Test compact layouts on real or simulated iPhone sizes.
   - Reduce dense dashboard sections where they become cramped.
   - Confirm tab count, navigation titles, sheets, onboarding, disclaimers, paywall, and settings fit without clipping.
   - Verify Dynamic Type, small screens, landscape, and dark mode.

2. App Review compliance copy scrub
   - Remove or soften public-facing "90% win rate", "highest probability", "supreme power", "ready to execute", and similar claims.
   - Keep "manual execution", "educational utility", "risk discipline", "setup checklist", and "local-first" language.
   - Replace aggressive marketing lines that could imply advice, guaranteed performance, or automated trading.
   - Make reviewer notes consistent with actual app behavior.

3. Financial risk and disclaimer review
   - Confirm the first-run disclaimer appears before any trading workflow.
   - Confirm "not financial advice" and "manual execution only" appear in customer-facing context without overwhelming the app.
   - Avoid presenting historical strategy rates as expected future results.
   - Consider legal review before external TestFlight.

4. StoreKit and monetization verification
   - Confirm `app.mdrn.steel.pro_unlock` exists in App Store Connect.
   - Test purchase, restore, locked/unlocked states, offline behavior, and failed purchase states.
   - Make paywall language concrete and App Review safe.

5. Privacy and permissions
   - Confirm privacy policy contact email is real.
   - Confirm privacy manifest matches actual APIs.
   - Confirm notification permission copy says alerts are user-enabled.
   - Re-check background behavior before claiming background monitoring on iOS.

6. Test coverage
   - Add a test target.
   - Cover time-window logic, VXX/VIX ratio thresholds, signal/watch generation, close-management timing, prompt placeholder replacement, UserDefaults persistence, Keychain storage, and daily risk locking.
   - Add at least one UI smoke test for onboarding -> manual entry -> dashboard -> settings.

7. App Store assets
   - Produce iPhone screenshots for required sizes.
   - Produce iPad screenshots.
   - Produce macOS screenshots.
   - Verify icon appearance at small sizes.
   - Prepare support URL, marketing URL, privacy URL, subtitle, keywords, and reviewer demo notes.

8. Signing and archive
   - Set team, signing, capabilities, version, and build number.
   - Run archive for iOS and macOS.
   - Upload to TestFlight.
   - Fix any App Store Connect processing warnings.

## P1: Hardening

1. Run on real devices
   - iPhone physical device.
   - iPad physical device or simulator.
   - Apple silicon Mac.
   - Intel Mac only if still required.

2. Build warnings and static checks
   - Keep Debug builds warning-free where practical.
   - Run Xcode Analyze.
   - Review entitlements and Info.plist for platform-specific keys.

3. Brand color audit
   - Current core palette is obsidian, electric cyan, neon green, red, yellow, and metallic gray.
   - No brown/beige theme is present in the design system.
   - There are still many `.orange` warning accents and setup-doc references to the 50 SMA as orange. Audit whether orange should remain as a market convention or be replaced with the brand warning yellow/cyan system.

4. Phone information architecture
   - Decide whether Desk, Manual, VXX, SPY, Live, and Settings all belong in the primary tab bar on iPhone.
   - Consider a shorter phone tab model: Desk, Manual, Coach, Risk, Settings.
   - Keep iPad/macOS denser if useful.

5. Data lifecycle
   - Document what is stored locally.
   - Add clear reset/delete-local-data controls if needed.
   - Confirm uninstall behavior and privacy policy match.

## P2: Post-Launch / Future

1. watchOS punch list
   - Do not add watchOS until iPhone is stable.
   - Define it as a companion, not a full trading app.
   - Best watch features: trading-window reminders, risk timer, alert glance, manual "dismiss" or "mark reviewed" actions.
   - Avoid order entry or brokerage actions on watch.

2. iPad optimization
   - Use wider layouts for side-by-side manual data and validation.
   - Keep touch targets generous.
   - Consider split-view navigation.

3. macOS release polish
   - Confirm menu commands.
   - Confirm update-checker behavior is appropriate for Mac App Store distribution.
   - Consider whether GitHub release update checks should be disabled for App Store builds.

4. Documentation refresh
   - Consolidate duplicate launch docs.
   - Split internal strategy notes from public App Store copy.
   - Keep aggressive brand voice in internal docs, and restrained clarity in App Store metadata.
