import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    AIStatusCard(
                        isActive: viewModel.activeSession != nil,
                        statusText: viewModel.activeSession != nil
                            ? "Session in progress"
                            : "Ready to assist you"
                    )
                    VoiceGuideButton {
                        navigationPath.append(AIMode.scene)
                    }
                    FeatureGrid { mode in
                        navigationPath.append(mode)
                    }
                    ActivityTimeline(
                        sessions: viewModel.recentSessions,
                        isLoading: viewModel.isLoading
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationDestination(for: AIMode.self) { mode in
                featureView(for: mode)
            }
            .task {
                await viewModel.loadRecentActivity()
                await viewModel.checkActiveSession()
            }
            .refreshable {
                await viewModel.loadRecentActivity()
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hi there")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("EyeGuide AI is ready")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome. EyeGuide AI is ready.")
    }

    @ViewBuilder
    private func featureView(for mode: AIMode) -> some View {
        switch mode {
        case .scene: SceneDescriptionView()
        case .readText: TextReaderView()
        case .findObject: ObjectFinderView()
        case .social: SocialAssistView()
        }
    }
}
