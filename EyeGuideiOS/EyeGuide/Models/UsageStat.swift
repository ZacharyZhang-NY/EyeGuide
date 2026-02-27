import Foundation

struct UsageStat: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let feature: String
    let timestamp: String
    let duration: Int?
    let success: Bool
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case feature
        case timestamp
        case duration
        case success
        case errorMessage = "error_message"
    }
}

struct UsageStatResponse: Codable, Sendable {
    let stat: UsageStat
}

struct UsageListResponse: Codable, Sendable {
    let stats: [UsageStat]
    let total: Int
    let limit: Int
    let offset: Int
}

struct UsageSummaryItem: Codable, Sendable {
    let feature: String
    let totalUses: String
    let successfulUses: String
    let avgDuration: String

    enum CodingKeys: String, CodingKey {
        case feature
        case totalUses = "total_uses"
        case successfulUses = "successful_uses"
        case avgDuration = "avg_duration"
    }
}

struct UsageSummaryResponse: Codable, Sendable {
    let summary: [UsageSummaryItem]
}
