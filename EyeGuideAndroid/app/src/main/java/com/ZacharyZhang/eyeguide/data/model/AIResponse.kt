package com.ZacharyZhang.eyeguide.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SceneRequest(
    val image: String,
    @SerialName("detail_level") val detailLevel: String = "standard",
    val language: String = "zh-CN",
)

@Serializable
data class ReadTextRequest(
    val image: String,
    val language: String = "zh-CN",
)

@Serializable
data class ConversationEntry(
    val role: String,
    val text: String,
)

@Serializable
data class ConversationRequest(
    val message: String,
    val image: String? = null,
    @SerialName("conversation_history") val conversationHistory: List<ConversationEntry> = emptyList(),
    val language: String = "zh-CN",
)

@Serializable
data class FindObjectRequest(
    val image: String,
    @SerialName("target_object") val targetObject: String,
    val language: String = "zh-CN",
)

@Serializable
data class SocialRequest(
    val image: String,
    val language: String = "zh-CN",
)

@Serializable
data class GeminiPart(
    val text: String? = null,
)

@Serializable
data class GeminiContent(
    val parts: List<GeminiPart> = emptyList(),
)

@Serializable
data class GeminiCandidate(
    val content: GeminiContent? = null,
    val finishReason: String? = null,
)

@Serializable
data class GeminiResult(
    val candidates: List<GeminiCandidate> = emptyList(),
)

@Serializable
data class AIResultResponse(
    val result: GeminiResult? = null,
    val error: String? = null,
)

fun AIResultResponse.extractText(): String {
    if (error != null) return error
    val text = result?.candidates?.firstOrNull()?.content?.parts?.firstOrNull()?.text
    return text ?: "No response received"
}
