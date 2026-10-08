import Foundation
import Observation

@MainActor
@Observable
final class SessionCoordinator {
    let caption = CaptionViewModel()
    let repository: TranscriptRepository
    private(set) var currentSession: ConferenceSession?
    var storageMessage: String?
    var autoSave = true
    var sessionTitle = "Conference"

    init(repository: TranscriptRepository) {
        self.repository = repository
        caption.onWillStart = { [weak self] in
            guard let self, self.currentSession == nil, self.autoSave else { return }
            self.currentSession = try self.repository.create(title: self.sessionTitle)
        }
        caption.onFinalized = { [weak self] change in
            guard let self, self.autoSave, let session = self.currentSession else { return }
            do { try self.repository.apply(change, to: session) }
            catch {
                self.storageMessage = "Could not save captions. They remain visible in this session. Free storage and use Save Session before closing the app."
                Task { await self.caption.pause() }
            }
        }
        caption.onCheckpoint = { [weak self] duration in
            guard let self, self.autoSave, let session = self.currentSession else { return }
            do { try self.repository.checkpoint(session, duration: duration, ended: false) }
            catch { self.storageMessage = "Could not save session time. Retry Save Session." }
        }
        caption.onEnded = { [weak self] in self?.saveCurrent(ended: true) }
    }

    func saveCurrent(ended: Bool = false) {
        guard caption.startedAt != nil || !caption.transcript.finalized.isEmpty else { return }
        do {
            if currentSession == nil {
                currentSession = try repository.create(title: sessionTitle)
            }
            guard let currentSession else { return }
            // Upserts are idempotent, so retrying after a write failure cannot duplicate captions.
            try repository.apply(.init(removedIDs: [], upserted: caption.transcript.finalized), to: currentSession)
            try repository.checkpoint(currentSession, duration: caption.currentDuration(at: Date()), ended: ended)
            storageMessage = nil
        } catch {
            storageMessage = "Session could not be saved. Keep the app open, free storage, and try Save Session again."
        }
    }

    func newSession() async {
        guard !caption.state.active, !caption.state.busy else { return }
        await caption.reset()
        currentSession = nil
        sessionTitle = "Conference"
    }
}
