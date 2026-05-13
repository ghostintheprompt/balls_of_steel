# Steel Trading Desk: App Store Launch Strategy (Internal)

**Objective:** Transition the "Steel Trading Desk" from a local-first utility to a publicly available **iOS application first**, followed by a macOS release on the Mac App Store. This "Mobile-First" strategy aims to capture the signal-on-the-go market and navigate Apple's review process with a more focused mobile interface.

---

## Phase 1: Compliance & Branding (The "Review Guard")
*Apple's review process is the primary bottleneck. We must minimize friction in branding and financial regulations.*

### 1.1 Branding Pivot
*   **Internal Name:** `Steel Trading Desk`
*   **App Store Display Name:** `Steel Trading Desk`
*   **Reasoning:** Professional, aggressive, and avoids "Objectionable Content" triggers.
*   **Action:** Ensure the name is consistent across all metadata.

---

## Phase 2: Technical Hardening (Mobile Priority)
*Ensuring the app meets Apple's performance and stability standards for iOS.*

### 2.1 iOS Target & Adaptive UI
*   **Task:** Add iOS target to the Xcode project.
*   **Requirements:**
    *   `com.apple.security.network.client`: Enabled.
    *   `com.apple.security.personal-information.keychain`: Enabled.
    *   Adaptive SwiftUI layouts that look "Elite" on iPhone (Compact) and iPad (Regular).

### 2.2 APNs & Signal Alerts
*   **Task:** Implement Push Notifications for ENTRY/WATCH/EXIT signals.
*   **Requirement:** Traders need to know when the institutional window is live without checking the app.

---

## Phase 3: Deployment Roadmap (iOS First)

### Step 1: iOS TestFlight (Week 1)
*   **Goal:** Surface immediate rejection reasons for the mobile interface.
*   **Action:** Submit the iOS build to TestFlight for External Review.

### Step 2: macOS Port & Approval (Week 2-3)
*   **Action:** Once iOS is in review/approved, finalize the macOS target using the same shared logic.
*   **Benefit:** macOS reviewers often see an approved iOS app as a sign of legitimacy.

---

---

## Phase 4: Free Full Desk
*This is a field tool and a gift to traders, not a fish funnel.*

### 4.1 Release Structure
The VXX/VIX/VWAP desk ships free. No Lite/Pro split, no locked prompts, no fake premium wall. The value is proving the workflow is real enough that serious people want to support the broader MDRN work later.

| Area | Release Posture |
| :--- | :--- |
| **Manual Entry** | Full tape entry for VXX, VIX, volume, VWAP, key level, pattern, and window |
| **Desk Sequence** | Full gate sequence: volume/window, ratio, VWAP/key level, pattern, decision |
| **Prompt Desk** | Available without purchase prompts |
| **Risk Tools** | Available without purchase prompts |
| **Brokerage** | Manual execution only for launch |

### 4.2 Long-Term Support
If monetization returns, it should be patronage, enterprise support, or serious investor/supporter interest earned by the product's usefulness. No subscription bait and no locked trading workflow.

### 4.3 Internal Product Ladder
VXX is the free desk: the gift, proof of craft, and cleanest way to show the MDRN trading style without charging people for another fake system.

The future paid product, if we build one, is the SPY version. That should be treated as a separate serious product line with deeper workflow, stronger tooling, and enough value to justify payment. Do not leak this into App Store copy for the free VXX release.

---

## Critical Risks to Monitor
| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| **Financial Regulation** | High | Emphasize "Manual Entry" and "Journaling" over "Trading". |
| **Branding Rejection** | Medium | Use a sanitized "Display Name" in the App Store. |
| **Scope Creep** | Medium | Keep the phone flow lean: Desk, Tape, Risk. Add live charts/arrows only when they directly improve entries. |

---

**Next Directive Recommendation:**
To begin, we should audit the `Info.plist` and `.entitlements` to ensure they are production-ready for the App Store Sandbox.
