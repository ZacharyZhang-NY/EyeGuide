package com.ZacharyZhang.eyeguide.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.ZacharyZhang.eyeguide.ui.camera.AIMode
import com.ZacharyZhang.eyeguide.ui.camera.CameraScreen
import com.ZacharyZhang.eyeguide.ui.camera.CameraViewModel
import com.ZacharyZhang.eyeguide.ui.history.HistoryScreen
import com.ZacharyZhang.eyeguide.ui.home.HomeScreen
import com.ZacharyZhang.eyeguide.ui.home.HomeViewModel
import com.ZacharyZhang.eyeguide.ui.home.components.BottomNavBar
import com.ZacharyZhang.eyeguide.ui.settings.SettingsScreen
import com.ZacharyZhang.eyeguide.ui.settings.SettingsViewModel
import com.ZacharyZhang.eyeguide.util.SpeechHelper

object Routes {
    const val HOME = "home"
    const val FEATURES = "features"
    const val HISTORY = "history"
    const val SETTINGS = "settings"
    const val VOICE_GUIDE = "voice_guide"
    const val SCENE = "scene"
    const val READ_TEXT = "read_text"
    const val FIND_OBJECT = "find_object"
    const val SOCIAL = "social"
}

private val tabRoutes = setOf(Routes.HOME, Routes.FEATURES, Routes.HISTORY, Routes.SETTINGS)

@Composable
fun EyeGuideNavigation(
    speechHelper: SpeechHelper,
) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route ?: Routes.HOME

    Scaffold(
        bottomBar = {
            if (currentRoute in tabRoutes) {
                BottomNavBar(
                    currentRoute = currentRoute,
                    onItemClick = { route ->
                        if (route != currentRoute) {
                            navController.navigate(route) {
                                popUpTo(Routes.HOME) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    },
                )
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Routes.HOME,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(Routes.HOME) {
                val viewModel: HomeViewModel = hiltViewModel()
                HomeScreen(
                    viewModel = viewModel,
                    onNavigateToSettings = { navController.navigate(Routes.SETTINGS) },
                    onNavigateToVoiceGuide = { navController.navigate(Routes.VOICE_GUIDE) },
                    onNavigateToFeature = { route -> navController.navigate(route) },
                )
            }

            composable(Routes.FEATURES) {
                val viewModel: CameraViewModel = hiltViewModel()
                CameraScreen(
                    viewModel = viewModel,
                    speechHelper = speechHelper,
                    onBack = { navController.popBackStack() },
                    mode = AIMode.SCENE,
                )
            }

            composable(Routes.HISTORY) {
                HistoryScreen()
            }

            composable(Routes.SETTINGS) {
                val viewModel: SettingsViewModel = hiltViewModel()
                SettingsScreen(
                    viewModel = viewModel,
                    onBack = { navController.popBackStack() },
                )
            }

            composable(Routes.VOICE_GUIDE) {
                val viewModel: CameraViewModel = hiltViewModel()
                CameraScreen(
                    viewModel = viewModel,
                    speechHelper = speechHelper,
                    onBack = { navController.popBackStack() },
                    mode = AIMode.SCENE,
                )
            }

            composable(Routes.SCENE) {
                val viewModel: CameraViewModel = hiltViewModel()
                CameraScreen(
                    viewModel = viewModel,
                    speechHelper = speechHelper,
                    onBack = { navController.popBackStack() },
                    mode = AIMode.SCENE,
                )
            }

            composable(Routes.READ_TEXT) {
                val viewModel: CameraViewModel = hiltViewModel()
                CameraScreen(
                    viewModel = viewModel,
                    speechHelper = speechHelper,
                    onBack = { navController.popBackStack() },
                    mode = AIMode.READ_TEXT,
                )
            }

            composable(Routes.FIND_OBJECT) {
                val viewModel: CameraViewModel = hiltViewModel()
                CameraScreen(
                    viewModel = viewModel,
                    speechHelper = speechHelper,
                    onBack = { navController.popBackStack() },
                    mode = AIMode.FIND_OBJECT,
                )
            }

            composable(Routes.SOCIAL) {
                val viewModel: CameraViewModel = hiltViewModel()
                CameraScreen(
                    viewModel = viewModel,
                    speechHelper = speechHelper,
                    onBack = { navController.popBackStack() },
                    mode = AIMode.SOCIAL,
                )
            }
        }
    }
}
