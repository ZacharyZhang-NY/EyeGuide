import Foundation

struct LocalActivity: Codable, Identifiable {
    let id: UUID
    let feature: String
    let timestamp: Date
    let success: Bool

    init(feature: String, success: Bool) {
        self.id = UUID()
        self.feature = feature
        self.timestamp = Date()
        self.success = success
    }
}

final class LocalActivityStore {
    static let shared = LocalActivityStore()

    private let key = "local_activities"
    private let maxEntries = 50

    func save(feature: String, success: Bool) {
        var activities = load()
        activities.insert(LocalActivity(feature: feature, success: success), at: 0)
        if activities.count > maxEntries {
            activities = Array(activities.prefix(maxEntries))
        }
        if let data = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> [LocalActivity] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let activities = try? JSONDecoder().decode([LocalActivity].self, from: data) else {
            return []
        }
        return activities
    }
}
