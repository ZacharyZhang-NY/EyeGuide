package com.ZacharyZhang.eyeguide.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel,
    onBack: () -> Unit,
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val prefs = uiState.user?.preferences
    var showDeleteDialog by remember { mutableStateOf(false) }
    var voiceSpeed by remember(prefs) { mutableFloatStateOf(prefs?.voiceSpeed ?: 1.0f) }
    var voicePitch by remember(prefs) { mutableFloatStateOf(prefs?.voicePitch ?: 1.0f) }
    var vibrationEnabled by remember(prefs) { mutableStateOf(prefs?.vibrationEnabled ?: true) }
    var highContrast by remember(prefs) { mutableStateOf(prefs?.highContrastEnabled ?: false) }
    var detailExpanded by remember { mutableStateOf(false) }
    var selectedDetail by remember(prefs) { mutableStateOf(prefs?.descriptionDetail ?: "standard") }
    val detailOptions = listOf("concise", "standard", "detailed")

    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp)) {
        Spacer(modifier = Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack, modifier = Modifier.size(48.dp).semantics {
                contentDescription = "Go back"
            }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null) }
            Spacer(modifier = Modifier.width(8.dp))
            Text("Settings", style = MaterialTheme.typography.headlineMedium, modifier = Modifier.semantics { heading() })
        }
        Spacer(modifier = Modifier.height(16.dp))

        if (uiState.isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(modifier = Modifier.semantics { contentDescription = "Loading settings" })
            }
        } else {
            Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
                Text("Voice Speed: ${String.format("%.1f", voiceSpeed)}x", style = MaterialTheme.typography.titleMedium)
                Slider(
                    value = voiceSpeed, onValueChange = { voiceSpeed = it },
                    valueRange = 0.5f..2.0f, steps = 5,
                    modifier = Modifier.semantics { contentDescription = "Voice speed slider" },
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text("Voice Pitch: ${String.format("%.1f", voicePitch)}x", style = MaterialTheme.typography.titleMedium)
                Slider(
                    value = voicePitch, onValueChange = { voicePitch = it },
                    valueRange = 0.5f..2.0f, steps = 5,
                    modifier = Modifier.semantics { contentDescription = "Voice pitch slider" },
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text("Description Detail", style = MaterialTheme.typography.titleMedium)
                Spacer(modifier = Modifier.height(8.dp))
                ExposedDropdownMenuBox(expanded = detailExpanded, onExpandedChange = { detailExpanded = it }) {
                    OutlinedTextField(
                        value = selectedDetail.replaceFirstChar { it.uppercase() },
                        onValueChange = {},
                        readOnly = true,
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = detailExpanded) },
                        modifier = Modifier.fillMaxWidth().menuAnchor(MenuAnchorType.PrimaryNotEditable),
                    )
                    ExposedDropdownMenu(expanded = detailExpanded, onDismissRequest = { detailExpanded = false }) {
                        detailOptions.forEach { option ->
                            DropdownMenuItem(
                                text = { Text(option.replaceFirstChar { it.uppercase() }) },
                                onClick = { selectedDetail = option; detailExpanded = false },
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("Vibration", style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                    Switch(checked = vibrationEnabled, onCheckedChange = { vibrationEnabled = it },
                        modifier = Modifier.semantics { contentDescription = "Toggle vibration" })
                }
                Spacer(modifier = Modifier.height(12.dp))
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("High Contrast", style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                    Switch(checked = highContrast, onCheckedChange = { highContrast = it },
                        modifier = Modifier.semantics { contentDescription = "Toggle high contrast" })
                }
                Spacer(modifier = Modifier.height(24.dp))
                Button(
                    onClick = {
                        viewModel.updatePreferences(
                            voiceSpeed = voiceSpeed, voicePitch = voicePitch,
                            descriptionDetail = selectedDetail, vibrationEnabled = vibrationEnabled,
                            highContrastEnabled = highContrast,
                        )
                    },
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    enabled = !uiState.isSaving,
                ) { Text(if (uiState.isSaving) "Saving..." else "Save Settings") }
                Spacer(modifier = Modifier.height(32.dp))
                Button(
                    onClick = { showDeleteDialog = true },
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                ) { Text("Delete Account") }
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Account") },
            text = { Text("Are you sure? This action cannot be undone.") },
            confirmButton = {
                TextButton(onClick = { showDeleteDialog = false; viewModel.deleteAccount { onBack() } }) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = { TextButton(onClick = { showDeleteDialog = false }) { Text("Cancel") } },
        )
    }
}
