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

## Phase 4: Monetization Strategy (Freemium Model)
*Aligning with the "Elite" philosophy: Provide high value for free, unlock supreme power for a premium.*

### 4.1 The Tiered Structure
To maximize adoption while ensuring revenue, we will use an **In-App Purchase (IAP)** to unlock "Pro" features.

| Feature | **Lite (Free)** | **Pro (Unlocked)** |
| :--- | :--- | :--- |
| **Manual Entry** | Basic Price/Volume | Full VIX/Ratio/Technical Data |
| **Prompt Coach** | Pre-Market & Morning | **Supreme Library** (Institutional Flow, Power Hour, Crisis Mode) |
| **Journaling** | Last 5 Trades | **Unlimited History** + P&L Analytics |
| **Brokerage** | Manual Only | **Schwab API Integration** |
| **Risk Tools** | Basic Close Warning | **Hard-Exit Automated Discipline** |

### 4.2 Pricing Strategy
*   **Model:** One-time In-App Purchase (Life-time "Pro" Unlock).
*   **Psychological Pricing:** 
    *   **$49.99:** "Entry Elite" - Accessible for retail traders.
    *   **$99.99:** "Institutional Pro" - Positioned as a professional tool.
*   **Why One-Time?** Subscriptions often feel like "bloatware." A one-time high-ticket price reinforces the "Steel Trading Desk" brand of conviction and local-first ownership.

### 4.3 App Store Implementation
*   **Guideline 3.1.1:** Use Apple's native IAP framework.
*   **Trial Period:** Offer a 7-day "Pro Trial" to hook users on the Institutional Flow window (3:45 PM), which has the highest reliability (90%).

---

## Critical Risks to Monitor
| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| **Financial Regulation** | High | Emphasize "Manual Entry" and "Journaling" over "Trading". |
| **Branding Rejection** | Medium | Use a sanitized "Display Name" in the App Store. |
| **IAP Complexity** | Low | Implement a single "Unlock All" non-consumable IAP. |

---

**Next Directive Recommendation:**
To begin, we should audit the `Info.plist` and `.entitlements` to ensure they are production-ready for the App Store Sandbox.
