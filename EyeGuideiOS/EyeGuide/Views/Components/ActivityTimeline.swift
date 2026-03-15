import SwiftUI

struct ActivityTimeline: View {
    let activities: [LocalActivity]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .accessibilityLabel("Loading recent activity")
            } else if activities.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .accessibilityLabel("No recent activity recorded")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activities.prefix(3).enumerated()), id: \.element.id) { index, activity in
                        HStack(alignment: .top, spacing: 16) {
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
                                    .fontWeight(.semibold)
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
                        .padding(.vertical, 12)
                        .accessibilityElement(children: .combine)

                        if index < min(activities.count, 3) - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        }
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
