import Foundation

struct WallhavenAPIResponse: Codable {
    let data: [WallhavenImageDTO]
    let meta: WallhavenMetaDTO
}

struct WallhavenImageDTO: Codable {
    let id: String
    let path: String
    let thumbs: WallhavenThumbsDTO
}

struct WallhavenThumbsDTO: Codable {
    let large: String
    let original: String
    let small: String
}

struct WallhavenMetaDTO: Codable {
    let current_page: Int
    let last_page: Int
    let per_page: Int
    let total: Int
}

class WallhavenAPI {
    static let shared = WallhavenAPI()
    private let baseURL = "https://wallhaven.cc/api/v1"
    
    func getCollection(username: String, id: String, page: Int = 1, apiKey: String? = nil) async throws -> WallhavenAPIResponse {
        var urlString = "\(baseURL)/collections/\(username)/\(id)?page=\(page)"
        if let key = apiKey, !key.isEmpty {
            urlString += "&apikey=\(key)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        // Rate limiting might be an issue, Wallhaven asks for 1 req/sec roughly or check headers.
        // For now, simple fetch.
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(WallhavenAPIResponse.self, from: data)
    }
}
