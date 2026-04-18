import Foundation
import StoreKit

// MARK: - StoreKit Service
// Simple, battle-tested freemium unlock
// One product: $69.69 one-time purchase
// No subscriptions, no complexity, no bullshit

@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    // MARK: - Published State
    @Published var hasUnlocked: Bool = false
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    @Published var errorMessage: String?

    // MARK: - Product Configuration
    private let productID = "com.ballsofsteel.fullunlock"
    private let unlockKey = "hasUnlockedFullVersion"

    // Transaction listener
    private var transactionListener: Task<Void, Never>?

    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case restoring
        case success
        case failed(StoreKitError)
    }

    enum StoreKitError: LocalizedError, Equatable {
        case productNotFound
        case purchaseFailed(String)
        case purchaseCancelled
        case verificationFailed
        case networkError
        case unknown

        var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "Product not available. Check your internet connection."
            case .purchaseFailed(let reason):
                return "Purchase failed: \(reason)"
            case .purchaseCancelled:
                return "Purchase was cancelled."
            case .verificationFailed:
                return "Unable to verify purchase. Contact support if you were charged."
            case .networkError:
                return "Network error. Check your connection and try again."
            case .unknown:
                return "An unknown error occurred. Try again later."
            }
        }
    }

    private init() {
        // Check if user has previously unlocked
        hasUnlocked = UserDefaults.standard.bool(forKey: unlockKey)

        // Start transaction listener
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Initialization
    /// Load products from App Store
    func loadProducts() async {
        purchaseState = .loading
        errorMessage = nil

        do {
            let loadedProducts = try await Product.products(for: [productID])
            products = loadedProducts
            purchaseState = .idle

            if products.isEmpty {
                purchaseState = .failed(.productNotFound)
                errorMessage = "Unable to load unlock option. Please try again later."
            }
        } catch {
            purchaseState = .failed(.networkError)
            errorMessage = "Network error loading products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase Flow
    /// Purchase the full unlock
    func purchase() async {
        guard let product = products.first else {
            purchaseState = .failed(.productNotFound)
            errorMessage = "Product not loaded. Try restarting the app."
            return
        }

        purchaseState = .purchasing
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Unlock the app
                await unlockFullVersion()

                // Finish the transaction
                await transaction.finish()

                purchaseState = .success

            case .userCancelled:
                purchaseState = .failed(.purchaseCancelled)
                errorMessage = "Purchase cancelled."

            case .pending:
                purchaseState = .idle
                errorMessage = "Purchase is pending. Check back later."

            @unknown default:
                purchaseState = .failed(.unknown)
                errorMessage = "An unknown error occurred."
            }
        } catch {
            purchaseState = .failed(.purchaseFailed(error.localizedDescription))
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore Purchases
    /// Restore previous purchases
    func restorePurchases() async {
        purchaseState = .restoring
        errorMessage = nil

        do {
            try await AppStore.sync()

            // Check for existing entitlements
            var hasFoundPurchase = false

            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)

                if transaction.productID == productID {
                    await unlockFullVersion()
                    hasFoundPurchase = true
                    break
                }
            }

            if hasFoundPurchase {
                purchaseState = .success
            } else {
                purchaseState = .idle
                errorMessage = "No previous purchase found."
            }
        } catch {
            purchaseState = .failed(.verificationFailed)
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    // MARK: - Transaction Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener
    /// Listen for transactions (e.g., from other devices, ask to buy)
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            guard let self = self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    if transaction.productID == self.productID {
                        await self.unlockFullVersion()
                        await transaction.finish()
                    }
                } catch {
                    #if DEBUG
                    print("Transaction verification failed: \(error)")
                    #endif
                }
            }
        }
    }

    // MARK: - Unlock Logic
    /// Unlock full version (all features)
    private func unlockFullVersion() {
        hasUnlocked = true
        UserDefaults.standard.set(true, forKey: unlockKey)
        #if DEBUG
        print("Full version unlocked!")        #endif
    }

    // MARK: - Feature Access
    /// Check if a feature is available based on unlock status
    func hasAccessTo(_ feature: PremiumFeature) -> Bool {
        if hasUnlocked {
            return true
        }

        // Free features
        return feature.isFreeFeature
    }

    /// Get formatted price for display
    var formattedPrice: String? {
        products.first?.displayPrice
    }
}

// MARK: - Premium Features
enum PremiumFeature {
    // Free (always available)
    case institutionalFlowStrategy
    case institutionalFlowPrompt
    case basicSignalValidator
    case positionSizingCalculator

    // Paid (requires unlock)
    case allStrategies
    case allPromptTemplates
    case advancedTools
    case patternRecognition
    case allDocumentation
    case tradeJournal
    case riskManagement

    var isFreeFeature: Bool {
        switch self {
        case .institutionalFlowStrategy,
             .institutionalFlowPrompt,
             .basicSignalValidator,
             .positionSizingCalculator:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .institutionalFlowStrategy:
            return "Institutional Flow Strategy"
        case .institutionalFlowPrompt:
            return "3:40 PM Prompt Template"
        case .basicSignalValidator:
            return "Basic Signal Validation"
        case .positionSizingCalculator:
            return "Position Sizing Calculator"
        case .allStrategies:
            return "All 16 VXX Strategies"
        case .allPromptTemplates:
            return "All Prompt Coach Templates"
        case .advancedTools:
            return "Advanced Trading Tools"
        case .patternRecognition:
            return "Pattern Recognition System"
        case .allDocumentation:
            return "Complete Strategy Documentation"
        case .tradeJournal:
            return "Trade Journal & Analytics"
        case .riskManagement:
            return "Risk Management Suite"
        }
    }

    var description: String {
        switch self {
        case .institutionalFlowStrategy:
            return "90% win rate window (3:45-4:10 PM)"
        case .institutionalFlowPrompt:
            return "Best prompt template for highest-edge trades"
        case .basicSignalValidator:
            return "Volume + Arrow signal validation"
        case .positionSizingCalculator:
            return "Dynamic position sizing based on volume/IV"
        case .allStrategies:
            return "Complete VXX strategy library with win rates"
        case .allPromptTemplates:
            return "Daily schedule + conditional prompts"
        case .advancedTools:
            return "Technical indicators, pattern detection, more"
        case .patternRecognition:
            return "Shooting Star, Doji, Hammer, Hanging Man"
        case .allDocumentation:
            return "VXX Strategy Lessons + Implementation Guides"
        case .tradeJournal:
            return "Track trades, analyze performance, improve edge"
        case .riskManagement:
            return "Position sizing, stop loss, profit targets"
        }
    }
}

// MARK: - Free vs Paid Helper
extension StoreKitService {
    /// Get list of all premium features for unlock screen
    static var allPremiumFeatures: [PremiumFeature] {
        [
            .allStrategies,
            .allPromptTemplates,
            .advancedTools,
            .patternRecognition,
            .allDocumentation,
            .tradeJournal,
            .riskManagement
        ]
    }

    /// Get list of free features for display
    static var freeFeatures: [PremiumFeature] {
        [
            .institutionalFlowStrategy,
            .institutionalFlowPrompt,
            .basicSignalValidator,
            .positionSizingCalculator
        ]
    }
}
