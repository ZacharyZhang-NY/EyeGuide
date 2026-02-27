package com.ZacharyZhang.eyeguide.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: String,
    @SerialName("device_id") val deviceId: String,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
)

@Serializable
data class UserPreference(
    val id: String,
    @SerialName("user_id") val userId: String,
    @SerialName("voice_speed") val voiceSpeed: Float = 1.0f,
    @SerialName("voice_pitch") val voicePitch: Float = 1.0f,
    @SerialName("description_detail") val descriptionDetail: String = "standard",
    val language: String = "en",
    @SerialName("vibration_enabled") val vibrationEnabled: Boolean = true,
    @SerialName("high_contrast_enabled") val highContrastEnabled: Boolean = false,
    @SerialName("enabled_features") val enabledFeatures: List<String> = emptyList(),
    @SerialName("emergency_contact") val emergencyContact: String? = null,
)

@Serializable
data class UserWithPreferences(
    val user: User,
    val preferences: UserPreference? = null,
)

@Serializable
data class RegisterRequest(
    @SerialName("device_id") val deviceId: String,
)

@Serializable
data class PreferenceUpdateRequest(
    @SerialName("voice_speed") val voiceSpeed: Float? = null,
    @SerialName("voice_pitch") val voicePitch: Float? = null,
    @SerialName("description_detail") val descriptionDetail: String? = null,
    val language: String? = null,
    @SerialName("vibration_enabled") val vibrationEnabled: Boolean? = null,
    @SerialName("high_contrast_enabled") val highContrastEnabled: Boolean? = null,
    @SerialName("enabled_features") val enabledFeatures: List<String>? = null,
    @SerialName("emergency_contact") val emergencyContact: String? = null,
)

@Serializable
data class PreferenceResponse(
    val preferences: UserPreference,
)

@Serializable
data class DeleteResponse(
    val success: Boolean,
)
