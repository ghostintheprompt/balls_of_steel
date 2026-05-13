import Foundation
import StoreKit

class StoreKitService: ObservableObject {
    static let shared = StoreKitService()
    
    @Published private(set) var hasProUnlock = true
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
        products = []
    }
    
    func purchase() async throws -> Transaction? {
        hasProUnlock = true
        return nil
    }
    
    func restorePurchases() async {
        hasProUnlock = true
    }
    
    @MainActor
    func updatePurchaseStatus() async {
        hasProUnlock = true
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
