package com.ZacharyZhang.eyeguide.data.repository

import com.ZacharyZhang.eyeguide.data.model.DeleteResponse
import com.ZacharyZhang.eyeguide.data.model.PreferenceUpdateRequest
import com.ZacharyZhang.eyeguide.data.model.RegisterRequest
import com.ZacharyZhang.eyeguide.data.model.UserPreference
import com.ZacharyZhang.eyeguide.data.model.UserWithPreferences
import com.ZacharyZhang.eyeguide.data.remote.EyeGuideApi
import com.ZacharyZhang.eyeguide.util.DeviceIdManager
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserRepository @Inject constructor(
    private val api: EyeGuideApi,
    private val deviceIdManager: DeviceIdManager,
) {
    suspend fun registerOrLogin(): Result<UserWithPreferences> = runCatching {
        val deviceId = deviceIdManager.getOrCreateDeviceId()
        api.register(RegisterRequest(deviceId))
    }

    suspend fun getMe(): Result<UserWithPreferences> = runCatching {
        api.getMe()
    }

    suspend fun updatePreferences(request: PreferenceUpdateRequest): Result<UserPreference> =
        runCatching {
            api.updatePreferences(request).preferences
        }

    suspend fun deleteAccount(): Result<DeleteResponse> = runCatching {
        val result = api.deleteAccount()
        deviceIdManager.clearDeviceId()
        result
    }
}
