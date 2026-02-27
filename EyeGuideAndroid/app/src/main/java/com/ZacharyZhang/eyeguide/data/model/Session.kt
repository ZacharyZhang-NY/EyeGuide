package com.ZacharyZhang.eyeguide.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Session(
    val id: String,
    @SerialName("user_id") val userId: String,
    @SerialName("started_at") val startedAt: String,
    @SerialName("ended_at") val endedAt: String? = null,
    val location: String? = null,
    @SerialName("session_type") val sessionType: String,
)

@Serializable
data class CreateSessionRequest(
    @SerialName("session_type") val sessionType: String = "general",
    val location: String? = null,
)

@Serializable
data class SessionResponse(
    val session: Session? = null,
)

@Serializable
data class SessionListResponse(
    val sessions: List<Session>,
    val total: Int,
    val limit: Int,
    val offset: Int,
)
