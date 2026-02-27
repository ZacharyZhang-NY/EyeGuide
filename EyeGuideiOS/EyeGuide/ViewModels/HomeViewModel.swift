import Foundation
import Observation

@Observable
final class HomeViewModel {
    var recentSessions: [Session] = []
    var isLoading = false
    var errorMessage: String?
    var activeSession: Session?

    func loadRecentActivity() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIService.shared.getSessions(limit: 5)
            recentSessions = response.sessions
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func checkActiveSession() async {
        do {
            let data = try await APIService.shared.getSessions(limit: 1)
            activeSession = data.sessions.first(where: { $0.endedAt == nil })
        } catch {
            activeSession = nil
        }
    }

    func startSession(type: String = "general") async {
        do {
            let response = try await APIService.shared.createSession(type: type)
            activeSession = response.session
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endCurrentSession() async {
        guard let session = activeSession else { return }
        do {
            _ = try await APIService.shared.endSession(id: session.id)
            activeSession = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
