import AVFoundation
import Speech
import Observation

@Observable
final class SpeechService {
    var isListening = false
    var recognizedText = ""
    var isSpeaking = false

    var voiceSpeed: Float = 1.0
    var voicePitch: Float = 1.0
    var language: String = "en-US"

    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var recognizer: SFSpeechRecognizer?
    @ObservationIgnored private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var recognitionTask: SFSpeechRecognitionTask?
    @ObservationIgnored private let audioEngine = AVAudioEngine()

    func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * voiceSpeed
        utterance.pitchMultiplier = voicePitch
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        isSpeaking = true
        synthesizer.speak(utterance)

        Task { [weak self] in
            guard let self else { return }
            while self.synthesizer.isSpeaking {
                try? await Task.sleep(for: .milliseconds(100))
            }
            self.isSpeaking = false
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    func startListening() throws {
        stopListening()

        recognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognizer, recognizer.isAvailable,
              let recognitionRequest else {
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true

        recognitionTask = recognizer.recognitionTask(
            with: recognitionRequest
        ) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopListening()
                }
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
}
