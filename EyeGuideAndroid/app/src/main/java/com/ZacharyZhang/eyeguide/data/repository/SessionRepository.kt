package com.ZacharyZhang.eyeguide.data.repository

import com.ZacharyZhang.eyeguide.data.model.CreateSessionRequest
import com.ZacharyZhang.eyeguide.data.model.Session
import com.ZacharyZhang.eyeguide.data.model.SessionListResponse
import com.ZacharyZhang.eyeguide.data.remote.EyeGuideApi
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SessionRepository @Inject constructor(
    private val api: EyeGuideApi,
) {
    suspend fun createSession(sessionType: String = "general"): Result<Session?> = runCatching {
        api.createSession(CreateSessionRequest(sessionType)).session
    }

    suspend fun endSession(sessionId: String): Result<Session?> = runCatching {
        api.endSession(sessionId).session
    }

    suspend fun getSessions(limit: Int = 20, offset: Int = 0): Result<SessionListResponse> =
        runCatching {
            api.getSessions(limit, offset)
        }

    suspend fun getActiveSession(): Result<Session?> = runCatching {
        api.getActiveSession().session
    }
}
