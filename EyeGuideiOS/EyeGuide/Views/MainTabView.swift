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
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.recentSessions.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Your session history will appear here")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.recentSessions) { session in
                                SessionRow(session: session)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .task { await viewModel.loadRecentActivity() }
            .refreshable { await viewModel.loadRecentActivity() }
        }
    }
}

private struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForType(session.sessionType))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionType.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(session.startedAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if session.endedAt == nil {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "navigation": "location.fill"
        case "reading": "doc.text.fill"
        case "social": "person.fill"
        case "shopping": "cart.fill"
        default: "bubble.left.fill"
        }
    }
}
