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
                    .accessibilityLabel("Speech Speed")
                    .accessibilityValue("\(String(format: "%.1f", viewModel.voiceSpeed))x")

                    VStack(alignment: .leading) {
                        Text("Pitch: \(viewModel.voicePitch, specifier: "%.1f")")
                        Slider(value: $viewModel.voicePitch, in: 0.5...2.0, step: 0.1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Voice Pitch")
                    .accessibilityValue(String(format: "%.1f", viewModel.voicePitch))
                }

                Section("Description") {
                    Picker("Detail Level", selection: $viewModel.descriptionDetail) {
                        Text("Concise").tag("concise")
                        Text("Standard").tag("standard")
                        Text("Detailed").tag("detailed")
                    }
                    .accessibilityHint("Select how detailed AI descriptions should be")
                }

                Section("Language") {
                    Picker("Language", selection: $viewModel.language) {
                        Text("Chinese").tag("zh-CN")
                        Text("English").tag("en-US")
                    }
                    .accessibilityHint("Select the app language")
                }

                Section("Accessibility") {
                    Toggle("Vibration Feedback", isOn: $viewModel.vibrationEnabled)
                        .accessibilityHint(viewModel.vibrationEnabled ? "Currently on" : "Currently off")
                    Toggle("High Contrast", isOn: $viewModel.highContrastEnabled)
                        .accessibilityHint(viewModel.highContrastEnabled ? "Currently on" : "Currently off")
                }

                Section {
                    Button {
                        HapticService.impact()
                        Task {
                            if let prefs = await viewModel.savePreferences() {
                                appState.preferences = prefs
                                HapticService.notification(.success)
                                UIAccessibility.post(
                                    notification: .announcement,
                                    argument: "Settings saved successfully"
                                )
                            } else {
                                HapticService.notification(.error)
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .accessibilityLabel("Saving settings")
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
                            .accessibilityLabel("Error: \(error)")
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
