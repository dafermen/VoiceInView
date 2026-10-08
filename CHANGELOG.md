# Changelog

## Unreleased — 0.1.0 development, through Phase 9
iOS 17 compatibility builds with Xcode 15.2; physical speech and release verification remain pending. This is not a release-certified binary.

### Added
- iOS 17/Xcode 15.2 compatibility engine with required on-device recognition, explicit speech authorization, bounded buffering and 50-second request rotation. Modern iOS 26 engine retained for newer toolchains.
- Native simulator coverage for compatibility recognition lifecycle and offline policy.
- Native on-device English SpeechAnalyzer/SpeechTranscriber pipeline and explicit model installation.
- Partial/final captions, pause/resume, lazy/windowed rendering, text size, appearance, live following and active-time display.
- Local versioned SwiftData conference sessions, incremental final saves, history, rename/search/delete and recovery display.
- Text export, Copy and native sharing.
- Persisted preferences, microphone diagnostics and Offline Readiness/Test Offline Mode.
- Bounded queues, stale-session/cancellation guards, missing-audio/finalization timeouts and storage monitoring.
- Privacy manifest, policy/source audit, App Store drafts, icon and release checklist.
- Windows static validation and Mac Debug/test/Release/archive scripts.
- 40 compatibility unit tests and 3 UI tests passed on iOS 17.2; one additional modern conversion test requires Xcode 26/iOS 26. Independent macOS assembler validation is also available.

### Fixed
- Explicitly delete a session’s captions before saving its deletion, covering the orphan observed with iOS 17 SwiftData.
- A late final revision replacing all captions from an earlier analyzer run now preserves that run's position instead of moving it after newer speech. Added an XCTest regression that reproduces the original failure.

### Limitations
- Actual Airplane Mode captions, device compatibility, accessibility and 30/60/120-minute performance unverified.
- Foreground built-in microphone only; no audio recording, accounts, cloud AI, analytics, ads or tracking.
- Publisher/signing/license/public URLs and real screenshots still required.

## Earlier foundation
Phases 0–1 added SwiftUI/Xcode structure, microphone capture, permissions, states, initial tests and documentation.
