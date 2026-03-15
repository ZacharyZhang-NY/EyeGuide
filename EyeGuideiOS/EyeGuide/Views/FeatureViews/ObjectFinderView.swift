import SwiftUI

struct ObjectFinderView: View {
    @State private var viewModel = CameraViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cameraCard
                if !viewModel.objectQuery.isEmpty {
                    searchStatusCard
                }
                if !viewModel.aiResult.isEmpty {
                    resultCard
                }
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }
                controlsSection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Locate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.cameraService.requestAuthorization()
            if viewModel.cameraService.isAuthorized {
                viewModel.cameraService.startSession()
            }
            let authorized = await viewModel.speechService.requestSpeechAuthorization()
            viewModel.aiMode = .findObject
            if authorized {
                viewModel.speechService.speak("What are you looking for? Say the object name.")
                while viewModel.speechService.isSpeaking {
                    try? await Task.sleep(for: .milliseconds(200))
                }
                try? await Task.sleep(for: .milliseconds(500))
                try? viewModel.speechService.startListening()
            }
        }
        .onDisappear {
            viewModel.stopAutoAnalysis()
            viewModel.cameraService.stopSession()
            viewModel.speechService.stopListening()
            viewModel.speechService.stopSpeaking()
        }
        .onChange(of: viewModel.errorMessage) { _, newError in
            if let error = newError {
                UIAccessibility.post(notification: .announcement, argument: error)
            }
        }
    }

    // MARK: - Camera

    private var cameraCard: some View {
        ZStack {
            if viewModel.cameraService.isAuthorized {
                if let frame = viewModel.cameraService.latestFrame {
                    Image(uiImage: frame)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                        .accessibilityHidden(true)
                } else {
                    Color(.systemGray6)
                        .frame(height: 250)
                        .overlay {
                            ProgressView()
                                .accessibilityLabel("Starting camera")
                        }
                }
            } else {
                Color(.systemGray6)
                    .frame(height: 250)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text("Camera access required")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Camera access required. Open device Settings to enable camera.")
            }

            if viewModel.isAnalyzing {
                Color.black.opacity(0.3)
                    .frame(height: 250)
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
                    .accessibilityLabel("Searching for \(viewModel.objectQuery)")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - Search Status

    private var searchStatusCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.82, green: 0.96, blue: 0.33).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "scope")
                    .foregroundStyle(Color(red: 0.82, green: 0.96, blue: 0.33))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Looking for")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.objectQuery)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            Spacer()
            if viewModel.isAutoAnalyzing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Searching for \(viewModel.objectQuery)\(viewModel.isAutoAnalyzing ? ", scanning" : "")")
    }

    // MARK: - Result

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Result")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(viewModel.aiResult)
                .font(.body)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .accessibilityLabel("Search result: \(viewModel.aiResult)")
    }

    // MARK: - Error

    private func errorBanner(_ error: String) -> some View {
        Text(error)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel("Error: \(error)")
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: 16) {
            Button {
                HapticService.impact()
                toggleVoiceInput()
            } label: {
                HStack {
                    Image(systemName: viewModel.speechService.isListening ? "stop.fill" : "mic.fill")
                        .font(.title3)
                    Text(viewModel.speechService.isListening ? "Stop Listening" : "Say What to Find")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(viewModel.speechService.isListening ? .white : Color(uiColor: .systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.speechService.isListening ? Color.red : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .accessibilityLabel(viewModel.speechService.isListening ? "Stop listening" : "Say what to find")
            .accessibilityHint(viewModel.speechService.isListening ? "Stops recording and starts searching" : "Starts listening for the object name")
        }
    }

    // MARK: - Voice

    private func toggleVoiceInput() {
        if viewModel.speechService.isListening {
            viewModel.speechService.stopListening()
            HapticService.notification(.success)
            let text = viewModel.speechService.recognizedText
            if !text.isEmpty {
                viewModel.objectQuery = text
                viewModel.startAutoAnalysis()
            }
        } else {
            viewModel.stopAutoAnalysis()
            HapticService.notification(.warning)
            try? viewModel.speechService.startListening()
        }
    }
}
