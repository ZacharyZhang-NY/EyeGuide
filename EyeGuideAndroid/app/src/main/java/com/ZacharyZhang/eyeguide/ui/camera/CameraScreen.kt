package com.ZacharyZhang.eyeguide.ui.camera

import android.Manifest
import android.graphics.Bitmap
import android.view.ViewGroup
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.OutlinedTextField
import androidx.compose.ui.text.input.ImeAction
import com.ZacharyZhang.eyeguide.ui.theme.EyeGuideLime
import com.ZacharyZhang.eyeguide.util.SpeechHelper
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import java.util.concurrent.Executors

enum class AIMode(val title: String) {
    SCENE("Scene Description"),
    READ_TEXT("Text Reader"),
    FIND_OBJECT("Object Finder"),
    SOCIAL("Social Assist"),
}

@Composable
fun CameraScreen(
    viewModel: CameraViewModel,
    speechHelper: SpeechHelper,
    onBack: () -> Unit,
    mode: AIMode = AIMode.SCENE,
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val isSpeaking by speechHelper.isSpeaking.collectAsStateWithLifecycle()
    val isListening by speechHelper.isListening.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    var hasCameraPermission by remember { mutableStateOf(false) }
    var hasAudioPermission by remember { mutableStateOf(false) }
    val imageCapture = remember { ImageCapture.Builder().build() }
    val executor = remember { Executors.newSingleThreadExecutor() }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        hasCameraPermission = permissions[Manifest.permission.CAMERA] == true
        hasAudioPermission = permissions[Manifest.permission.RECORD_AUDIO] == true
    }

    LaunchedEffect(Unit) {
        permissionLauncher.launch(
            arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
        )
    }

    LaunchedEffect(uiState.result) {
        uiState.result?.let { speechHelper.speak(it) }
    }

    DisposableEffect(Unit) {
        onDispose { viewModel.clearConversation() }
    }

    // Auto-analysis loop for continuous modes
    if (mode != AIMode.FIND_OBJECT) {
        LaunchedEffect(hasCameraPermission) {
            if (!hasCameraPermission) return@LaunchedEffect
            delay(2000)
            while (isActive) {
                val currentState = viewModel.uiState.value
                val currentlySpeaking = speechHelper.isSpeaking.value
                if (!currentState.isAnalyzing && !currentlySpeaking) {
                    captureImage(imageCapture, executor) { bitmap ->
                        when (mode) {
                            AIMode.SCENE -> viewModel.analyzeScene(bitmap)
                            AIMode.READ_TEXT -> viewModel.readText(bitmap)
                            AIMode.SOCIAL -> viewModel.analyzeSocial(bitmap)
                            AIMode.FIND_OBJECT -> {}
                        }
                    }
                    delay(1000)
                    while (viewModel.uiState.value.isAnalyzing) delay(300)
                    while (speechHelper.isSpeaking.value) delay(300)
                    delay(2000)
                } else {
                    delay(500)
                }
            }
        }
    }

    Column(modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier.size(48.dp).semantics {
                    contentDescription = "Go back"
                },
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
            }
            Text(mode.title, style = MaterialTheme.typography.titleLarge, modifier = Modifier.weight(1f))
        }

        if (hasCameraPermission) {
            Box(
                modifier = Modifier.weight(1f).fillMaxWidth().clip(RoundedCornerShape(16.dp)).padding(horizontal = 16.dp),
            ) {
                AndroidView(
                    factory = { ctx ->
                        PreviewView(ctx).apply {
                            layoutParams = ViewGroup.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT,
                            )
                            scaleType = PreviewView.ScaleType.FILL_CENTER
                        }.also { previewView ->
                            val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                            cameraProviderFuture.addListener({
                                val cameraProvider = cameraProviderFuture.get()
                                val preview = Preview.Builder().build().also {
                                    it.surfaceProvider = previewView.surfaceProvider
                                }
                                cameraProvider.unbindAll()
                                cameraProvider.bindToLifecycle(
                                    lifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA, preview, imageCapture,
                                )
                            }, ContextCompat.getMainExecutor(ctx))
                        }
                    },
                    modifier = Modifier.fillMaxSize(),
                )
            }
        } else {
            Box(modifier = Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text("Camera permission required", style = MaterialTheme.typography.bodyLarge)
            }
        }

        uiState.result?.let { result ->
            Box(
                modifier = Modifier.fillMaxWidth().heightIn(max = 200.dp).padding(horizontal = 16.dp, vertical = 8.dp)
                    .clip(RoundedCornerShape(12.dp)).background(MaterialTheme.colorScheme.surface).padding(12.dp),
            ) {
                Text(
                    text = result, style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.verticalScroll(rememberScrollState()),
                )
            }
        }

        uiState.error?.let { error ->
            Text(
                text = error, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
            )
        }

        if (mode == AIMode.FIND_OBJECT) {
            var objectQuery by remember { mutableStateOf("") }
            OutlinedTextField(
                value = objectQuery,
                onValueChange = { objectQuery = it },
                label = { Text("What are you looking for?") },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(
                    onSearch = {
                        if (objectQuery.isNotBlank()) {
                            captureImage(imageCapture, executor) { bitmap ->
                                viewModel.findObject(bitmap, objectQuery)
                            }
                        }
                    },
                ),
            )

            Row(
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconButton(
                    onClick = {
                        if (objectQuery.isNotBlank()) {
                            captureImage(imageCapture, executor) { bitmap ->
                                viewModel.findObject(bitmap, objectQuery)
                            }
                        }
                    },
                    modifier = Modifier.size(56.dp).clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary)
                        .semantics { contentDescription = "Find object" },
                ) {
                    Icon(Icons.Default.CameraAlt, contentDescription = null, tint = MaterialTheme.colorScheme.onPrimary)
                }
                IconButton(
                    onClick = {
                        if (isListening) {
                            speechHelper.stopListening()
                        } else {
                            speechHelper.startListening(
                                onResult = { text -> objectQuery = text },
                                onError = {},
                            )
                        }
                    },
                    modifier = Modifier.size(56.dp).clip(CircleShape)
                        .background(if (isListening) MaterialTheme.colorScheme.error else EyeGuideLime)
                        .semantics { contentDescription = if (isListening) "Stop listening" else "Voice search" },
                ) {
                    Icon(
                        if (isListening) Icons.Default.Stop else Icons.Default.Mic,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimary,
                    )
                }
            }
        } else {
            // For auto-analyzed modes, show status and voice button only
            Column(
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text(
                    text = "Live",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(modifier = Modifier.height(8.dp))
                IconButton(
                    onClick = {
                        if (isListening) {
                            speechHelper.stopListening()
                        } else {
                            speechHelper.startListening(
                                onResult = { text -> viewModel.sendConversation(text) },
                                onError = {},
                            )
                        }
                    },
                    modifier = Modifier.size(56.dp).clip(CircleShape)
                        .background(if (isListening) MaterialTheme.colorScheme.error else EyeGuideLime)
                        .semantics { contentDescription = if (isListening) "Stop listening" else "Start voice input" },
                ) {
                    Icon(
                        if (isListening) Icons.Default.Stop else Icons.Default.Mic,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimary,
                    )
                }
            }
        }
    }
}

private fun captureImage(
    imageCapture: ImageCapture,
    executor: java.util.concurrent.Executor,
    onCaptured: (Bitmap) -> Unit,
) {
    imageCapture.takePicture(executor, object : ImageCapture.OnImageCapturedCallback() {
        override fun onCaptureSuccess(image: ImageProxy) {
            val rotation = image.imageInfo.rotationDegrees
            var bitmap = image.toBitmap()
            image.close()
            if (rotation != 0) {
                val matrix = android.graphics.Matrix()
                matrix.postRotate(rotation.toFloat())
                bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            }
            onCaptured(bitmap)
        }
    })
}
