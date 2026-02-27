import Foundation

struct Session: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let startedAt: String
    let endedAt: String?
    let location: String?
    let sessionType: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case location
        case sessionType = "session_type"
    }
}

struct SessionResponse: Codable, Sendable {
    let session: Session
}

struct SessionListResponse: Codable, Sendable {
    let sessions: [Session]
    let total: Int
    let limit: Int
    let offset: Int
}
