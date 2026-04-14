import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    enum KeychainError: Error {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
    }
    
    func save(_ data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query.merging(attributesToUpdate) { (_, new) in new } as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus != errSecSuccess {
                print("--- Keychain Error: Update failed with status \(updateStatus) ---")
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            print("--- Keychain Error: Save failed with status \(status) ---")
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
