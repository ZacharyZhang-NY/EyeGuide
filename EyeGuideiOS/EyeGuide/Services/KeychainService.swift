import Foundation
import Security

enum KeychainService {
    private static let deviceIdKey = "com.ZacharyZhang.EyeGuide.deviceId"

    static func getOrCreateDeviceId() -> String {
        if let existing = getDeviceId() {
            return existing
        }
        let newId = UUID().uuidString
        save(deviceId: newId)
        return newId
    }

    static func getDeviceId() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: deviceIdKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let deviceId = String(data: data, encoding: .utf8) else {
            return nil
        }
        return deviceId
    }

    private static func save(deviceId: String) {
        guard let data = deviceId.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: deviceIdKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
