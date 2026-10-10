# Changelog

## Unreleased — 0.1.0 development, through Phase 9
iOS 17 compatibility builds with Xcode 15.2; the user confirmed basic operation of TestFlight builds 5 and 6 on their iPhone; detailed offline and release verification remain pending. This is not a release-certified binary.

### Changed
- New Session is a 44-point blue circular +. Completed portrait sessions omit the old footer to expand the reader; fullscreen and landscape retain accessible controls.
- Expanded the caption reader with a compact status strip and an adaptive landscape control bar. Reading options now open from Aa; save/new-session actions and full status information live in the session menu.
- A single primary action changes between Start Listening, Pause, Resume and New Session. Stop remains directly accessible.
- Renamed the app, Xcode project and scheme, source/test targets, exported filename fallback, permission text, documentation and repository to VoiceInView.
- Adopted the subtitle "Live English Captions" and tagline "See what's being said."
- Kept `com.dafermen.vReader` and the original internal session-storage directory for continuity. Validation/archive scripts also accept their previous environment-variable names.

### Added
- Optional per-session microphone recording, protected local audio, M4A export and independent audio deletion.
- Audio playback with seeking, synchronized captions and fullscreen rotation; transcript editing from the player.
- SRT/WebVTT and combined audio + corrected text + subtitle sharing, using sample-based timing across pauses and speech request rotations.
- Explicit per-session background listening and mixing with other apps' speaker audio; no internal other-app audio capture.
- Additive V4 media metadata that preserves existing sessions and corrections.
- Transcript editing with paragraph drafts, undo/redo, save/discard and restoration of the original recognition.
- Literal find/replace with whole-word/case options, previews and one/all replacement.
- Shared review preview for corrected text and bookmarks, optional metadata, TXT/PDF export, Copy and native sharing.
- Reading-position restoration and jumps from saved bookmarks.
- Additive V3 storage for corrections and reading positions, preserving old sessions, captions and bookmark snapshots.
- Fullscreen reader with visible listening status and accessible pause, stop and exit controls in portrait and landscape.
- Automatic pause of live following when scrolling back, a Back to live control and a pinned transcript window while rereading.
- Persistent line spacing, bold text and high-contrast reading options.
- Phrase bookmarks stored as snapshots, with an additive V1-to-V2 migration that preserves existing sessions.
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
- 56 compatibility unit tests and 12 UI scenarios passed across full and focused runs on iOS 17.2; one additional modern conversion test requires Xcode 26/iOS 26. Independent macOS assembler validation is also available.

### Fixed
- Provisional caption revisions retain their identity; the live text container stays stable and no longer animates every word update.
- Explicitly delete a session’s captions before saving its deletion, covering the orphan observed with iOS 17 SwiftData.
- A late final revision replacing all captions from an earlier analyzer run now preserves that run's position instead of moving it after newer speech. Added an XCTest regression that reproduces the original failure.

### Limitations
- Actual Airplane Mode captions, device compatibility, accessibility and 30/60/120-minute performance unverified.
- Foreground built-in microphone only; no audio recording, accounts, cloud AI, analytics, ads or tracking.
- Publisher/signing/license/public URLs and real screenshots still required.

## Earlier foundation
Phases 0–1 added SwiftUI/Xcode structure, microphone capture, permissions, states, initial tests and documentation.
