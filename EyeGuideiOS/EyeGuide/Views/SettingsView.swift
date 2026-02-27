import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Voice") {
                    VStack(alignment: .leading) {
                        Text("Speech Speed: \(viewModel.voiceSpeed, specifier: "%.1f")x")
                        Slider(value: $viewModel.voiceSpeed, in: 0.5...2.0, step: 0.1)
                    }
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading) {
                        Text("Pitch: \(viewModel.voicePitch, specifier: "%.1f")")
                        Slider(value: $viewModel.voicePitch, in: 0.5...2.0, step: 0.1)
                    }
                    .accessibilityElement(children: .combine)
                }

                Section("Description") {
                    Picker("Detail Level", selection: $viewModel.descriptionDetail) {
                        Text("Concise").tag("concise")
                        Text("Standard").tag("standard")
                        Text("Detailed").tag("detailed")
                    }
                }

                Section("Language") {
                    Picker("Language", selection: $viewModel.language) {
                        Text("Chinese").tag("zh-CN")
                        Text("English").tag("en-US")
                    }
                }

                Section("Accessibility") {
                    Toggle("Vibration Feedback", isOn: $viewModel.vibrationEnabled)
                    Toggle("High Contrast", isOn: $viewModel.highContrastEnabled)
                }

                Section {
                    Button {
                        Task {
                            if let prefs = await viewModel.savePreferences() {
                                appState.preferences = prefs
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Settings")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSaving)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadPreferences(from: appState.preferences)
            }
        }
    }
}
