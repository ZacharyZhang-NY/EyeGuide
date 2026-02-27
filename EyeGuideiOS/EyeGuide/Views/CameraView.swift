import SwiftUI

struct CameraView: View {
    @State private var viewModel = CameraViewModel()
    @State private var showObjectInput = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                cameraPreview
                controlPanel
            }
        }
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
    }

    private var cameraPreview: some View {
        ZStack {
            if viewModel.cameraService.isAuthorized {
                if let frame = viewModel.cameraService.latestFrame {
                    Image(uiImage: frame)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    Color.black
                    ProgressView()
                        .tint(.white)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                    Text("Camera access required")
                        .foregroundStyle(.white)
                    Text("Enable camera in Settings")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            if !viewModel.aiResult.isEmpty {
                VStack {
                    Spacer()
                    Text(viewModel.aiResult)
                        .font(.subheadline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                }
            }

            if viewModel.isAnalyzing {
                Color.black.opacity(0.3)
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controlPanel: some View {
        VStack(spacing: 16) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Picker("Mode", selection: $viewModel.aiMode) {
                ForEach(AIMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if viewModel.aiMode == .findObject {
                TextField("What to find?", text: $viewModel.objectQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }

            HStack(spacing: 32) {
                Button {
                    Task { await viewModel.analyzeCurrentFrame() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.82, green: 0.96, blue: 0.33))
                            .frame(width: 64, height: 64)
                        Image(systemName: "eye.fill")
                            .font(.title2)
                            .foregroundStyle(.black)
                    }
                }
                .disabled(viewModel.isAnalyzing)
                .accessibilityLabel("Analyze scene")

                Button {
                    toggleVoiceInput()
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.speechService.isListening ? Color.red : Color.white)
                            .frame(width: 64, height: 64)
                        Image(systemName: viewModel.speechService.isListening ? "stop.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundStyle(.black)
                    }
                }
                .accessibilityLabel(viewModel.speechService.isListening ? "Stop listening" : "Start voice input")
            }
            .padding(.bottom, 16)
        }
        .padding(.top, 12)
        .background(Color(uiColor: .systemBackground))
    }

    private func toggleVoiceInput() {
        if viewModel.speechService.isListening {
            viewModel.speechService.stopListening()
            let text = viewModel.speechService.recognizedText
            if !text.isEmpty {
                Task { await viewModel.sendVoiceMessage(text) }
            }
        } else {
            try? viewModel.speechService.startListening()
        }
    }
}
