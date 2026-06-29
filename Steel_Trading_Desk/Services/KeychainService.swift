import Foundation
import Security

struct KeychainService {
    private static let service = Bundle.main.bundleIdentifier ?? "app.mdrn.steel"
    private static let cacheLock = NSLock()
    private static var cachedValues: [String: String] = [:]
    private static var cachedMissingKeys = Set<String>()

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
            #if DEBUG
            print("[Keychain] add failed for \(key): \(addStatus)")
            #endif
        }
    }

    static func load(key: String) -> String? {
        if let cached = cachedValue(for: key) {
            return cached
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            cacheMissing(key)
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

    private static func cache(_ value: String, for key: String) {
        cacheLock.lock()
        cachedValues[key] = value
        cachedMissingKeys.remove(key)
        cacheLock.unlock()
    }

    private static func cacheMissing(_ key: String) {
        cacheLock.lock()
        cachedValues.removeValue(forKey: key)
        cachedMissingKeys.insert(key)
        cacheLock.unlock()
    }
}
