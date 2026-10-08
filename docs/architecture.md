# Architecture
## Phase 1 implementation
App -> HomeView -> ListeningViewModel -> AudioCapturing -> AudioCaptureService.
Models contain ListeningState, MicrophonePermission and CaptureFailure.
The protocol allows microphone/state tests without hardware.

ListeningViewModel uses Observation and MainActor for presentation. States: idle, requestingPermission, ready, starting, listening, stopping, error.
Start requests permission only when undetermined, rejects denied/unavailable permission and configures capture only after consent. Repeated start calls are ignored while busy.
A generation identifier invalidates outstanding permission responses and stale level tasks when Stop/background/failure ends a session.
A system permission sheet creates an inactive scene; it must not cancel the pending user intent. Background stops capture and invalidates that intent. Foreground refreshes permission without automatically starting capture.

AudioCaptureService configures AVAudioSession record/measurement, activates it and prefers builtInMic. A fresh AVAudioEngine uses the actual input format; invalid/no input and startup errors produce recoverable failures.
An explicitly Sendable tap closure computes first-channel RMS and maps -60...0 dBFS to a relative 0...1 meter. It does not store or forward raw audio.
AsyncStream bufferingNewest(1) bounds pending level data; presentation consumes approximately 10 updates/second. A five-second missing-buffer watchdog stops a stalled session; silence still delivers buffers and does not trigger it.
Notifications are bridged to MainActor through failure values. Session generation rejects stale notifications. Engine teardown is dispatched away from the engine's notification callback.
Stop cancels consumers, removes observers/tap, finishes the stream, stops/releases the engine and deactivates the session. Release failures are surfaced and deactivation is retried on the next start.
No background capture mode, Bluetooth capture option, automatic resume or recording file is enabled.

## Future approved additions
Phase 2 adds SpeechTranscribing and Apple speech, transient audio delivery, asset checks and partial/final captions. The current volume stream is not a transcription audio interface.
Phase 4 adds local ConferenceSession persistence; evaluate SwiftData then.
Phase 10 online AI requires separate approval, backend security and explicit user action.
Never silently fall back to cloud recognition.

Minimum OS iOS 26.0. Future speech hardware/locale/assets need runtime verification.
See ADR-001, ADR-002 and ADR-003.
