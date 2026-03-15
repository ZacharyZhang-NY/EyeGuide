import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView()
            }
            Tab("Features", systemImage: "square.stack.3d.up.fill", value: 1) {
                CameraView()
            }
            Tab("History", systemImage: "clock.fill", value: 2) {
                HistoryView()
            }
            Tab("Profile", systemImage: "person.fill", value: 3) {
                SettingsView()
            }
        }
        .tint(Color.primary)
    }
}

struct HistoryView: View {
    @State private var activities: [LocalActivity] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Loading activity history")
                } else if activities.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Your activity history will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(activities) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .task {
                activities = LocalActivityStore.shared.load()
                isLoading = false
            }
            .refreshable {
                activities = LocalActivityStore.shared.load()
            }
        }
    }
}

private struct ActivityRow: View {
    let activity: LocalActivity

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                Image(systemName: iconForFeature(activity.feature))
                    .font(.system(size: 14))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(titleForFeature(activity.feature))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(formatDate(activity.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !activity.success {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(titleForFeature(activity.feature)), \(formatDate(activity.timestamp))\(activity.success ? "" : ", failed")"
        )
    }

    private func iconForFeature(_ feature: String) -> String {
        switch feature {
        case "scene_description": return "eye.fill"
        case "text_reading": return "doc.text.fill"
        case "social_assistant": return "person.2.fill"
        case "object_recognition": return "scope"
        case "voice_interaction": return "mic.fill"
        default: return "bubble.left.fill"
        }
    }

    private func titleForFeature(_ feature: String) -> String {
        switch feature {
        case "scene_description": return "Scene Description"
        case "text_reading": return "Text Reading"
        case "social_assistant": return "Social Assist"
        case "object_recognition": return "Object Finder"
        case "voice_interaction": return "Voice Question"
        default: return "Activity"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }
}
