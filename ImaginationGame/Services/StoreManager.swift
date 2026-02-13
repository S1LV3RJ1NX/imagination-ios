//
//  StoreManager.swift
//  ImaginationGame
//
//  StoreKit 2 manager for non-consumable IAP
//  Product: "Unlock All Chambers" - one-time purchase
//

import Combine
import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    // MARK: - Product ID
    // Configure this in App Store Connect under In-App Purchases
    nonisolated static let unlockAllProductID = "com.prathamesh.ImaginationGame.unlockall"
    
    // MARK: - Published State
    @Published var isUnlocked: Bool = false
    @Published var product: Product?
    @Published var isPurchasing: Bool = false
    @Published var errorMessage: String?
    
    private var transactionListener: Task<Void, Error>?
    
    // MARK: - Init
    
    init() {
        // Check persisted state first (instant)
        isUnlocked = UserDefaults.standard.bool(forKey: "chambersUnlocked")
        
        // Listen for transactions
        transactionListener = listenForTransactions()
        
        // Load product and verify entitlement
        Task {
            await loadProduct()
            await checkEntitlement()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Load Product
    
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [StoreManager.unlockAllProductID])
            if let product = products.first {
                self.product = product
                print("💰 Product loaded: \(product.displayName) - \(product.displayPrice)")
            } else {
                print("⚠️ No product found for ID: \(StoreManager.unlockAllProductID)")
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            errorMessage = "Unable to load purchase options."
        }
    }
    
    // MARK: - Purchase
    
    func purchase() async {
        guard let product = product else {
            errorMessage = "Product not available. Please try again."
            return
        }
        
        guard !isPurchasing else { return }
        
        isPurchasing = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                unlock()
                print("✅ Purchase successful!")
                
            case .userCancelled:
                print("ℹ️ User cancelled purchase")
                
            case .pending:
                print("⏳ Purchase pending (Ask to Buy)")
                errorMessage = "Purchase is pending approval."
                
            @unknown default:
                print("⚠️ Unknown purchase result")
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            errorMessage = "Purchase failed. Please try again."
        }
        
        isPurchasing = false
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlement()
            
            if isUnlocked {
                print("✅ Purchase restored!")
            } else {
                errorMessage = "No previous purchase found."
            }
        } catch {
            print("❌ Restore failed: \(error)")
            errorMessage = "Unable to restore purchases."
        }
    }
    
    // MARK: - Check Entitlement
    
    func checkEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == StoreManager.unlockAllProductID {
                    unlock()
                    return
                }
            }
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID == StoreManager.unlockAllProductID {
                        await self.unlock()
                    }
                    await transaction.finish()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    private func unlock() {
        isUnlocked = true
        UserDefaults.standard.set(true, forKey: "chambersUnlocked")
        print("🔓 Chambers unlocked!")
    }
}
