import SwiftUI

struct CameraView: View {
    @State private var viewModel = CameraViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                cameraCard
                modePicker
                if viewModel.aiMode == .findObject {
                    objectQueryField
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
        .navigationTitle("AI Vision")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.cameraService.requestAuthorization()
            if viewModel.cameraService.isAuthorized {
                viewModel.cameraService.startSession()
            }
            _ = await viewModel.speechService.requestSpeechAuthorization()
        }
        .onDisappear {
            viewModel.cameraService.stopSession()
            viewModel.speechService.stopListening()
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
                    .accessibilityLabel("Analyzing image")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("Mode", selection: $viewModel.aiMode) {
            ForEach(AIMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Analysis mode")
        .accessibilityHint("Choose between Scene, Read, Find, and Social modes")
    }

    // MARK: - Object Query

    private var objectQueryField: some View {
        TextField("What to find?", text: $viewModel.objectQuery)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Object to search for")
            .accessibilityHint("Type or dictate the name of the object you want to find")
    }

    // MARK: - Result

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Result")
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
        .accessibilityLabel("Result: \(viewModel.aiResult)")
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
        HStack(spacing: 16) {
            Button {
                HapticService.impact()
                Task { await viewModel.analyzeCurrentFrame() }
            } label: {
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.title3)
                    Text("Analyze")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.82, green: 0.96, blue: 0.33))
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .disabled(viewModel.isAnalyzing)
            .accessibilityLabel("Analyze scene")
            .accessibilityHint("Captures and analyzes what the camera sees")

            Button {
                HapticService.impact()
                toggleVoiceInput()
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.speechService.isListening ? Color.red : Color.primary)
                        .frame(width: 56, height: 56)
                    Image(systemName: viewModel.speechService.isListening ? "stop.fill" : "mic.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.speechService.isListening ? .white : Color(uiColor: .systemBackground))
                }
            }
            .accessibilityLabel(viewModel.speechService.isListening ? "Stop listening" : "Start voice input")
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
            HapticService.notification(.warning)
            try? viewModel.speechService.startListening()
        }
    }
}
