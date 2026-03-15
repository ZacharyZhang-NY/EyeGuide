package com.ZacharyZhang.eyeguide.data.local

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

data class LocalActivity(
    val id: String = UUID.randomUUID().toString(),
    val feature: String,
    val timestamp: Long = System.currentTimeMillis(),
    val success: Boolean,
)

@Singleton
class LocalActivityStore @Inject constructor(
    context: Context,
) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("local_activities", Context.MODE_PRIVATE)

    private val maxEntries = 50

    fun save(feature: String, success: Boolean) {
        val activities = load().toMutableList()
        activities.add(
            0,
            LocalActivity(feature = feature, success = success),
        )
        val trimmed = if (activities.size > maxEntries) activities.take(maxEntries) else activities
        val jsonArray = JSONArray()
        trimmed.forEach { activity ->
            val obj = JSONObject().apply {
                put("id", activity.id)
                put("feature", activity.feature)
                put("timestamp", activity.timestamp)
                put("success", activity.success)
            }
            jsonArray.put(obj)
        }
        prefs.edit().putString("activities", jsonArray.toString()).apply()
    }

    fun load(): List<LocalActivity> {
        val json = prefs.getString("activities", null) ?: return emptyList()
        return try {
            val array = JSONArray(json)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                LocalActivity(
                    id = obj.getString("id"),
                    feature = obj.getString("feature"),
                    timestamp = obj.getLong("timestamp"),
                    success = obj.getBoolean("success"),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
