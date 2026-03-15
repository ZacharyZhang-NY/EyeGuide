import Foundation
import Observation

@Observable
final class GeminiLiveService: NSObject, @unchecked Sendable {
    var isConnected = false

    @ObservationIgnored private var webSocketTask: URLSessionWebSocketTask?
    @ObservationIgnored private var onTextUpdate: ((String) -> Void)?
    @ObservationIgnored private var onTurnComplete: ((String) -> Void)?
    @ObservationIgnored private var onError: ((String) -> Void)?
    @ObservationIgnored private var accumulatedText = ""

    struct Config {
        let apiKey: String
        let model: String
        let wsBaseURL: String
        let systemPrompt: String
        let temperature: Double
    }

    func connect(
        config: Config,
        onTextUpdate: @escaping (String) -> Void,
        onTurnComplete: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        disconnect()

        self.onTextUpdate = onTextUpdate
        self.onTurnComplete = onTurnComplete
        self.onError = onError

        let urlString = "\(config.wsBaseURL)?key=\(config.apiKey)"
        guard let url = URL(string: urlString) else {
            onError("Invalid WebSocket URL")
            return
        }

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        let setup: [String: Any] = [
            "setup": [
                "model": "models/\(config.model)",
                "generationConfig": [
                    "responseModalities": ["TEXT"],
                    "temperature": config.temperature,
                ] as [String: Any],
                "systemInstruction": [
                    "parts": [["text": config.systemPrompt]],
                ],
            ] as [String: Any],
        ]

        sendJSON(setup)
        receiveMessage()
    }

    func sendFrame(_ base64Image: String) {
        guard isConnected else { return }
        let message: [String: Any] = [
            "realtimeInput": [
                "mediaChunks": [
                    [
                        "mimeType": "image/jpeg",
                        "data": base64Image,
                    ],
                ],
            ],
        ]
        sendJSON(message)
    }

    func sendText(_ text: String) {
        guard isConnected else { return }
        let message: [String: Any] = [
            "clientContent": [
                "turns": [
                    [
                        "role": "user",
                        "parts": [["text": text]],
                    ] as [String: Any],
                ],
                "turnComplete": true,
            ] as [String: Any],
        ]
        sendJSON(message)
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        accumulatedText = ""
        let strongSelf = self
        Task { @MainActor in
            strongSelf.isConnected = false
        }
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
            let string = String(data: data, encoding: .utf8)
        else { return }
        webSocketTask?.send(.string(string)) { [weak self] error in
            if let error, let self {
                let callback = self.onError
                Task { @MainActor in
                    callback?("Send error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage()
            case .failure(let error):
                let strongSelf = self
                let callback = self.onError
                Task { @MainActor in
                    strongSelf.isConnected = false
                    callback?("Connection lost: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        if json["setupComplete"] != nil {
            let strongSelf = self
            Task { @MainActor in
                strongSelf.isConnected = true
            }
            return
        }

        if let serverContent = json["serverContent"] as? [String: Any] {
            if let modelTurn = serverContent["modelTurn"] as? [String: Any],
                let parts = modelTurn["parts"] as? [[String: Any]]
            {
                for part in parts {
                    if let partText = part["text"] as? String {
                        accumulatedText += partText
                    }
                }
                let current = accumulatedText
                let textCallback = onTextUpdate
                Task { @MainActor in
                    textCallback?(current)
                }
            }

            if serverContent["turnComplete"] as? Bool == true {
                let finalText = accumulatedText
                accumulatedText = ""
                let completeCallback = onTurnComplete
                Task { @MainActor in
                    completeCallback?(finalText)
                }
            }
        }
    }
}
