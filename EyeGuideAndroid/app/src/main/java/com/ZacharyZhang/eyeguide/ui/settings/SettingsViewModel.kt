package com.ZacharyZhang.eyeguide.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ZacharyZhang.eyeguide.data.model.PreferenceUpdateRequest
import com.ZacharyZhang.eyeguide.data.model.UserPreference
import com.ZacharyZhang.eyeguide.data.model.UserWithPreferences
import com.ZacharyZhang.eyeguide.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val isLoading: Boolean = true,
    val user: UserWithPreferences? = null,
    val isSaving: Boolean = false,
    val error: String? = null,
    val saveSuccess: Boolean = false,
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val userRepository: UserRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        loadUser()
    }

    private fun loadUser() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            userRepository.getMe()
                .onSuccess { data ->
                    _uiState.update { it.copy(user = data, isLoading = false) }
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
        }
    }

    fun updatePreferences(
        voiceSpeed: Float? = null,
        voicePitch: Float? = null,
        descriptionDetail: String? = null,
        language: String? = null,
        vibrationEnabled: Boolean? = null,
        highContrastEnabled: Boolean? = null,
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true, saveSuccess = false) }
            val request = PreferenceUpdateRequest(
                voiceSpeed = voiceSpeed,
                voicePitch = voicePitch,
                descriptionDetail = descriptionDetail,
                language = language,
                vibrationEnabled = vibrationEnabled,
                highContrastEnabled = highContrastEnabled,
            )
            userRepository.updatePreferences(request)
                .onSuccess { prefs ->
                    _uiState.update { state ->
                        val updatedUser = state.user?.copy(preferences = prefs)
                        state.copy(user = updatedUser, isSaving = false, saveSuccess = true)
                    }
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message, isSaving = false) }
                }
        }
    }

    fun deleteAccount(onDeleted: () -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }
            userRepository.deleteAccount()
                .onSuccess { onDeleted() }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message, isSaving = false) }
                }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun clearSaveSuccess() {
        _uiState.update { it.copy(saveSuccess = false) }
    }

    val preferences: UserPreference?
        get() = _uiState.value.user?.preferences
}
