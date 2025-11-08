import SwiftUI

// MARK: - First Launch Disclaimer
// Required legal disclaimer shown on first app launch

struct FirstLaunchDisclaimerView: View {
    @Binding var isPresented: Bool
    @State private var hasReadDisclaimer = false
    @State private var hasAgreedToTerms = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    disclaimerHeader

                    // Educational Tool Statement
                    educationalToolSection

                    // Risk Disclaimer
                    riskDisclaimerSection

                    // No Financial Advice
                    noAdviceSection

                    // Manual Execution
                    manualExecutionSection

                    // Acknowledgment Checkboxes
                    acknowledgmentSection

                    // Accept Button
                    acceptButton
                }
                .padding()
            }
            .navigationTitle("Important Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true) // Must accept to proceed
    }

    private var disclaimerHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("BALLS OF STEEL")
                .font(.title)
                .fontWeight(.bold)

            Text("Educational Trading Tool")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Please read carefully before using this app")
                .font(.subheadline)
                .foregroundColor(.red)
        }
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

            • Options trading is highly risky and not suitable for all investors
            • You can lose your entire investment
            • Past performance does NOT guarantee future results
            • Win rates and strategies shown are educational examples
            • Market conditions change - no system guarantees profits

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

            • All content is for educational and informational purposes only
            • We do not provide investment, tax, or legal advice
            • Strategies shown are examples, not recommendations
            • Consult a licensed financial advisor before trading
            • You are solely responsible for your trading decisions

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
            • Connect to broker APIs for live trading
            • Execute trades automatically
            • Provide real-time market data
            • Make trading decisions for you

            You must:
            • Enter market data manually from your platform
            • Analyze setups using the educational tools
            • Make your own trading decisions
            • Execute trades on your own platform (ThinkOrSwim, Schwab, etc.)
            """)
        }
    }

    private var acknowledgmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: $hasReadDisclaimer) {
                Text("I have read and understand all disclaimers above")
                    .font(.subheadline)
            }
            .toggleStyle(CheckboxToggleStyle())

            Toggle(isOn: $hasAgreedToTerms) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I agree that:")
                        .font(.subheadline)
                    Text("• This is an educational tool only")
                        .font(.caption)
                    Text("• I trade at my own risk")
                        .font(.caption)
                    Text("• I will not hold the creator liable for losses")
                        .font(.caption)
                }
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow, lineWidth: 2)
                )
        )
    }

    private var acceptButton: some View {
        Button(action: {
            if hasReadDisclaimer && hasAgreedToTerms {
                UserDefaults.standard.set(true, forKey: "hasAcceptedDisclaimer")
                isPresented = false
            }
        }) {
            Text(hasReadDisclaimer && hasAgreedToTerms ? "Accept & Continue" : "Read All Disclaimers First")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasReadDisclaimer && hasAgreedToTerms ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
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
                    .font(.headline)
                    .foregroundColor(color)
            }

            content
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(configuration.isOn ? .blue : .gray)
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
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
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

// MARK: - Terms of Service (Placeholder)
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)

                Text("""
                **Educational Use Only**

                This application is provided as an educational tool for learning trading strategies. \
                It is not a licensed trading platform, financial advisor, or investment service.

                **No Warranty**

                The app is provided "as is" without warranty of any kind. We make no guarantees about \
                accuracy, reliability, or suitability for any purpose.

                **User Responsibility**

                You are solely responsible for:
                • All trading decisions
                • Risk management
                • Compliance with applicable laws
                • Losses incurred from trading

                **Limitation of Liability**

                The creator shall not be liable for any damages arising from use of this application, \
                including but not limited to trading losses, lost profits, or data loss.

                **No Broker Affiliation**

                This app is not affiliated with, endorsed by, or sponsored by any broker, including \
                Charles Schwab, TD Ameritrade, or ThinkOrSwim.
                """)
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy (Placeholder)
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("""
                **Data Collection**

                This app does NOT collect, store, or transmit:
                • Personal information
                • Trading data
                • Account credentials
                • Financial information

                **Local Storage Only**

                All data entered manually is stored locally on your device using UserDefaults. \
                This data never leaves your device.

                **No Analytics**

                We do not use analytics, tracking, or third-party services.

                **No Accounts**

                This app does not require account creation or login.
                """)
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
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
                **⚠️ TRADING INVOLVES SUBSTANTIAL RISK OF LOSS ⚠️**

                **Options Trading Risks:**
                • Options can expire worthless
                • High volatility can cause rapid losses
                • Leverage amplifies both gains and losses
                • Time decay (theta) works against option buyers
                • Implied volatility crush can cause instant losses

                **VXX-Specific Risks:**
                • VXX is a volatility product, not a stock
                • Subject to contango and roll costs
                • Can lose value even when VIX rises
                • Highly volatile and unpredictable
                • Not suitable for long-term holding

                **System Limitations:**
                • Past performance does not guarantee future results
                • Win rates are historical examples, not promises
                • Market conditions change constantly
                • No system eliminates risk
                • You can lose your entire investment

                **Your Responsibility:**
                • Only trade with risk capital you can afford to lose
                • Understand options before trading them
                • Start small and scale gradually
                • Use proper position sizing
                • Never risk more than 1-2% per trade
                • Consult a licensed financial advisor

                This educational tool does not reduce trading risk. You are 100% responsible for your \
                trading decisions and any losses incurred.
                """)
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle("Risk Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    FirstLaunchDisclaimerView(isPresented: .constant(true))
}
