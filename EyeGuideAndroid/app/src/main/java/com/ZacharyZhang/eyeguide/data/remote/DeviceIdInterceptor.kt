package com.ZacharyZhang.eyeguide.data.remote

import com.ZacharyZhang.eyeguide.util.DeviceIdManager
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DeviceIdInterceptor @Inject constructor(
    private val deviceIdManager: DeviceIdManager,
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()
        val deviceId = deviceIdManager.getDeviceId()

        val request = if (deviceId != null && !original.url.encodedPath.contains("register")) {
            original.newBuilder()
                .header("X-Device-Id", deviceId)
                .build()
        } else {
            original
        }

        return chain.proceed(request)
    }
}
