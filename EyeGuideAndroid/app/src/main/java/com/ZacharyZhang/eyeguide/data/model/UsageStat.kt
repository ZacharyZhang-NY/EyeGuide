package com.ZacharyZhang.eyeguide.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class UsageStat(
    val id: String,
    @SerialName("user_id") val userId: String,
    val feature: String,
    val timestamp: String,
    val duration: Int? = null,
    val success: Boolean,
    @SerialName("error_message") val errorMessage: String? = null,
)

@Serializable
data class RecordUsageRequest(
    val feature: String,
    val duration: Int? = null,
    val success: Boolean,
    @SerialName("error_message") val errorMessage: String? = null,
)

@Serializable
data class UsageStatResponse(
    val stat: UsageStat,
)

@Serializable
data class UsageListResponse(
    val stats: List<UsageStat>,
    val total: Int,
    val limit: Int,
    val offset: Int,
)

@Serializable
data class UsageSummaryItem(
    val feature: String,
    @SerialName("total_uses") val totalUses: Int,
    @SerialName("successful_uses") val successfulUses: Int,
    @SerialName("avg_duration") val avgDuration: Double,
)

@Serializable
data class UsageSummaryResponse(
    val summary: List<UsageSummaryItem>,
)
