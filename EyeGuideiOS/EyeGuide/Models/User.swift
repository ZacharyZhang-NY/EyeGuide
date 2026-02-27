import Foundation

struct User: Codable, Sendable {
    let id: String
    let deviceId: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserPreference: Codable, Sendable {
    let id: String
    let userId: String
    var voiceSpeed: Double
    var voicePitch: Double
    var descriptionDetail: String
    var language: String
    var vibrationEnabled: Bool
    var highContrastEnabled: Bool
    var enabledFeatures: [String]
    var emergencyContact: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case voiceSpeed = "voice_speed"
        case voicePitch = "voice_pitch"
        case descriptionDetail = "description_detail"
        case language
        case vibrationEnabled = "vibration_enabled"
        case highContrastEnabled = "high_contrast_enabled"
        case enabledFeatures = "enabled_features"
        case emergencyContact = "emergency_contact"
    }
}

struct RegisterResponse: Codable, Sendable {
    let user: User
    let preferences: UserPreference?
}

struct UserResponse: Codable, Sendable {
    let user: User
    let preferences: UserPreference?
}

struct PreferencesResponse: Codable, Sendable {
    let preferences: UserPreference
}
