import Foundation

final class APIService {
    static let shared = APIService()

    private let baseURL = "https://eyeguide-api-1048901501985.us-central1.run.app"
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    private var deviceId: String {
        KeychainService.getOrCreateDeviceId()
    }

    private func request(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(deviceId, forHTTPHeaderField: "X-Device-Id")

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        return data
    }

    // MARK: - User

    func registerDevice(deviceId: String) async throws -> RegisterResponse {
        struct Body: Encodable { let device_id: String }
        let data = try await request(
            "/api/users/register", method: "POST",
            body: Body(device_id: deviceId)
        )
        return try decoder.decode(RegisterResponse.self, from: data)
    }

    func getUser() async throws -> UserResponse {
        let data = try await request("/api/users/me")
        return try decoder.decode(UserResponse.self, from: data)
    }

    func updatePreferences(_ updates: PreferenceUpdate) async throws -> PreferencesResponse {
        let data = try await request("/api/users/me/preferences", method: "PATCH", body: updates)
        return try decoder.decode(PreferencesResponse.self, from: data)
    }

    // MARK: - Sessions

    func createSession(type: String) async throws -> SessionResponse {
        struct Body: Encodable { let session_type: String }
        let data = try await request(
            "/api/sessions", method: "POST",
            body: Body(session_type: type)
        )
        return try decoder.decode(SessionResponse.self, from: data)
    }

    func endSession(id: String) async throws -> SessionResponse {
        let data = try await request("/api/sessions/\(id)/end", method: "PATCH")
        return try decoder.decode(SessionResponse.self, from: data)
    }

    func getSessions(limit: Int = 20, offset: Int = 0) async throws -> SessionListResponse {
        let data = try await request("/api/sessions?limit=\(limit)&offset=\(offset)")
        return try decoder.decode(SessionListResponse.self, from: data)
    }

    // MARK: - Usage

    func recordUsage(feature: String, success: Bool, duration: Int? = nil) async throws {
        struct Body: Encodable {
            let feature: String
            let success: Bool
            let duration: Int?
        }
        _ = try await request(
            "/api/usage", method: "POST",
            body: Body(feature: feature, success: success, duration: duration)
        )
    }

    // MARK: - AI Config

    struct AIConfigResponse: Codable {
        let apiKey: String
        let wsUrl: String
        let model: String
    }

    func getAIConfig() async throws -> AIConfigResponse {
        let data = try await request("/api/ai/config")
        return try decoder.decode(AIConfigResponse.self, from: data)
    }

    // MARK: - AI

    func analyzeScene(
        imageBase64: String,
        detailLevel: String = "standard",
        language: String = "en"
    ) async throws -> GeminiResponse {
        struct Body: Encodable {
            let image: String
            let detail_level: String
            let language: String
        }
        let data = try await request(
            "/api/ai/scene", method: "POST",
            body: Body(image: imageBase64, detail_level: detailLevel, language: language)
        )
        return try decoder.decode(GeminiResponse.self, from: data)
    }

    func readText(
        imageBase64: String,
        language: String = "en"
    ) async throws -> GeminiResponse {
        struct Body: Encodable {
            let image: String
            let language: String
        }
        let data = try await request(
            "/api/ai/read-text", method: "POST",
            body: Body(image: imageBase64, language: language)
        )
        return try decoder.decode(GeminiResponse.self, from: data)
    }

    func conversation(
        message: String,
        imageBase64: String? = nil,
        history: [ConversationEntry] = [],
        language: String = "en"
    ) async throws -> GeminiResponse {
        struct Body: Encodable {
            let message: String
            let image: String?
            let conversation_history: [ConversationEntry]?
            let language: String
        }
        let data = try await request(
            "/api/ai/conversation", method: "POST",
            body: Body(
                message: message,
                image: imageBase64,
                conversation_history: history.isEmpty ? nil : history,
                language: language
            )
        )
        return try decoder.decode(GeminiResponse.self, from: data)
    }

    func findObject(
        imageBase64: String,
        targetObject: String,
        language: String = "en"
    ) async throws -> GeminiResponse {
        struct Body: Encodable {
            let image: String
            let target_object: String
            let language: String
        }
        let data = try await request(
            "/api/ai/find-object", method: "POST",
            body: Body(image: imageBase64, target_object: targetObject, language: language)
        )
        return try decoder.decode(GeminiResponse.self, from: data)
    }

    func analyzeSocial(
        imageBase64: String,
        language: String = "en"
    ) async throws -> GeminiResponse {
        struct Body: Encodable {
            let image: String
            let language: String
        }
        let data = try await request(
            "/api/ai/social", method: "POST",
            body: Body(image: imageBase64, language: language)
        )
        return try decoder.decode(GeminiResponse.self, from: data)
    }
}

// MARK: - Supporting Types

struct PreferenceUpdate: Encodable, Sendable {
    var voice_speed: Double?
    var voice_pitch: Double?
    var description_detail: String?
    var language: String?
    var vibration_enabled: Bool?
    var high_contrast_enabled: Bool?
    var enabled_features: [String]?
    var emergency_contact: String?
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .invalidResponse: "Invalid response"
        case .serverError(let code): "Server error (\(code))"
        }
    }
}
