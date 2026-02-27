package com.ZacharyZhang.eyeguide.ui.camera

import android.graphics.Bitmap
import android.util.Base64
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ZacharyZhang.eyeguide.data.model.ConversationEntry
import com.ZacharyZhang.eyeguide.data.model.extractText
import com.ZacharyZhang.eyeguide.data.repository.AIRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream
import javax.inject.Inject

data class CameraUiState(
    val isAnalyzing: Boolean = false,
    val result: String? = null,
    val error: String? = null,
    val conversationHistory: List<ConversationEntry> = emptyList(),
)

@HiltViewModel
class CameraViewModel @Inject constructor(
    private val aiRepository: AIRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(CameraUiState())
    val uiState: StateFlow<CameraUiState> = _uiState.asStateFlow()

    fun analyzeScene(bitmap: Bitmap, detailLevel: String = "standard", language: String = "en") {
        val base64 = bitmapToBase64(bitmap)
        viewModelScope.launch {
            _uiState.update { it.copy(isAnalyzing = true, result = null, error = null) }
            aiRepository.analyzeScene(base64, detailLevel, language)
                .onSuccess { response ->
                    val text = response.extractText()
                    _uiState.update { it.copy(isAnalyzing = false, result = text) }
                    aiRepository.recordUsage("scene_description", success = true)
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isAnalyzing = false, error = e.message) }
                    aiRepository.recordUsage("scene_description", success = false, errorMessage = e.message)
                }
        }
    }

    fun readText(bitmap: Bitmap, language: String = "en") {
        val base64 = bitmapToBase64(bitmap)
        viewModelScope.launch {
            _uiState.update { it.copy(isAnalyzing = true, result = null, error = null) }
            aiRepository.readText(base64, language)
                .onSuccess { response ->
                    _uiState.update { it.copy(isAnalyzing = false, result = response.extractText()) }
                    aiRepository.recordUsage("text_reading", success = true)
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isAnalyzing = false, error = e.message) }
                    aiRepository.recordUsage("text_reading", success = false, errorMessage = e.message)
                }
        }
    }

    fun findObject(bitmap: Bitmap, targetObject: String, language: String = "en") {
        val base64 = bitmapToBase64(bitmap)
        viewModelScope.launch {
            _uiState.update { it.copy(isAnalyzing = true, result = null, error = null) }
            aiRepository.findObject(base64, targetObject, language)
                .onSuccess { response ->
                    _uiState.update { it.copy(isAnalyzing = false, result = response.extractText()) }
                    aiRepository.recordUsage("object_recognition", success = true)
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isAnalyzing = false, error = e.message) }
                    aiRepository.recordUsage("object_recognition", success = false, errorMessage = e.message)
                }
        }
    }

    fun analyzeSocial(bitmap: Bitmap, language: String = "en") {
        val base64 = bitmapToBase64(bitmap)
        viewModelScope.launch {
            _uiState.update { it.copy(isAnalyzing = true, result = null, error = null) }
            aiRepository.analyzeSocial(base64, language)
                .onSuccess { response ->
                    _uiState.update { it.copy(isAnalyzing = false, result = response.extractText()) }
                    aiRepository.recordUsage("social_assistant", success = true)
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isAnalyzing = false, error = e.message) }
                    aiRepository.recordUsage("social_assistant", success = false, errorMessage = e.message)
                }
        }
    }

    fun sendConversation(message: String, bitmap: Bitmap? = null, language: String = "en") {
        val base64 = bitmap?.let { bitmapToBase64(it) }
        viewModelScope.launch {
            val history = _uiState.value.conversationHistory
            _uiState.update { it.copy(isAnalyzing = true, result = null, error = null) }
            aiRepository.conversation(message, base64, history, language)
                .onSuccess { response ->
                    val text = response.extractText()
                    val updatedHistory = history +
                        ConversationEntry("user", message) +
                        ConversationEntry("model", text)
                    _uiState.update {
                        it.copy(isAnalyzing = false, result = text, conversationHistory = updatedHistory)
                    }
                    aiRepository.recordUsage("voice_interaction", success = true)
                }
                .onFailure { e ->
                    _uiState.update { it.copy(isAnalyzing = false, error = e.message) }
                    aiRepository.recordUsage("voice_interaction", success = false, errorMessage = e.message)
                }
        }
    }

    fun clearResult() {
        _uiState.update { it.copy(result = null, error = null) }
    }

    fun clearConversation() {
        _uiState.update { CameraUiState() }
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val maxWidth = 640
        val scaledBitmap = if (bitmap.width > maxWidth) {
            val scale = maxWidth.toFloat() / bitmap.width
            val newHeight = (bitmap.height * scale).toInt()
            Bitmap.createScaledBitmap(bitmap, maxWidth, newHeight, true)
        } else {
            bitmap
        }
        val stream = ByteArrayOutputStream()
        scaledBitmap.compress(Bitmap.CompressFormat.JPEG, 60, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }
}
