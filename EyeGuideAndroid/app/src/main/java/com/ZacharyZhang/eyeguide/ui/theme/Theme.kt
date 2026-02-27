package com.ZacharyZhang.eyeguide.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColorScheme = lightColorScheme(
    primary = EyeGuideLavender,
    onPrimary = EyeGuideInk,
    primaryContainer = EyeGuideLavenderLight,
    onPrimaryContainer = EyeGuideInk,
    secondary = EyeGuideLime,
    onSecondary = EyeGuideInk,
    secondaryContainer = EyeGuideLime,
    onSecondaryContainer = EyeGuideInk,
    tertiary = EyeGuideSecondary,
    onTertiary = EyeGuideWhite,
    background = EyeGuideBackground,
    onBackground = EyeGuideInk,
    surface = EyeGuideSurface,
    onSurface = EyeGuideInk,
    surfaceVariant = Color(0xFFE8E8ED),
    onSurfaceVariant = EyeGuideSecondary,
    error = EyeGuideError,
    onError = EyeGuideWhite,
)

private val DarkColorScheme = darkColorScheme(
    primary = EyeGuideLavenderDark,
    onPrimary = EyeGuideWhite,
    primaryContainer = Color(0xFF3D3555),
    onPrimaryContainer = EyeGuideLavender,
    secondary = EyeGuideLimeDark,
    onSecondary = EyeGuideInk,
    secondaryContainer = Color(0xFF3D4420),
    onSecondaryContainer = EyeGuideLime,
    tertiary = EyeGuideSecondary,
    onTertiary = EyeGuideWhite,
    background = EyeGuideBackgroundDark,
    onBackground = EyeGuideWhite,
    surface = EyeGuideSurfaceDark,
    onSurface = EyeGuideWhite,
    surfaceVariant = Color(0xFF3A3A3C),
    onSurfaceVariant = EyeGuideSecondary,
    error = EyeGuideError,
    onError = EyeGuideWhite,
)

@Composable
fun EyeGuideTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    val view = LocalView.current

    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            @Suppress("DEPRECATION")
            window.statusBarColor = colorScheme.background.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content,
    )
}
