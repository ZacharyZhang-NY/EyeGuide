import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var voiceSpeed: Double = 1.0
    var voicePitch: Double = 1.0
    var descriptionDetail: String = "standard"
    var language: String = "zh-CN"
    var vibrationEnabled: Bool = true
    var highContrastEnabled: Bool = false
    var isSaving = false
    var errorMessage: String?

    func loadPreferences(from prefs: UserPreference?) {
        guard let prefs else { return }
        voiceSpeed = prefs.voiceSpeed
        voicePitch = prefs.voicePitch
        descriptionDetail = prefs.descriptionDetail
        language = prefs.language
        vibrationEnabled = prefs.vibrationEnabled
        highContrastEnabled = prefs.highContrastEnabled
    }

    func savePreferences() async -> UserPreference? {
        isSaving = true
        errorMessage = nil
        do {
            let update = PreferenceUpdate(
                voice_speed: voiceSpeed,
                voice_pitch: voicePitch,
                description_detail: descriptionDetail,
                language: language,
                vibration_enabled: vibrationEnabled,
                high_contrast_enabled: highContrastEnabled
            )
            let response = try await APIService.shared.updatePreferences(update)
            isSaving = false
            return response.preferences
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return nil
        }
    }
}
