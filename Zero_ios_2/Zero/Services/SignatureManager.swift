import Foundation
import UIKit

/// Manager for storing and retrieving user signatures with iCloud sync
class SignatureManager {
    static let shared = SignatureManager()

    private let signatureKey = "savedSignature"
    private let signatureImageKey = "savedSignatureImage"

    // iCloud key-value store for signature sync across devices
    private let iCloudStore = NSUbiquitousKeyValueStore.default

    private init() {
        // Listen for iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )

        // Sync from iCloud on init
        syncFromiCloud()
    }

    @objc private func iCloudStoreDidChange(_ notification: Notification) {
        Logger.info("iCloud signature data changed, syncing...", category: .app)
        syncFromiCloud()
    }

    private func syncFromiCloud() {
        // Sync text signature
        if let cloudSignature = iCloudStore.string(forKey: signatureKey) {
            UserDefaults.standard.set(cloudSignature, forKey: signatureKey)
        }

        // Sync image signature
        if let cloudImageData = iCloudStore.data(forKey: signatureImageKey) {
            UserDefaults.standard.set(cloudImageData, forKey: signatureImageKey)
        }
    }

    // MARK: - Text Signature

    /// Save a text signature (user's typed name)
    func saveSignature(name: String) {
        UserDefaults.standard.set(name, forKey: signatureKey)
        iCloudStore.set(name, forKey: signatureKey)
        iCloudStore.synchronize()
        Logger.info("Signature saved and synced to iCloud: \(name)", category: .app)
    }

    /// Get saved text signature
    func getSavedSignature() -> String? {
        return UserDefaults.standard.string(forKey: signatureKey)
    }

    /// Check if user has a saved signature
    func hasSignature() -> Bool {
        return getSavedSignature() != nil
    }

    /// Clear saved signature
    func clearSignature() {
        UserDefaults.standard.removeObject(forKey: signatureKey)
        UserDefaults.standard.removeObject(forKey: signatureImageKey)
        iCloudStore.removeObject(forKey: signatureKey)
        iCloudStore.removeObject(forKey: signatureImageKey)
        iCloudStore.synchronize()
        Logger.info("Signature cleared from device and iCloud", category: .app)
    }

    // MARK: - Image Signature (Future: Canvas Drawing)

    /// Save a signature image (for drawn signatures)
    func saveSignatureImage(_ image: UIImage) {
        if let data = image.pngData() {
            UserDefaults.standard.set(data, forKey: signatureImageKey)
            iCloudStore.set(data, forKey: signatureImageKey)
            iCloudStore.synchronize()
            Logger.info("Signature image saved and synced to iCloud", category: .app)
        }
    }

    /// Get saved signature image
    func getSavedSignatureImage() -> UIImage? {
        guard let data = UserDefaults.standard.data(forKey: signatureImageKey) else {
            return nil
        }
        return UIImage(data: data)
    }

    /// Check if user has a saved signature image
    func hasSignatureImage() -> Bool {
        return getSavedSignatureImage() != nil
    }
}
