import SwiftUI

// MARK: - First Launch Disclaimer
// Required legal disclaimer shown on first app launch

struct FirstLaunchDisclaimerView: View {
    @Binding var isPresented: Bool
    @State private var hasReadDisclaimer = false
    @State private var hasAgreedToTerms = false

    var body: some View {
        NavigationView {
            ZStack {
                TradingBackdrop()

                ScrollView {
                    VStack(spacing: 24) {
                        disclaimerHeader
                        educationalToolSection
                        riskDisclaimerSection
                        noAdviceSection
                        manualExecutionSection
                        acknowledgmentSection
                        acceptButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Important Disclaimer")
        }
        .interactiveDismissDisabled(true)
    }

    private var disclaimerHeader: some View {
        VStack(spacing: 12) {
            BallsOfSteelMark(size: 104, primaryAccent: DesignSystem.warningColor)

            BallsOfSteelWordmark(
                alignment: .center,
                title: "BALLS OF STEEL",
                subtitle: "Educational desk. Manual execution."
            )
            .multilineTextAlignment(.center)

            Text("Read this carefully before you touch the tape.")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.bearishColor)
        }
        .deskPanel(glow: DesignSystem.warningColor.opacity(0.12))
    }

    private var educationalToolSection: some View {
        DisclaimerCard(
            icon: "book.fill",
            title: "Educational Tool Only",
            color: .blue
        ) {
            Text("""
            This app is designed as an educational tool to teach the VXX trading system. \
            It does NOT provide live trading, automated execution, or real-time market data.

            You must manually enter data from your own trading platform and execute all trades yourself.
            """)
        }
    }

    private var riskDisclaimerSection: some View {
        DisclaimerCard(
            icon: "exclamationmark.shield.fill",
            title: "Trading Risk Warning",
            color: .red
        ) {
            Text("""
            **TRADING INVOLVES SUBSTANTIAL RISK OF LOSS**

            - Options trading is highly risky and not suitable for all investors
            - You can lose your entire investment
            - Past performance does NOT guarantee future results
            - Win rates and strategies shown are educational examples
            - Market conditions change - no system guarantees profits

            Only trade with money you can afford to lose.
            """)
        }
    }

    private var noAdviceSection: some View {
        DisclaimerCard(
            icon: "person.fill.xmark",
            title: "Not Financial Advice",
            color: .orange
        ) {
            Text("""
            **THIS IS NOT FINANCIAL ADVICE**

            - All content is for educational and informational purposes only
            - We do not provide investment, tax, or legal advice
            - Strategies shown are examples, not recommendations
            - Consult a licensed financial advisor before trading
            - You are solely responsible for your trading decisions

            The creator got a 74 on the Series 7. This is a learning tool, not advice.
            """)
        }
    }

    private var manualExecutionSection: some View {
        DisclaimerCard(
            icon: "hand.tap.fill",
            title: "Manual Execution Required",
            color: .green
        ) {
            Text("""
            **YOU EXECUTE ALL TRADES**

            This app does NOT:
            - Connect to broker APIs for live trading
            - Execute trades automatically
            - Provide real-time market data
            - Make trading decisions for you

            You must:
            - Enter market data manually from your platform
            - Analyze setups using the educational tools
            - Make your own trading decisions
            - Execute trades on your own platform (ThinkOrSwim, Schwab, etc.)
            """)
        }
    }

    private var acknowledgmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $hasReadDisclaimer) {
                Text("I have read and understand all disclaimers above")
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.primaryText)
            }
            .toggleStyle(CheckboxToggleStyle())

            Toggle(isOn: $hasAgreedToTerms) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I agree that:")
                        .font(DesignSystem.Typography.bodyFont)
                        .foregroundColor(DesignSystem.primaryText)
                    Text("- This is an educational tool only")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                    Text("- I trade at my own risk")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                    Text("- I will not hold the creator liable for losses")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.mutedText)
                }
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .deskPanel(glow: DesignSystem.warningColor.opacity(0.12))
    }

    private var acceptButton: some View {
        Button(action: {
            if hasReadDisclaimer && hasAgreedToTerms {
                UserDefaults.standard.set(true, forKey: "hasAcceptedDisclaimer")
                isPresented = false
            }
        }) {
            Text(hasReadDisclaimer && hasAgreedToTerms ? "Accept & Continue" : "Read All Disclaimers First")
                .font(DesignSystem.Typography.headlineFont)
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasReadDisclaimer && hasAgreedToTerms ? DesignSystem.primaryColor : DesignSystem.secondaryColor.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .disabled(!hasReadDisclaimer || !hasAgreedToTerms)
    }
}

// MARK: - Disclaimer Card Component
struct DisclaimerCard<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(DesignSystem.Typography.headlineFont)
                    .foregroundColor(color)
            }

            content
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.primaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .deskPanel(glow: color.opacity(0.12), padding: 0)
    }
}

// MARK: - Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(configuration.isOn ? DesignSystem.primaryColor : DesignSystem.mutedText)
                configuration.label
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Educational Banner
// Reusable banner for consistent disclaimers throughout the app

struct EducationalBanner: View {
    let message: String
    var icon: String = "info.circle.fill"
    var color: Color = .blue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(message)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .deskPanel(glow: color.opacity(0.1), padding: 0)
    }
}

// MARK: - Quick Disclaimers for Common Screens
extension View {
    /// Add educational disclaimer banner to any view
    func withEducationalDisclaimer(_ message: String = "Educational tool - Not financial advice") -> some View {
        VStack(spacing: 0) {
            self
            EducationalBanner(message: message, icon: "graduationcap.fill", color: .blue)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    /// Add risk warning banner
    func withRiskWarning(_ message: String = "Trading involves substantial risk of loss") -> some View {
        VStack(spacing: 0) {
            self
            EducationalBanner(message: message, icon: "exclamationmark.triangle.fill", color: .red)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    /// Add manual execution reminder
    func withManualExecutionReminder(_ message: String = "You execute trades manually on your own platform") -> some View {
        VStack(spacing: 0) {
            self
            EducationalBanner(message: message, icon: "hand.tap.fill", color: .green)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - About/Legal View
struct AboutLegalView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BALLS OF STEEL v3.0")
                            .font(.headline)
                        Text("Institutional Flow Edition")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\nCreated by someone who got a 74 on the Series 7. NYC cold caller energy. Educational tool for learning the VXX system.")
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Legal")) {
                    NavigationLink("Terms of Service") {
                        TermsOfServiceView()
                    }
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    NavigationLink("Risk Disclaimer") {
                        RiskDisclaimerView()
                    }
                }

                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("3.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Mode")
                        Spacer()
                        Text("Educational")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("About & Legal")
        }
    }
}

// MARK: - Terms of Service (Complete)
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Effective Date: November 8, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("""
                **IMPORTANT: READ CAREFULLY BEFORE USING THIS APPLICATION**

                By downloading, installing, or using Balls of Steel ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.

                ------------------------------------

                **1. EDUCATIONAL TOOL ONLY**

                1.1 The App is an educational tool designed to teach VXX trading strategies and systematic analysis techniques.

                1.2 The App is NOT:
                - A licensed trading platform
                - A broker-dealer or financial advisor
                - An investment service
                - A source of financial advice
                - A guarantee of profits or trading success

                1.3 All strategies, win rates, and examples provided are for educational purposes only and do not constitute recommendations to buy or sell any security.

                ------------------------------------

                **2. NO AUTOMATED TRADING**

                2.1 The App does NOT execute trades automatically.

                2.2 The App does NOT connect to broker APIs for live trading.

                2.3 All market data must be entered manually by the user.

                2.4 You must execute all trades manually on your own trading platform.

                ------------------------------------

                **3. USER RESPONSIBILITY**

                You are solely responsible for:

                3.1 All trading decisions made based on information from the App.

                3.2 Risk management and position sizing decisions.

                3.3 Compliance with all applicable laws and regulations in your jurisdiction.

                3.4 Any and all losses incurred from trading.

                3.5 Verifying accuracy of manually entered data.

                3.6 Understanding options trading risks before trading.

                ------------------------------------

                **4. RISK DISCLOSURE**

                4.1 Trading securities and options involves substantial risk of loss.

                4.2 You can lose your entire investment.

                4.3 Options trading is especially risky and not suitable for all investors.

                4.4 Past performance of strategies does not guarantee future results.

                4.5 Market conditions change constantly - no system eliminates risk.

                4.6 Only trade with money you can afford to lose.

                ------------------------------------

                **5. NO WARRANTY**

                5.1 The App is provided "AS IS" without warranty of any kind, express or implied.

                5.2 We make no guarantees about:
                - Accuracy of strategies or win rates
                - Availability or reliability of the App
                - Suitability for any particular purpose
                - Freedom from errors or bugs

                5.3 We do not warrant that the App will meet your requirements or expectations.

                ------------------------------------

                **6. LIMITATION OF LIABILITY**

                6.1 To the maximum extent permitted by law, we shall not be liable for:
                - Trading losses of any kind
                - Lost profits or opportunities
                - Data loss or corruption
                - Indirect, incidental, or consequential damages
                - Any damages arising from use or inability to use the App

                6.2 Our maximum liability shall not exceed the amount you paid for the App.

                ------------------------------------

                **7. NO BROKER AFFILIATION**

                7.1 The App is not affiliated with, endorsed by, or sponsored by any broker including:
                - Charles Schwab
                - TD Ameritrade
                - ThinkOrSwim
                - Interactive Brokers
                - Any other trading platform

                7.2 All trademarks belong to their respective owners.

                ------------------------------------

                **8. PURCHASES & REFUNDS**

                8.1 In-app purchases are processed through Apple's App Store.

                8.2 Purchases are final and non-refundable except as required by law.

                8.3 Apple's refund policy applies. Contact Apple for refund requests.

                8.4 We do not have access to your payment information.

                ------------------------------------

                **9. DATA & PRIVACY**

                9.1 The App stores data locally on your device only.

                9.2 We do not collect, transmit, or sell your personal information.

                9.3 See our Privacy Policy for full details.

                ------------------------------------

                **10. PROHIBITED USES**

                You agree NOT to:

                10.1 Use the App for illegal activities.

                10.2 Reverse engineer or modify the App.

                10.3 Redistribute or resell the App or its content.

                10.4 Use the App in a way that violates any laws or regulations.

                10.5 Claim the App provides financial advice or guarantees profits.

                ------------------------------------

                **11. CHANGES TO TERMS**

                11.1 We may update these Terms at any time.

                11.2 Continued use of the App after changes constitutes acceptance.

                11.3 Major changes will be communicated through the App.

                ------------------------------------

                **12. TERMINATION**

                12.1 We may terminate your access to the App at any time for any reason.

                12.2 You may stop using the App at any time by deleting it.

                12.3 These Terms survive termination where applicable.

                ------------------------------------

                **13. GOVERNING LAW**

                13.1 These Terms are governed by the laws of New York State, USA.

                13.2 Any disputes shall be resolved in New York courts.

                13.3 If any provision is found invalid, the remaining provisions continue in effect.

                ------------------------------------

                **14. CONTACT**

                For questions about these Terms, contact us through the App's support channels.

                ------------------------------------

                **ACKNOWLEDGMENT**

                By using this App, you acknowledge that:
                - You have read and understood these Terms
                - You agree to be bound by these Terms
                - You understand the risks of trading
                - You are using this App as an educational tool only
                - You will execute all trades manually on your own platform
                - You accept full responsibility for your trading decisions

                74 on the Series 7. This is a learning tool. Trade at your own risk.
                """)
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

// MARK: - Privacy Policy (Complete)
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Effective Date: November 8, 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("""
                Balls of Steel ("we", "us", "the App") is committed to protecting your privacy. This Privacy Policy explains what information we collect (spoiler: almost nothing) and how we use it.

                ------------------------------------

                **1. INFORMATION WE DO NOT COLLECT**

                The App does NOT collect, store, transmit, or sell:

                1.1 Personal Information
                - Name, email, phone number, address
                - Date of birth, gender, demographic info
                - Social security number or tax ID
                - Any personally identifiable information

                1.2 Financial Information
                - Trading account credentials
                - Brokerage account numbers
                - Bank account information
                - Credit card or payment details
                - Trading history or P&L data

                1.3 Trading Data
                - Market data you enter manually
                - Strategies you view or use
                - Signals you generate
                - Prompts you copy
                - Trading decisions you make

                1.4 Device Information
                - Device IDs or advertising identifiers
                - IP address
                - Location data
                - Device fingerprinting

                1.5 Usage Analytics
                - App usage patterns
                - Feature usage statistics
                - Screen views or interactions
                - Crash reports or diagnostics

                **We collect NOTHING. Zero. Nada. Your privacy is 100% protected.**

                ------------------------------------

                **2. LOCAL STORAGE ONLY**

                2.1 The App stores data locally on YOUR device using:
                - UserDefaults (iOS system storage)
                - Local file storage
                - No cloud sync
                - No remote servers

                2.2 Data stored locally includes:
                - Manual data entries (VXX price, volume, etc.)
                - Unlock status (if you purchased full version)
                - App preferences (haptic settings, platform choice)
                - Onboarding completion status

                2.3 This data:
                - Never leaves your device
                - Is not transmitted to us or any third party
                - Is deleted when you delete the App
                - Cannot be accessed by us

                ------------------------------------

                **3. NO THIRD-PARTY SERVICES**

                3.1 The App does NOT use:
                - Analytics services (no Google Analytics, Mixpanel, etc.)
                - Advertising networks
                - Social media SDKs
                - Cloud storage services
                - External APIs for data collection
                - Tracking pixels or beacons

                3.2 The ONLY third-party service we use:
                - Apple's StoreKit for in-app purchases
                - Managed entirely by Apple
                - We never see your payment information

                ------------------------------------

                **4. NO ACCOUNT REQUIRED**

                4.1 The App does not require:
                - Account creation
                - Login credentials
                - Email verification
                - User profiles

                4.2 You can use the App completely anonymously.

                ------------------------------------

                **5. APPLE APP STORE**

                5.1 In-App Purchases:
                - Processed entirely through Apple's App Store
                - We never see your payment information
                - Apple's privacy policy applies to purchase data
                - Apple may collect transaction information

                5.2 Apple ID:
                - Required for App Store downloads
                - Managed by Apple, not us
                - Subject to Apple's Privacy Policy

                ------------------------------------

                **6. DATA SECURITY**

                6.1 Since we don't collect data, there's no data to secure on our end.

                6.2 Local data on your device is protected by:
                - iOS encryption (if enabled on your device)
                - iOS app sandboxing
                - Your device passcode/biometric lock

                6.3 Best practices:
                - Use a strong device passcode
                - Enable device encryption
                - Don't store sensitive info in the App's manual entry fields

                ------------------------------------

                **7. CHILDREN'S PRIVACY**

                7.1 The App is rated 17+ and is not intended for children under 17.

                7.2 We do not knowingly collect information from anyone under 17.

                7.3 Options trading is not appropriate for minors.

                ------------------------------------

                **8. DATA DELETION**

                8.1 To delete all your data:
                - Delete the App from your device
                - All local data is automatically deleted

                8.2 Since we don't collect data remotely, there's nothing for us to delete on our end.

                ------------------------------------

                **9. INTERNATIONAL USERS**

                9.1 The App can be used worldwide.

                9.2 All data stays on YOUR device, regardless of location.

                9.3 No data crosses borders because no data is transmitted.

                9.4 GDPR, CCPA, and other privacy laws:
                - Fully compliant because we collect nothing
                - No data = no privacy concerns
                - No need for consent forms or opt-outs

                ------------------------------------

                **10. CHANGES TO THIS POLICY**

                10.1 We may update this Privacy Policy from time to time.

                10.2 Changes will be posted within the App.

                10.3 Continued use after changes constitutes acceptance.

                10.4 Material changes will be communicated clearly.

                ------------------------------------

                **11. YOUR RIGHTS**

                11.1 Since we don't collect data, there's no data to:
                - Access (it's on your device already)
                - Correct (you control it locally)
                - Delete (delete the App)
                - Export (it's in your device's storage)
                - Opt-out of (there's no collection to opt out of)

                ------------------------------------

                **12. CONTACT US**

                12.1 If you have questions about this Privacy Policy:
                - Use the App's support channels
                - We'll respond as quickly as possible

                12.2 For Apple-related privacy concerns:
                - Contact Apple directly
                - Review Apple's Privacy Policy

                ------------------------------------

                **SUMMARY**

                **What we collect:** NOTHING

                **Where your data goes:** NOWHERE (stays on your device)

                **Who we share with:** NO ONE

                **Third-party services:** Apple StoreKit only (for purchases)

                **Analytics/tracking:** NONE

                **Your privacy:** 100% PROTECTED

                This is the simplest privacy policy you'll ever read because we genuinely don't collect your data. Your trading strategies, manual entries, and app usage stay private on YOUR device.

                74 on the Series 7. Your privacy is respected. Trade with confidence.
                """)
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

// MARK: - Risk Disclaimer (Detailed)
struct RiskDisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Risk Disclaimer")
                    .font(.title)
                    .fontWeight(.bold)

                Text("""
                **WARNING: TRADING INVOLVES SUBSTANTIAL RISK OF LOSS**

                **Options Trading Risks:**
                - Options can expire worthless
                - High volatility can cause rapid losses
                - Leverage amplifies both gains and losses
                - Time decay (theta) works against option buyers
                - Implied volatility crush can cause instant losses

                **VXX-Specific Risks:**
                - VXX is a volatility product, not a stock
                - Subject to contango and roll costs
                - Can lose value even when VIX rises
                - Highly volatile and unpredictable
                - Not suitable for long-term holding

                **System Limitations:**
                - Past performance does not guarantee future results
                - Win rates are historical examples, not promises
                - Market conditions change constantly
                - No system eliminates risk
                - You can lose your entire investment

                **Your Responsibility:**
                - Only trade with risk capital you can afford to lose
                - Understand options before trading them
                - Start small and scale gradually
                - Use proper position sizing
                - Never risk more than 1-2% per trade
                - Consult a licensed financial advisor

                This educational tool does not reduce trading risk. You are 100% responsible for your \
                trading decisions and any losses incurred.
                """)
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("Risk Disclaimer")
    }
}

// MARK: - Preview
#Preview {
    FirstLaunchDisclaimerView(isPresented: .constant(true))
}
