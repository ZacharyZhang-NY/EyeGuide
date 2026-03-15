import Foundation
import Observation
import UIKit

enum AIMode: String, CaseIterable, Hashable {
    case scene = "Scene"
    case readText = "Read"
    case findObject = "Find"
    case social = "Social"

    var usageFeatureName: String {
        switch self {
        case .scene: "scene_description"
        case .readText: "text_reading"
        case .findObject: "object_recognition"
        case .social: "social_assistant"
        }
    }
}

@Observable
final class CameraViewModel {
    var aiMode: AIMode = .scene
    var aiResult = ""
    var isAnalyzing = false
    var errorMessage: String?
    var objectQuery = ""
    var conversationHistory: [ConversationEntry] = []
    var isAutoAnalyzing = false

    @ObservationIgnored private var autoAnalysisTask: Task<Void, Never>?
    @ObservationIgnored private var frameStreamTask: Task<Void, Never>?
    @ObservationIgnored private let liveService = GeminiLiveService()

    let cameraService = CameraService()
    let speechService = SpeechService()

    // MARK: - Live API

    func startAutoAnalysis() {
        guard !isAutoAnalyzing else { return }
        isAutoAnalyzing = true

        autoAnalysisTask = Task { [weak self] in
            guard let self else { return }

            do {
                let config = try await APIService.shared.getAIConfig()
                guard !Task.isCancelled else { return }

                let systemPrompt = self.systemPromptForMode(self.aiMode)

                var wsConnected = false

                self.liveService.connect(
                    config: GeminiLiveService.Config(
                        apiKey: config.apiKey,
                        model: config.model,
                        wsBaseURL: config.wsUrl,
                        systemPrompt: systemPrompt,
                        temperature: 0.2
                    ),
                    onTextUpdate: { [weak self] text in
                        self?.aiResult = text
                    },
                    onTurnComplete: { [weak self] text in
                        guard let self, !text.isEmpty else { return }
                        self.aiResult = text
                        self.speechService.speak(text)
                    },
                    onError: { [weak self] error in
                        guard let self, wsConnected else { return }
                        self.errorMessage = error
                    }
                )

                // Wait for WebSocket connection
                var waited = 0
                while !self.liveService.isConnected && !Task.isCancelled && waited < 50 {
                    try await Task.sleep(for: .milliseconds(100))
                    waited += 1
                }

                guard self.liveService.isConnected, !Task.isCancelled else {
                    self.liveService.disconnect()
                    await MainActor.run { self.startHTTPAutoAnalysis() }
                    return
                }

                wsConnected = true

                // Stream camera frames at ~1 FPS
                self.frameStreamTask = Task { [weak self] in
                    while !Task.isCancelled {
                        if let base64 = self?.cameraService.captureCurrentFrame() {
                            self?.liveService.sendFrame(base64)
                        }
                        try? await Task.sleep(for: .seconds(1))
                    }
                }

                // Let initial frames arrive
                try await Task.sleep(for: .seconds(2))

                // Periodically prompt for analysis
                while !Task.isCancelled && self.isAutoAnalyzing {
                    let prompt = self.analysisPromptForMode(self.aiMode)
                    self.liveService.sendText(prompt)

                    // Wait for speech to finish
                    while self.speechService.isSpeaking && !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(300))
                    }

                    guard !Task.isCancelled && self.isAutoAnalyzing else { break }
                    try? await Task.sleep(for: .seconds(3))
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.startHTTPAutoAnalysis()
                }
            }
        }
    }

    func stopAutoAnalysis() {
        isAutoAnalyzing = false
        autoAnalysisTask?.cancel()
        frameStreamTask?.cancel()
        autoAnalysisTask = nil
        frameStreamTask = nil
        liveService.disconnect()
    }

    func sendVoiceMessage(_ text: String) async {
        if liveService.isConnected {
            liveService.sendText(text)
            conversationHistory.append(ConversationEntry(role: "user", text: text))
        } else {
            await sendVoiceMessageHTTP(text)
        }
    }

    // MARK: - HTTP Fallback

    private func startHTTPAutoAnalysis() {
        guard isAutoAnalyzing else { return }
        autoAnalysisTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(1))

            while !Task.isCancelled && self.isAutoAnalyzing {
                await self.analyzeCurrentFrame()

                while self.speechService.isSpeaking && !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(300))
                }

                guard !Task.isCancelled && self.isAutoAnalyzing else { break }
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func analyzeCurrentFrame() async {
        guard let base64 = cameraService.captureCurrentFrame() else {
            errorMessage = "No camera frame available"
            return
        }

        isAnalyzing = true
        errorMessage = nil

        do {
            let response: GeminiResponse
            let api = APIService.shared
            switch aiMode {
            case .scene:
                response = try await api.analyzeScene(imageBase64: base64)
            case .readText:
                response = try await api.readText(imageBase64: base64)
            case .findObject:
                guard !objectQuery.isEmpty else {
                    errorMessage = "Please specify what to find"
                    isAnalyzing = false
                    return
                }
                response = try await api.findObject(
                    imageBase64: base64, targetObject: objectQuery
                )
            case .social:
                response = try await api.analyzeSocial(imageBase64: base64)
            }

            let text = response.textContent
            aiResult = text
            speechService.speak(text)
            HapticService.notification(.success)
            LocalActivityStore.shared.save(feature: aiMode.usageFeatureName, success: true)
        } catch {
            errorMessage = error.localizedDescription
            HapticService.notification(.error)
            LocalActivityStore.shared.save(feature: aiMode.usageFeatureName, success: false)
        }

        isAnalyzing = false
    }

    private func sendVoiceMessageHTTP(_ text: String) async {
        let base64 = cameraService.captureCurrentFrame()
        isAnalyzing = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.conversation(
                message: text,
                imageBase64: base64,
                history: conversationHistory
            )

            let resultText = response.textContent
            aiResult = resultText
            conversationHistory.append(ConversationEntry(role: "user", text: text))
            conversationHistory.append(ConversationEntry(role: "model", text: resultText))
            speechService.speak(resultText)
            LocalActivityStore.shared.save(feature: "voice_interaction", success: true)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    // MARK: - Prompts

    private func systemPromptForMode(_ mode: AIMode) -> String {
        switch mode {
        case .scene:
            return
                "You are a real-time blind navigation assistant. Watch the video feed and describe what's ahead: obstacles, vehicles, steps, barriers, and safe paths. Speak like a friend guiding them. Natural speech, under 50 words per response. No lists, JSON, or formatted output."
        case .readText:
            return
                "You are a text reading assistant for blind people. Read all visible text in the video feed from top to bottom. Just read the text content naturally. No extra explanations."
        case .social:
            return
                "You are a social assistant for blind people. Describe people visible in the video: how many, what they're doing, expressions, body language. Natural concise speech, under 50 words per response."
        case .findObject:
            return
                "You are an object finding assistant for blind people. Help locate specific objects in the video feed. Describe direction (left, right, ahead, above, below) and approximate distance. Natural speech."
        }
    }

    private func analysisPromptForMode(_ mode: AIMode) -> String {
        switch mode {
        case .scene: return "What's ahead? Any dangers or obstacles?"
        case .readText: return "Read any visible text."
        case .social: return "Describe the people you see."
        case .findObject: return "Where is \(objectQuery)?"
        }
    }
}
