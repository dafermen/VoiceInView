# vReader

Native iPhone app for readable live English captions during conferences, classes and meetings. The planned speech engine runs on device without Internet after required models are installed.

## Current status
Phase 1 microphone capture is implemented. Apple compilation, automated tests and real-device verification are PENDING on a Mac.
The app now requests microphone access on Start Listening, captures transient audio from the built-in microphone, shows listening state and an input volume meter, and stops safely on user action/background/interruption/input changes.
Live captions and transcript storage are not implemented. Do not proceed to Phase 2 without explicit approval. Phase 0 and Phase 1 build/runtime acceptance remain unverified.

## Requirements
- Mac with Xcode 26+ and iOS 26 SDK/runtime for build and tests.
- iPhone with iOS 26.0+ for real microphone validation.
- Future speech engine support depends on hardware, supported en-US locale and installed models; OS version alone is not sufficient.
- Replace com.example.vReader and choose your development team for device signing.

## Architecture
- vReader/App: application entry.
- vReader/UI: accessible SwiftUI controls and input meter.
- vReader/ViewModels: MainActor observable listening state and lifecycle handling.
- vReader/Models: explicit states, permissions and user-facing failures.
- vReader/Services/Audio: testable AudioCapturing protocol and native AVFoundation service.
- vReaderUnitTests: mocked state/lifecycle tests.
- vReaderTests: UI launch smoke test.
- docs: decisions, architecture, roadmap, privacy and testing.

No third-party dependencies. No stored audio, network requests, accounts or speech recognition in this phase.

## Build / test / use
Open vReader.xcodeproj on a Mac, select vReader and an iOS 26+ iPhone simulator. Product > Build; Product > Test runs the unit and UI test targets.
Device signing and CLI commands: [development](docs/development.md).
On iPhone, tap Start Listening and allow microphone access. Speak and check the meter. Tap Stop. A stopped session never restarts automatically.
Denied permission offers Open Settings. Device restrictions may prevent permission changes.

## Limitations
Windows cannot compile or run iOS apps. Static integrity checks are not a successful build.
Microphone capture works in foreground only and prefers the phone microphone; Bluetooth microphone capture is not enabled.
The meter measures volume, not speech presence or transcription readiness. Silence is a valid audio buffer.
Physical device validation is essential; simulator audio cannot prove iPhone behavior.
The selected iOS 26 API installTap is deprecated starting in iOS 27. Its replacement requires iOS 27; migration must be verified with that SDK before changing the baseline.
An App Store icon, final identifier, license, privacy policy and release validation remain pending.

[Phase 1 report](docs/phase-1-report.md) · [Architecture](docs/architecture.md) · [Roadmap](docs/roadmap.md) · [Manual testing](docs/testing.md)
