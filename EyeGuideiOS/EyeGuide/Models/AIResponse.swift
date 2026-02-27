import Foundation

struct GeminiResponse: Codable, Sendable {
    let result: GeminiResult
}

struct GeminiResult: Codable, Sendable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable, Sendable {
    let content: GeminiContent?
    let finishReason: String?
}

struct GeminiContent: Codable, Sendable {
    let parts: [GeminiPart]?
    let role: String?
}

struct GeminiPart: Codable, Sendable {
    let text: String?
}

struct ConversationEntry: Codable, Sendable {
    let role: String
    let text: String
}

extension GeminiResponse {
    var textContent: String {
        guard let candidates = result.candidates,
              let firstCandidate = candidates.first,
              let content = firstCandidate.content,
              let parts = content.parts,
              let firstPart = parts.first,
              let text = firstPart.text else {
            return ""
        }
        return text
    }
}
