package com.ZacharyZhang.eyeguide

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.ZacharyZhang.eyeguide.ui.navigation.EyeGuideNavigation
import com.ZacharyZhang.eyeguide.ui.theme.EyeGuideTheme
import com.ZacharyZhang.eyeguide.util.SpeechHelper
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var speechHelper: SpeechHelper

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        speechHelper.initialize()
        enableEdgeToEdge()
        setContent {
            EyeGuideTheme {
                EyeGuideNavigation(speechHelper = speechHelper)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        speechHelper.shutdown()
    }
}
