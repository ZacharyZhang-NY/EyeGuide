import SwiftUI

struct ObjectFinderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CameraViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Go back")
                    Spacer()
                    Text("Object Finder")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Spacer().frame(width: 60)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                cameraPreview
                bottomPanel
            }
        }
        .navigationBarBackButtonHidden(true)
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
                    ProgressView().tint(.white)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                    Text("Camera access required")
                        .foregroundStyle(.white)
                }
            }

            if !viewModel.aiResult.isEmpty {
                VStack {
                    Spacer()
                    Text(viewModel.aiResult)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomPanel: some View {
        VStack(spacing: 16) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            if !viewModel.objectQuery.isEmpty {
                Text("Looking for: \(viewModel.objectQuery)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isAutoAnalyzing {
                Text("Searching for \(viewModel.objectQuery)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
            .accessibilityLabel(viewModel.speechService.isListening ? "Stop listening" : "Say what to find")
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
                viewModel.objectQuery = text
                viewModel.startAutoAnalysis()
            }
        } else {
            viewModel.stopAutoAnalysis()
            try? viewModel.speechService.startListening()
        }
    }
}
