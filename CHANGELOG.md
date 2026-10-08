# Changelog

## Unreleased — Phase 1
- Added contextual microphone permission flow and usage description in Debug/Release.
- Added built-in microphone AVAudioEngine capture with input volume meter.
- Added explicit listening, startup, stopping and error states; Settings recovery.
- Stop on background, audio interruptions, input/engine changes and media-service loss/reset.
- Added bounded volume delivery, stale-session protection and missing-buffer watchdog.
- Added twelve mocked state/lifecycle tests and updated UI smoke test.
- Updated architecture, privacy, manual testing and API availability decision.
- Compilation and Apple test execution remain pending on macOS.

## Phase 0
- Native SwiftUI shell and Xcode shared scheme.
- Offline-first architecture, project conventions, documentation and Git foundation.
- iOS 26.0 deployment target.
