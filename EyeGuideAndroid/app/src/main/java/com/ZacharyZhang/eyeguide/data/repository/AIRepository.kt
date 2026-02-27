package com.ZacharyZhang.eyeguide.data.repository

import com.ZacharyZhang.eyeguide.data.model.AIResultResponse
import com.ZacharyZhang.eyeguide.data.model.ConversationEntry
import com.ZacharyZhang.eyeguide.data.model.ConversationRequest
import com.ZacharyZhang.eyeguide.data.model.FindObjectRequest
import com.ZacharyZhang.eyeguide.data.model.ReadTextRequest
import com.ZacharyZhang.eyeguide.data.model.RecordUsageRequest
import com.ZacharyZhang.eyeguide.data.model.SceneRequest
import com.ZacharyZhang.eyeguide.data.model.SocialRequest
import com.ZacharyZhang.eyeguide.data.model.UsageListResponse
import com.ZacharyZhang.eyeguide.data.model.UsageSummaryResponse
import com.ZacharyZhang.eyeguide.data.remote.EyeGuideApi
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AIRepository @Inject constructor(
    private val api: EyeGuideApi,
) {
    suspend fun analyzeScene(
        image: String,
        detailLevel: String = "standard",
        language: String = "zh-CN",
    ): Result<AIResultResponse> = runCatching {
        api.analyzeScene(SceneRequest(image, detailLevel, language))
    }

    suspend fun readText(image: String, language: String = "zh-CN"): Result<AIResultResponse> =
        runCatching {
            api.readText(ReadTextRequest(image, language))
        }

    suspend fun conversation(
        message: String,
        image: String? = null,
        history: List<ConversationEntry> = emptyList(),
        language: String = "zh-CN",
    ): Result<AIResultResponse> = runCatching {
        api.conversation(ConversationRequest(message, image, history, language))
    }

    suspend fun findObject(
        image: String,
        targetObject: String,
        language: String = "zh-CN",
    ): Result<AIResultResponse> = runCatching {
        api.findObject(FindObjectRequest(image, targetObject, language))
    }

    suspend fun analyzeSocial(
        image: String,
        language: String = "zh-CN",
    ): Result<AIResultResponse> = runCatching {
        api.analyzeSocial(SocialRequest(image, language))
    }

    suspend fun recordUsage(
        feature: String,
        success: Boolean,
        errorMessage: String? = null,
    ): Result<Unit> = runCatching {
        api.recordUsage(RecordUsageRequest(feature, success = success, errorMessage = errorMessage))
    }

    suspend fun getUsage(limit: Int = 50, offset: Int = 0): Result<UsageListResponse> =
        runCatching { api.getUsage(limit, offset) }

    suspend fun getUsageSummary(): Result<UsageSummaryResponse> =
        runCatching { api.getUsageSummary() }
}
