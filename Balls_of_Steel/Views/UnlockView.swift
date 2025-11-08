import SwiftUI

// MARK: - Unlock Screen
// $69.69 - One time. All features. No BS.

struct UnlockView: View {
    @StateObject private var storeKit = StoreKitService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingSuccess = false
    @State private var showingError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    unlockHeader

                    // What You Get
                    whatYouGetSection

                    // Free Version (For Comparison)
                    freeVersionSection

                    // Purchase Button
                    purchaseSection

                    // Restore Purchases
                    restoreButton

                    // Fine Print
                    finePrint
                }
                .padding()
            }
            .navigationTitle("Unlock Full Version")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if storeKit.hasUnlocked {
                        Button("Done") { dismiss() }
                    } else {
                        Button("Maybe Later") { dismiss() }
                    }
                }
            }
            .alert("Unlocked!", isPresented: $showingSuccess) {
                Button("Let's Go") { dismiss() }
            } message: {
                Text("All 16 strategies, complete Prompt Coach, full tools. You're ready.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(storeKit.errorMessage ?? "An error occurred. Try again.")
            }
            .task {
                await storeKit.loadProducts()
            }
            .onChange(of: storeKit.purchaseState) { _, newState in
                if case .success = newState {
                    showingSuccess = true
                }
                if case .failed = newState {
                    showingError = true
                }
            }
        }
    }

    // MARK: - Header
    private var unlockHeader: some View {
        VStack(spacing: 16) {
            // Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            Text("BALLS OF STEEL")
                .font(.title)
                .fontWeight(.black)

            Text("Full System Unlock")
                .font(.headline)
                .foregroundColor(.secondary)

            // Price
            if let price = storeKit.formattedPrice {
                Text(price)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            } else {
                ProgressView()
            }

            Text("One-time payment. No subscriptions. No hidden fees.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - What You Get
    private var whatYouGetSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("What You Get")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            ForEach(StoreKitService.allPremiumFeatures, id: \.displayName) { feature in
                PremiumFeatureRow(feature: feature)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                )
        )
    }

    // MARK: - Free Version (Comparison)
    private var freeVersionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
                Text("Free Version Includes")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            ForEach(StoreKitService.freeFeatures, id: \.displayName) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.displayName)
                            .font(.subheadline)
                        Text(feature.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text("Unlock to get ALL strategies, prompts, and tools.")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    // MARK: - Purchase Section
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if storeKit.hasUnlocked {
                // Already unlocked
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Full Version Unlocked")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)

            } else {
                // Purchase button
                Button(action: {
                    Task {
                        await storeKit.purchase()
                    }
                }) {
                    HStack(spacing: 12) {
                        if case .purchasing = storeKit.purchaseState {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "star.fill")
                            Text("Unlock Full Version")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(storeKit.products.isEmpty || isPurchasing)

                if case .loading = storeKit.purchaseState {
                    HStack {
                        ProgressView()
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var isPurchasing: Bool {
        if case .purchasing = storeKit.purchaseState {
            return true
        }
        return false
    }

    // MARK: - Restore Button
    private var restoreButton: some View {
        Button(action: {
            Task {
                await storeKit.restorePurchases()
            }
        }) {
            HStack(spacing: 8) {
                if case .restoring = storeKit.purchaseState {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text("Restore Purchases")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .disabled(case .restoring = storeKit.purchaseState)
    }

    // MARK: - Fine Print
    private var finePrint: some View {
        VStack(spacing: 12) {
            Text("74 on the Series 7. This is an educational tool.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Payment charged to Apple ID account. No auto-renewal. Educational tool - not financial advice.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Unlock Prompt (Used in other views)
struct UnlockPromptBanner: View {
    @StateObject private var storeKit = StoreKitService.shared
    @State private var showingUnlockScreen = false

    let feature: PremiumFeature

    var body: some View {
        if !storeKit.hasAccessTo(feature) {
            Button(action: { showingUnlockScreen = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unlock Full Version")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Get \(feature.displayName) + all premium features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingUnlockScreen) {
                UnlockView()
            }
        }
    }
}

// MARK: - View Extension for Easy Gating
extension View {
    /// Gate a view behind premium unlock
    func requiresUnlock(_ feature: PremiumFeature) -> some View {
        Group {
            if StoreKitService.shared.hasAccessTo(feature) {
                self
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("Premium Feature")
                        .font(.headline)

                    Text(feature.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    UnlockPromptBanner(feature: feature)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    UnlockView()
}
