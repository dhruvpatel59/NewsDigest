import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case connectionFailure
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The requested URL is invalid."
        case .connectionFailure: return "Could not connect to the server."
        case .invalidResponse: return "The server provided an invalid response."
        case .decodingError: return "Failed to process the data."
        }
    }
}

// Actor provides built-in concurrency safety
actor NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private var cache: [String: (data: Any, timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 600 // 10 minutes default
    
    func fetch<T: Decodable>(from urlString: String, as type: T.Type, useCache: Bool = true) async throws -> T {
        if useCache, let cached = cache[urlString], Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            if let result = cached.data as? T {
                return result
            }
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "No body"
            print("--- NetworkManager Error: HTTP \(statusCode) ---")
            throw NetworkError.invalidResponse
        }
        
        do {
            let result = try decoder.decode(T.self, from: data)
            
            if useCache {
                cache[urlString] = (result, Date())
            }
            
            return result
        } catch {
            throw NetworkError.decodingError
        }
    }
}
