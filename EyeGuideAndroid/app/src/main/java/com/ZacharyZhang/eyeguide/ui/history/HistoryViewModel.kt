package com.ZacharyZhang.eyeguide.ui.history

import androidx.lifecycle.ViewModel
import com.ZacharyZhang.eyeguide.data.local.LocalActivity
import com.ZacharyZhang.eyeguide.data.local.LocalActivityStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject

data class HistoryUiState(
    val isLoading: Boolean = true,
    val isRefreshing: Boolean = false,
    val activities: List<LocalActivity> = emptyList(),
    val error: String? = null,
)

@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val localActivityStore: LocalActivityStore,
) : ViewModel() {

    private val _uiState = MutableStateFlow(HistoryUiState())
    val uiState: StateFlow<HistoryUiState> = _uiState.asStateFlow()

    init {
        loadActivities()
    }

    private fun loadActivities() {
        val activities = localActivityStore.load()
        _uiState.update { it.copy(activities = activities, isLoading = false) }
    }

    fun refresh() {
        _uiState.update { it.copy(isRefreshing = true) }
        val activities = localActivityStore.load()
        _uiState.update { it.copy(activities = activities, isRefreshing = false) }
    }
}
