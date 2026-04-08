import SwiftUI

// MARK: - Onboarding Flow
// 4 screens. Skippable. NYC energy. Educational positioning.

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var selectedPlatform: TradingPlatform = .thinkOrSwim

    var body: some View {
        ZStack {
            TradingBackdrop()

            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)

                howItWorksPage
                    .tag(1)

                realityCheckPage
                    .tag(2)

                platformSelectionPage
                    .tag(3)
            }

            if currentPage < 3 {
                VStack {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .padding()
                        .foregroundColor(DesignSystem.primaryColor)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Page 1: Welcome
    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            BallsOfSteelMark(size: 124)

            VStack(spacing: 16) {
                BallsOfSteelWordmark(
                    alignment: .center,
                    title: "BALLS OF STEEL",
                    subtitle: "Open first. Close honest."
                )
                .multilineTextAlignment(.center)

                Text("Manual desk for SPY and VXX.")
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.mutedText)
            }

            VStack(spacing: 12) {
                FeatureHighlight(icon: "clock.fill", text: "5 Time Windows", subtext: "70-90% win rates")
                FeatureHighlight(icon: "brain.head.profile", text: "Prompt Coach", subtext: "AI analysis at the right time")
                FeatureHighlight(icon: "arrow.up.arrow.down.circle.fill", text: "Arrow + Volume", subtext: "Simple signal validation")
            }

            Text("**Your phone beeps. VXX institutional flow. 300% volume. Arrow confirmed. You make the trade.**")
                .font(DesignSystem.Typography.bodyFont)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundColor(DesignSystem.mutedText)

            Spacer()

            Button(action: { withAnimation { currentPage = 1 } }) {
                Text("Let's Go")
                    .font(DesignSystem.Typography.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Page 2: How It Works
    private var howItWorksPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How It Works")
                .font(DesignSystem.Typography.heroFont)
                .foregroundColor(DesignSystem.primaryText)

            VStack(alignment: .leading, spacing: 24) {
                OnboardingStep(
                    number: "1",
                    icon: "hand.point.up.left.fill",
                    title: "Enter Market Data",
                    description: "Open ThinkOrSwim or Schwab. Check VXX price, volume, arrow signal. Enter manually in the app.",
                    color: .blue
                )

                OnboardingStep(
                    number: "2",
                    icon: "brain.head.profile",
                    title: "Prompt Coach Analyzes",
                    description: "App delivers the right analysis prompt at the right time. Copy to ChatGPT. Get systematic analysis in 30 seconds.",
                    color: .purple
                )

                OnboardingStep(
                    number: "3",
                    icon: "checkmark.circle.fill",
                    title: "You Execute The Trade",
                    description: "Make your decision. Execute on your platform. Not automated—but close.",
                    color: .green
                )
            }

            Text("**Total time: ~15 minutes spread across the day.**")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)

            Spacer()

            Button(action: { withAnimation { currentPage = 2 } }) {
                Text("Got It")
                    .font(DesignSystem.Typography.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Page 3: Reality Check
    private var realityCheckPage: some View {
        VStack(spacing: 32) {
            Spacer()

            BallsOfSteelMark(size: 92, primaryAccent: DesignSystem.warningColor, bullishAccent: DesignSystem.primaryColor, bearishAccent: DesignSystem.bearishColor)

            Text("Reality Check")
                .font(DesignSystem.Typography.heroFont)
                .foregroundColor(DesignSystem.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                RealityCheckPoint(
                    icon: "graduationcap.fill",
                    text: "This is an **educational tool**. Not financial advice.",
                    color: .blue
                )

                RealityCheckPoint(
                    icon: "exclamationmark.shield.fill",
                    text: "Trading involves **substantial risk of loss**. You can lose your entire investment.",
                    color: .red
                )

                RealityCheckPoint(
                    icon: "hand.tap.fill",
                    text: "**You execute all trades** manually on your own platform.",
                    color: .green
                )

                RealityCheckPoint(
                    icon: "person.fill.checkmark",
                    text: "74 on the Series 7. NYC cold caller. **This is a learning tool.**",
                    color: .purple
                )
            }

            Text("Only trade with money you can afford to lose.")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.bearishColor)
                .padding()
                .background(DesignSystem.bearishColor.opacity(0.12))
                .cornerRadius(8)

            Spacer()

            Button(action: { withAnimation { currentPage = 3 } }) {
                Text("I Understand")
                    .font(DesignSystem.Typography.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.warningColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Page 4: Platform Selection
    private var platformSelectionPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Choose Your Platform")
                .font(DesignSystem.Typography.heroFont)
                .foregroundColor(DesignSystem.primaryText)

            Text("Where do you execute trades?")
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.mutedText)

            VStack(spacing: 16) {
                ForEach(TradingPlatform.allCases, id: \.self) { platform in
                    PlatformButton(
                        platform: platform,
                        isSelected: selectedPlatform == platform,
                        action: { selectedPlatform = platform }
                    )
                }
            }
            .padding(.horizontal, 32)

            Text("You'll enter data manually from your platform. The app validates signals and generates prompts.")
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                savePlatformPreference()
                completeOnboarding()
            }) {
                Text("Start Trading")
                    .font(DesignSystem.Typography.headlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.bullishColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Helpers
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isPresented = false
    }

    private func savePlatformPreference() {
        UserDefaults.standard.set(selectedPlatform.rawValue, forKey: "selectedTradingPlatform")
    }
}

// MARK: - Feature Highlight
struct FeatureHighlight: View {
    let icon: String
    let text: String
    let subtext: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(DesignSystem.primaryColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(DesignSystem.Typography.headlineFont)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.primaryText)
                Text(subtext)
                    .font(DesignSystem.Typography.captionFont)
                    .foregroundColor(DesignSystem.mutedText)
            }

            Spacer()
        }
        .deskPanel(glow: DesignSystem.primaryColor.opacity(0.08), padding: 14)
    }
}

// MARK: - Onboarding Step
struct OnboardingStep: View {
    let number: String
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                Text(number)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(DesignSystem.Typography.headlineFont)
                        .foregroundColor(DesignSystem.primaryText)
                }

                Text(description)
                    .font(DesignSystem.Typography.bodyFont)
                    .foregroundColor(DesignSystem.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .deskPanel(glow: color.opacity(0.10), padding: 0)
    }
}

// MARK: - Reality Check Point
struct RealityCheckPoint: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            Text(LocalizedStringKey(text))
                .font(DesignSystem.Typography.bodyFont)
                .foregroundColor(DesignSystem.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .deskPanel(glow: color.opacity(0.08), padding: 0)
    }
}

// MARK: - Platform Button
struct PlatformButton: View {
    let platform: TradingPlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(platform.displayName)
                    .font(DesignSystem.Typography.bodyFont)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(DesignSystem.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.bullishColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? DesignSystem.bullishColor.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? DesignSystem.bullishColor : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trading Platform
enum TradingPlatform: String, CaseIterable {
    case thinkOrSwim = "thinkorswim"
    case schwab = "schwab"
    case tdAmeritrade = "tdameritrade"
    case interactiveBrokers = "interactivebrokers"
    case other = "other"

    var displayName: String {
        switch self {
        case .thinkOrSwim: return "ThinkOrSwim (TD Ameritrade)"
        case .schwab: return "Charles Schwab"
        case .tdAmeritrade: return "TD Ameritrade"
        case .interactiveBrokers: return "Interactive Brokers"
        case .other: return "Other Platform"
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(isPresented: .constant(true))
}
