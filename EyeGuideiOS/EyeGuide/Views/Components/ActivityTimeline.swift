import SwiftUI

struct ActivityTimeline: View {
    let sessions: [Session]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if sessions.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sessions.prefix(3).enumerated()), id: \.element.id) { index, session in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 40, height: 40)
                                Image(systemName: iconForSessionType(session.sessionType))
                                    .font(.system(size: 14))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(titleForSessionType(session.sessionType))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(formatDate(session.startedAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .accessibilityElement(children: .combine)

                        if index < min(sessions.count, 3) - 1 {
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

    private func iconForSessionType(_ type: String) -> String {
        switch type {
        case "navigation": return "location.fill"
        case "reading": return "doc.text.fill"
        case "social": return "person.fill"
        case "shopping": return "cart.fill"
        default: return "bubble.left.fill"
        }
    }

    private func titleForSessionType(_ type: String) -> String {
        switch type {
        case "navigation": return "Navigation Session"
        case "reading": return "Text Reading"
        case "social": return "Social Assist"
        case "shopping": return "Shopping Assist"
        default: return "General Session"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return dateString }
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .short
        return relative.localizedString(for: date, relativeTo: Date())
    }
}
