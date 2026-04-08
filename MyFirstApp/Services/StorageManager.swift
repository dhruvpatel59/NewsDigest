import Foundation

/// A high-performance manager for handling file-based persistence.
/// Replaces UserDefaults for large data sets to improve app launch and runtime performance.
actor StorageManager {
    static let shared = StorageManager()
    private init() {}
    
    private let fileManager = FileManager.default
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private func getURL(for key: String) -> URL {
        let docs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !fileManager.fileExists(atPath: docs.path) {
            try? fileManager.createDirectory(at: docs, withIntermediateDirectories: true)
        }
        return docs.appendingPathComponent("\(key).json")
    }
    
    func save<T: Encodable>(_ data: T, key: String) async {
        do {
            let encoded = try encoder.encode(data)
            let url = getURL(for: key)
            try encoded.write(to: url, options: .atomic)
        } catch {
            print("--- StorageManager Error Saving \(key): \(error.localizedDescription) ---")
        }
    }
    
    func load<T: Decodable>(key: String, as type: T.Type) async -> T? {
        let url = getURL(for: key)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("--- StorageManager Error Loading \(key): \(error.localizedDescription) ---")
            return nil
        }
    }
    
    func remove(key: String) async {
        let url = getURL(for: key)
        try? fileManager.removeItem(at: url)
    }
}
