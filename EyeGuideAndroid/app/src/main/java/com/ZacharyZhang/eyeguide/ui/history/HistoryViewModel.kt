package com.ZacharyZhang.eyeguide.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ZacharyZhang.eyeguide.data.model.Session
import com.ZacharyZhang.eyeguide.data.repository.SessionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HistoryUiState(
    val isLoading: Boolean = true,
    val isRefreshing: Boolean = false,
    val sessions: List<Session> = emptyList(),
    val error: String? = null,
)

@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val sessionRepository: SessionRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

    init {
        loadSessions()
    }

    private fun loadSessions() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            sessionRepository.getSessions(limit = 50)
                .onSuccess { response ->
                    _uiState.update { it.copy(sessions = response.sessions, isLoading = false) }
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message, isLoading = false) }
                }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true) }
            sessionRepository.getSessions(limit = 50)
                .onSuccess { response ->
                    _uiState.update { it.copy(sessions = response.sessions, isRefreshing = false) }
                }
                .onFailure { e ->
                    _uiState.update { it.copy(error = e.message, isRefreshing = false) }
                }
        }
    }
}
