import Foundation
import Security

struct KeychainService {
    private static let service = Bundle.main.bundleIdentifier ?? "app.mdrn.steel"
    private static let cacheLock = NSLock()
    private static var cachedValues: [String: String] = [:]
    private static var cachedMissingKeys = Set<String>()
    private static var cachedProtectedKeys = Set<String>()
    private static var suppressInteractiveReads = false

    static var isInteractionSuppressedForSession: Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return suppressInteractiveReads
    }

    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let matchQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
        let updateAttributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(matchQuery as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            cache(value, for: key)
            return
        }
        guard updateStatus == errSecItemNotFound else {
            handleAccessFailure(status: updateStatus, key: key, allowUserPrompt: true)
            #if DEBUG
            print("[Keychain] update failed for \(key): \(updateStatus)")
            #endif
            return
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus == errSecSuccess || addStatus == errSecDuplicateItem {
            cache(value, for: key)
        } else {
            handleAccessFailure(status: addStatus, key: key, allowUserPrompt: true)
            #if DEBUG
            print("[Keychain] add failed for \(key): \(addStatus)")
            #endif
        }
    }

    static func cacheSessionValue(_ value: String, for key: String) {
        if value.isEmpty {
            cacheMissing(key)
        } else {
            cache(value, for: key)
        }
    }

    static func load(key: String, allowUserPrompt: Bool = true) -> String? {
        if let cached = cachedValue(for: key) {
            return cached
        }
        guard shouldAttemptRead(key: key, allowUserPrompt: allowUserPrompt) else {
            return nil
        }

        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        if !allowUserPrompt {
            query[kSecUseAuthenticationUI] = kSecUseAuthenticationUISkip
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            handleAccessFailure(status: status, key: key, allowUserPrompt: allowUserPrompt)
            return nil
        }
        cache(value, for: key)
        return value
    }

    static func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
        SecItemDelete(query as CFDictionary)
        cacheMissing(key)
    }

    private static func cachedValue(for key: String) -> String?? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let value = cachedValues[key] {
            return value
        }
        if cachedMissingKeys.contains(key) {
            return .some(nil)
        }
        return .none
    }

    private static func shouldAttemptRead(key: String, allowUserPrompt: Bool) -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if allowUserPrompt, suppressInteractiveReads {
            return false
        }
        if !allowUserPrompt, cachedProtectedKeys.contains(key) {
            return false
        }
        return true
    }

    private static func cache(_ value: String, for key: String) {
        cacheLock.lock()
        cachedValues[key] = value
        cachedMissingKeys.remove(key)
        cachedProtectedKeys.remove(key)
        cacheLock.unlock()
    }

    private static func cacheMissing(_ key: String) {
        cacheLock.lock()
        cachedValues.removeValue(forKey: key)
        cachedProtectedKeys.remove(key)
        cachedMissingKeys.insert(key)
        cacheLock.unlock()
    }

    private static func markProtected(_ key: String, suppressPrompts: Bool) {
        cacheLock.lock()
        cachedValues.removeValue(forKey: key)
        cachedMissingKeys.remove(key)
        cachedProtectedKeys.insert(key)
        if suppressPrompts {
            suppressInteractiveReads = true
        }
        cacheLock.unlock()
    }

    private static func handleAccessFailure(status: OSStatus, key: String, allowUserPrompt: Bool) {
        if status == errSecItemNotFound {
            cacheMissing(key)
            return
        }
        if isUserInteractionFailure(status) {
            markProtected(key, suppressPrompts: allowUserPrompt)
            return
        }
        #if DEBUG
        print("[Keychain] load failed for \(key): \(status)")
        #endif
    }

    private static func isUserInteractionFailure(_ status: OSStatus) -> Bool {
        status == errSecUserCanceled ||
        status == errSecAuthFailed ||
        status == errSecInteractionNotAllowed
    }
}
