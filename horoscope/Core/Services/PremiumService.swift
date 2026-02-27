import Foundation
import Observation
import StoreKit
import os

@MainActor
@Observable
final class PremiumService {
    static let shared = PremiumService()

    private let logger = Logger(subsystem: "rk.horoscope", category: "PremiumService")
    private let defaultProductIDs: [String] = [
        "rk.horoscope.premium.monthly",
        "rk.horoscope.premium.yearly"
    ]

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false

    private var transactionUpdatesTask: Task<Void, Never>?

    var hasPremiumAccess: Bool {
        !purchasedProductIDs.isEmpty
    }

    private var productIDs: [String] {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "PREMIUM_PRODUCT_IDS") as? String {
            let parsed = configured
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if !parsed.isEmpty {
                return parsed
            }
        }
        return defaultProductIDs
    }

    private init() {
        transactionUpdatesTask = observeTransactionUpdates()

        Task {
            await refreshProducts()
            await refreshEntitlements()
        }
    }

    func refreshProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: productIDs)
            products = loaded.sorted(by: { $0.price < $1.price })
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription, privacy: .public)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
            return true

        case .pending:
            return false

        case .userCancelled:
            return false

        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            logger.error("Failed to restore purchases: \(error.localizedDescription, privacy: .public)")
        }
    }

    func refreshEntitlements() async {
        var active: Set<String> = []

        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(entitlement) else {
                continue
            }

            if transaction.revocationDate == nil {
                active.insert(transaction.productID)
            }
        }

        purchasedProductIDs = active
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            guard let self else { return }

            for await update in Transaction.updates {
                guard let transaction = try? self.checkVerified(update) else {
                    continue
                }

                _ = await MainActor.run {
                    self.purchasedProductIDs.insert(transaction.productID)
                }
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PremiumError.failedVerification
        }
    }
}

enum PremiumError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return String(localized: "premium.error.verification_failed")
        }
    }
}
