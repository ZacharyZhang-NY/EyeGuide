package com.ZacharyZhang.eyeguide.ui.home.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.ZacharyZhang.eyeguide.data.model.UsageStat
import com.ZacharyZhang.eyeguide.ui.theme.EyeGuideSuccess
import com.ZacharyZhang.eyeguide.ui.theme.EyeGuideError

private fun featureDisplayName(feature: String): String = when (feature) {
    "scene_description" -> "Scene Analysis"
    "text_reading" -> "Text Reading"
    "object_recognition" -> "Object Detection"
    "social_assistant" -> "Social Context"
    "voice_interaction" -> "Voice Chat"
    "navigation" -> "Navigation"
    else -> feature.replace("_", " ").replaceFirstChar { it.uppercase() }
}

@Composable
fun ActivityTimeline(
    activities: List<UsageStat>,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = "Recent Activity",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground,
        )
        Spacer(modifier = Modifier.height(12.dp))
        if (activities.isEmpty()) {
            Text(
                text = "No recent activity",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.semantics {
                    contentDescription = "No recent activity recorded"
                },
            )
        } else {
            activities.forEach { stat ->
                ActivityTimelineItem(stat = stat)
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun ActivityTimelineItem(
    stat: UsageStat,
    modifier: Modifier = Modifier,
) {
    val displayName = featureDisplayName(stat.feature)
    val statusText = if (stat.success) "Completed" else "Failed"
    val time = stat.timestamp.substringAfter("T").take(5)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surface)
            .padding(12.dp)
            .semantics {
                contentDescription = "$displayName $statusText at $time"
            },
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(10.dp)
                .clip(CircleShape)
                .background(if (stat.success) EyeGuideSuccess else EyeGuideError),
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = displayName,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface,
            )
            Text(
                text = statusText,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Text(
            text = time,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
