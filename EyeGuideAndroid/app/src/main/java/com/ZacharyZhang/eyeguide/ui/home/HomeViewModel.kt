package com.ZacharyZhang.eyeguide.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ZacharyZhang.eyeguide.data.local.LocalActivity
import com.ZacharyZhang.eyeguide.data.local.LocalActivityStore
import com.ZacharyZhang.eyeguide.data.model.Session
import com.ZacharyZhang.eyeguide.data.model.UserWithPreferences
import com.ZacharyZhang.eyeguide.data.repository.SessionRepository
import com.ZacharyZhang.eyeguide.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val isLoading: Boolean = true,
    val user: UserWithPreferences? = null,
    val activeSession: Session? = null,
    val recentActivity: List<LocalActivity> = emptyList(),
    val error: String? = null,
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val sessionRepository: SessionRepository,
    private val localActivityStore: LocalActivityStore,
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val userResult = userRepository.registerOrLogin()
            userResult.onSuccess { userData ->
                _uiState.update { it.copy(user = userData) }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message, isLoading = false) }
                return@launch
            }

            val sessionResult = sessionRepository.getActiveSession()
            sessionResult.onSuccess { session ->
                _uiState.update { it.copy(activeSession = session) }
            }

            val activities = localActivityStore.load()
            _uiState.update { it.copy(recentActivity = activities, isLoading = false) }
        }
    }

    fun startSession() {
        viewModelScope.launch {
            sessionRepository.createSession("general").onSuccess { session ->
                _uiState.update { it.copy(activeSession = session) }
            }
        }
    }

    fun endSession() {
        viewModelScope.launch {
            val sessionId = _uiState.value.activeSession?.id ?: return@launch
            sessionRepository.endSession(sessionId).onSuccess {
                _uiState.update { it.copy(activeSession = null) }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
