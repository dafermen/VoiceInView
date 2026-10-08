# Architecture through Phase 9
App -> AppRootView -> SessionCoordinator -> CaptionViewModel -> SpeechTranscribing.
AppleSpeechTranscriber uses the shared AudioCaptureService and an AudioConversion actor, never a cloud fallback.
MainActor owns observable UI state, capture/session control and SwiftData context. Conversion runs on its own actor.

## Audio and recognition
Start checks supported hardware/locale/installed assets, asks microphone permission only when needed, prepares analyzer and starts a built-in mic engine.
Tap buffers are copied into immutable-owned CapturedAudio values before crossing executor boundaries. @unchecked Sendable expresses that ownership contract; consumers never mutate a shared buffer.
AVAudioConverter produces AnalyzerInput at the analyzer-selected format. Asset download is an explicit separate action. Installed English assets are reserved for reuse.
Raw/input/result queues are bounded, overflow stops the session and missing audio/finalization timeouts surface errors.
Audio failures and relevant route/engine/media-service changes are marshaled to MainActor with generation checks. Unchanged input route/setup notifications do not stop a valid engine.

## Caption state
States: idle, preparing, listening, stopping, paused, ended, problem.
Start preparations and analyzer runs use separate cancellation generations. Stop/background invalidates outstanding permission/start intent.
Scene background handling stops microphone synchronously, checkpoints finalized state and schedules analyzer cleanup. Foreground never auto-resumes.
Pause/Stop finalize before ending a run; resume gets a new run identity. Partial results remain provisional and can be discarded on cancellation.
TranscriptAssembler replaces overlapping revisions by run/range, not text equality, so repeated words remain legitimate. Common chronological final append avoids a full history scan.
Active-listening duration uses ContinuousClock to avoid wall-clock changes; metadata uses Date.

## UI
Lazy segment rows show 300 recent final captions initially, with Load Earlier Captions. There is no growing single Text rendering the full live transcript.
User can disable live-follow to read older captions; scroll animation respects Reduce Motion. Caption text scales with Dynamic Type and user preference.
Screen wake is enabled only for active listening/caption view and reset on background/disappearance.
Settings and Offline Readiness expose actual microphone/model/storage state; unknown checks never become an assumed ready state.
Microphone diagnostics preserve the Phase 1 volume-only workflow.

## Persistence
Schema version 1 contains ConferenceSession and related StoredCaption rows with cascade deletion.
Repository upserts finalized changes by UUID and stores run ordering separately from audio timestamps. Time/capacity monitoring runs every 30 seconds. Final full-text cache is created at normal end for search.
MainActor saves incremental segments; profile cost on device before claiming long-session reliability. On write failure, captions remain in presentation state for retry/manual save; rollback invalidates repository caches.
CloudKit is disabled; the store directory is backup-excluded with complete-until-first-authentication protection. Store failure is explicit; no automatic destructive reset or deceptive in-memory fallback.
Future schema changes require an explicit migration plan.

## Privacy and distribution
Only model installation uses system download services. Explicit file export/Copy/Share can send text to user-selected destinations.
No raw audio storage, developer network client, tracking, ads, analytics, account or embedded secret.
Manifest includes app-owned preferences and disk-space reasons. Source review is not a binary privacy/security audit.
Phase 9 prepares metadata/icon/scripts/checklist; actual Mac/device/Organizer validation and owner publication inputs are pending.
Phase 10 is not implemented.

ADRs: 001 offline-first, 002 Apple speech/minimum OS, 003 foreground microphone, 004 speech pipeline, 005 local session persistence.
