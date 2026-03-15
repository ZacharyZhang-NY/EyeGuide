import SwiftUI

struct TextReaderView: View {
    @State private var viewModel = CameraViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cameraCard
                statusPill
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
        .navigationTitle("Read")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.cameraService.requestAuthorization()
            if viewModel.cameraService.isAuthorized {
                viewModel.cameraService.startSession()
            }
            _ = await viewModel.speechService.requestSpeechAuthorization()
            viewModel.aiMode = .readText
            viewModel.startAutoAnalysis()
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
                    .accessibilityLabel("Reading text")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - Status

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.isAutoAnalyzing ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)
            Text(viewModel.isAutoAnalyzing ? "Live" : "Paused")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(viewModel.isAutoAnalyzing ? .primary : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .accessibilityLabel(viewModel.isAutoAnalyzing ? "Live text reading active" : "Text reading paused")
    }

    // MARK: - Result

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text Found")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(viewModel.aiResult)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .accessibilityLabel("Text found: \(viewModel.aiResult)")
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
                    Text(viewModel.speechService.isListening ? "Stop Listening" : "Ask a Question")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(viewModel.speechService.isListening ? .white : Color(uiColor: .systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(viewModel.speechService.isListening ? Color.red : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .accessibilityLabel(viewModel.speechService.isListening ? "Stop listening" : "Ask about the text")
            .accessibilityHint(viewModel.speechService.isListening ? "Stops recording and sends your question" : "Starts listening for your voice question")
        }
    }

    // MARK: - Voice

    private func toggleVoiceInput() {
        if viewModel.speechService.isListening {
            viewModel.speechService.stopListening()
            HapticService.notification(.success)
            let text = viewModel.speechService.recognizedText
            if !text.isEmpty {
                Task { await viewModel.sendVoiceMessage(text) }
            }
        } else {
            viewModel.stopAutoAnalysis()
            HapticService.notification(.warning)
            try? viewModel.speechService.startListening()
        }
    }
}
