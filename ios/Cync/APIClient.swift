import Foundation

struct PredictResult: Decodable {
    let label: String
    let score: Double
}

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T
}

enum APIError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .badStatus(let code):
            return "HTTP \(code)"
        case .decoding:
            return "Failed to decode response"
        }
    }
}

final class APIClient {
    // Simulator: localhost works. Device: replace with your Mac LAN IP.
    private let baseURL = URL(string: "http://localhost:3000")!

    func predict(text: String) async throws -> PredictResult {
        guard let url = URL(string: "/api/v1/ai/predict", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["text": text])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.badStatus(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(APIResponse<PredictResult>.self, from: data)
            return decoded.data
        } catch {
            throw APIError.decoding
        }
    }
}
