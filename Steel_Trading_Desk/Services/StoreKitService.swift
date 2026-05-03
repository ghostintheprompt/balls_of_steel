import Foundation
import StoreKit

class StoreKitService: ObservableObject {
    static let shared = StoreKitService()
    
    @Published private(set) var hasProUnlock = false
    @Published private(set) var products: [Product] = []
    
    private let proProductId = "app.mdrn.steel.pro_unlock"
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await fetchProducts()
            await updatePurchaseStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func fetchProducts() async {
        do {
            products = try await Product.products(for: [proProductId])
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func purchase() async throws -> Transaction? {
        guard let product = products.first(where: { $0.id == proProductId }) else {
            return nil
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchaseStatus()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchaseStatus()
    }
    
    @MainActor
    func updatePurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == proProductId {
                    hasProUnlock = true
                    return
                }
            } catch {
                print("Transaction verification failed")
            }
        }
        hasProUnlock = false
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchaseStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
