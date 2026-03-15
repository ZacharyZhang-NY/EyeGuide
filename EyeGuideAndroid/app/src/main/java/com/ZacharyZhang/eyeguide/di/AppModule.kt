package com.ZacharyZhang.eyeguide.di

import android.content.Context
import com.ZacharyZhang.eyeguide.data.local.LocalActivityStore
import com.ZacharyZhang.eyeguide.util.DeviceIdManager
import com.ZacharyZhang.eyeguide.util.SpeechHelper
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDeviceIdManager(@ApplicationContext context: Context): DeviceIdManager {
        return DeviceIdManager(context)
    }

    @Provides
    @Singleton
    fun provideSpeechHelper(@ApplicationContext context: Context): SpeechHelper {
        return SpeechHelper(context)
    }

    @Provides
    @Singleton
    fun provideLocalActivityStore(@ApplicationContext context: Context): LocalActivityStore {
        return LocalActivityStore(context)
    }
}
