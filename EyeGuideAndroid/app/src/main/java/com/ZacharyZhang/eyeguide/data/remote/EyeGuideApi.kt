package com.ZacharyZhang.eyeguide.data.remote

import com.ZacharyZhang.eyeguide.data.model.AIResultResponse
import com.ZacharyZhang.eyeguide.data.model.ConversationRequest
import com.ZacharyZhang.eyeguide.data.model.CreateSessionRequest
import com.ZacharyZhang.eyeguide.data.model.DeleteResponse
import com.ZacharyZhang.eyeguide.data.model.FindObjectRequest
import com.ZacharyZhang.eyeguide.data.model.PreferenceResponse
import com.ZacharyZhang.eyeguide.data.model.PreferenceUpdateRequest
import com.ZacharyZhang.eyeguide.data.model.ReadTextRequest
import com.ZacharyZhang.eyeguide.data.model.RecordUsageRequest
import com.ZacharyZhang.eyeguide.data.model.RegisterRequest
import com.ZacharyZhang.eyeguide.data.model.SceneRequest
import com.ZacharyZhang.eyeguide.data.model.SessionListResponse
import com.ZacharyZhang.eyeguide.data.model.SessionResponse
import com.ZacharyZhang.eyeguide.data.model.SocialRequest
import com.ZacharyZhang.eyeguide.data.model.UsageListResponse
import com.ZacharyZhang.eyeguide.data.model.UsageStatResponse
import com.ZacharyZhang.eyeguide.data.model.UsageSummaryResponse
import com.ZacharyZhang.eyeguide.data.model.UserWithPreferences
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface EyeGuideApi {

    @POST("api/users/register")
    suspend fun register(@Body body: RegisterRequest): UserWithPreferences

    @GET("api/users/me")
    suspend fun getMe(): UserWithPreferences

    @PATCH("api/users/me/preferences")
    suspend fun updatePreferences(@Body body: PreferenceUpdateRequest): PreferenceResponse

    @DELETE("api/users/me")
    suspend fun deleteAccount(): DeleteResponse

    @POST("api/sessions")
    suspend fun createSession(@Body body: CreateSessionRequest): SessionResponse

    @PATCH("api/sessions/{id}/end")
    suspend fun endSession(@Path("id") sessionId: String): SessionResponse

    @GET("api/sessions")
    suspend fun getSessions(
        @Query("limit") limit: Int = 20,
        @Query("offset") offset: Int = 0,
    ): SessionListResponse

    @GET("api/sessions/active")
    suspend fun getActiveSession(): SessionResponse

    @POST("api/usage")
    suspend fun recordUsage(@Body body: RecordUsageRequest): UsageStatResponse

    @GET("api/usage")
    suspend fun getUsage(
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("feature") feature: String? = null,
    ): UsageListResponse

    @GET("api/usage/summary")
    suspend fun getUsageSummary(): UsageSummaryResponse

    @POST("api/ai/scene")
    suspend fun analyzeScene(@Body body: SceneRequest): AIResultResponse

    @POST("api/ai/read-text")
    suspend fun readText(@Body body: ReadTextRequest): AIResultResponse

    @POST("api/ai/conversation")
    suspend fun conversation(@Body body: ConversationRequest): AIResultResponse

    @POST("api/ai/find-object")
    suspend fun findObject(@Body body: FindObjectRequest): AIResultResponse

    @POST("api/ai/social")
    suspend fun analyzeSocial(@Body body: SocialRequest): AIResultResponse
}
