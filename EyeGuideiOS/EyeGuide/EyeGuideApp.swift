import SwiftUI

@main
struct EyeGuideApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isRegistered {
            MainTabView()
        } else {
            ProgressView("Connecting...")
                .task { await appState.register() }
        }
    }
}

@Observable
final class AppState {
    var isRegistered = false
    var user: User?
    var preferences: UserPreference?

    func register() async {
        let deviceId = KeychainService.getOrCreateDeviceId()
        do {
            let response = try await APIService.shared.registerDevice(deviceId: deviceId)
            user = response.user
            preferences = response.preferences
            isRegistered = true
        } catch {
            try? await Task.sleep(for: .seconds(2))
            await register()
        }
    }
}
