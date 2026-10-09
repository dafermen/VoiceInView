# VoiceInView

**See what's being said.** Live English Captions.

Native iPhone app designed to caption English speech on device during conferences, classes, meetings and presentations, without sending recognition audio to a server, when on-device English support is available.

## Current status
Implementation and release-preparation source through Phase 9 are present. This is a DEVELOPMENT BUILD, not a certified release candidate.
The project now targets iOS 17 and builds with Xcode 15.2 on macOS Ventura. A compatibility speech engine uses SFSpeechRecognizer with on-device recognition required. The modern iOS 26 engine is retained behind compiler/OS availability checks. See [validation results](docs/validation-report.md) for executed checks; real-device accuracy and offline behavior remain unverified.
On 2026-10-09, the user confirmed successful installation and basic operation of TestFlight build 0.1.0 (5) on their iPhone. This does not establish offline accuracy or extended reliability.
The user explicitly authorized continuous progression through Phase 9 despite pending Apple validation. Phase 10 online AI is not implemented.

## Implemented source
- Foreground built-in microphone capture, contextual permission and diagnostics.
- SpeechTranscribing boundary with offline-only SFSpeechRecognizer on older toolchains/OS versions, plus SpeechAnalyzer/SpeechTranscriber when built with Xcode 26+ and run on iOS 26+.
- Compatibility requests rotate after 50 seconds of audio; incoming audio waits in a bounded queue during finalization. Overflow/timeouts stop visibly. Speech permission and system model availability are explicit.
- Partial/final caption assembly with independent analyzer-run identities.
- Scaled/adjustable caption text, light/dark/system appearance, live-follow, pause/resume, active-listening duration and optional screen wake.
- SwiftData local sessions, incremental final-caption saves, history, rename, confirmed deletion and title/finished-transcript search.
- Text file export, Copy and native Share.
- Persistent settings and guided Offline Readiness / Test Offline Mode.
- Bounded queues, cancellation/overflow/stall/finalization guards and storage monitoring.
- Privacy manifest, in-app policy, publication draft, icon, App Store metadata drafts and release checklist.

## Requirements
Development: Mac with Xcode 15.2+ and a compatible iOS 17+ SDK/runtime. The modern speech engine requires Xcode 26+ (Swift compiler 6.2+) and iOS 26+.
Use: iPhone with iOS 17+, on-device en-US recognition support and microphone consent. The compatibility engine also requires Speech Recognition permission. OS version alone does not guarantee engine/model compatibility.
Final device matrix is pending. System language/model setup may need Internet and disk space. Xcode 15.2 builds use the compatibility engine even on newer iPhones; debugging also requires Xcode support for the phone’s OS.
No account, cloud recognition, OpenAI key or third-party package is required.

## Build and test on Mac
Open VoiceInView.xcodeproj, select shared scheme VoiceInView and an iOS 17+ iPhone simulator.
From the project root:
~~~sh
bash scripts/validate-macos.sh
~~~
The script builds Debug, runs unit/UI tests, builds Release and checks the simulator bundle. Physical iPhone checks remain manual.
Signing is configured for team `7799N4RYUG` and app identifier `com.dafermen.vReader`. Register this identifier with the same Apple team when configuring distribution.
The existing bundle identifier and internal `vReader` storage directory are retained across the VoiceInView rename so app identity and saved-session location remain stable. Shell scripts accept `VOICEINVIEW_*` settings and the previous `VREADER_*` aliases.
See [development](docs/development.md), [testing](docs/testing.md) and [release checklist](docs/release-checklist.md).

## How to use after validation
1. Settings > Offline Readiness: allow microphone and Speech Recognition when requested. Resolve any readiness warnings while online. With the compatibility engine, enable English (US) Dictation in iPhone Settings if on-device support is unavailable, then refresh; the app cannot download that engine’s model. Use Install English Model only if the modern engine offers it.
2. Test Offline Mode: enable Airplane Mode and turn Wi-Fi off, then return to Captions.
3. Start Listening; read live captions. Pause/Resume retains earlier final text. Stop finalizes the session.
4. Tap Aa for caption size, live following and screen wake. Rotate the iPhone to use the compact landscape controls.
5. Auto-save is on by default. When off, use the (…) Session actions menu > Save Session before clearing or closing the app. New Session and session information are in the same menu.
6. Sessions: open/rename/search/delete or export/copy/share.

Leaving/locking the app stops microphone capture; restart requires user action. Unfinished captions can be lost on cancellation. With the compatibility engine, a provisional request can contain about 50 seconds of speech; use Pause/Stop to finalize before leaving. Saved sessions are excluded from device backup; export anything you need to retain.
Audio is never stored or uploaded by the app. Explicit sharing may transmit text through the chosen destination.

## Architecture / folders
- VoiceInView/App — application entry.
- VoiceInView/UI — captions, sessions, readiness, settings, diagnostics and policy.
- VoiceInView/ViewModels — observable presentation and session coordination.
- VoiceInView/Services/Audio and Speech — native capture and isolated speech engine.
- VoiceInView/Models and Persistence — transcript assembly, schema, local storage and settings.
- VoiceInView/Utilities — time formatting and text export.
- VoiceInViewUnitTests / VoiceInViewTests — compatibility/lifecycle, transcript, storage, settings and UI tests; see the validation report for executed counts. Modern audio conversion tests require Xcode 26/iOS 26.
- scripts — Windows static checks and Mac build/archive validation.
- docs — architecture, ADRs, phase reports, privacy and release material.

## Limitations / release gates
Real offline transcription, latency, 30/60/120-minute reliability, accessibility, database recovery and protection/backup behavior remain unverified. Xcode Cloud produced the archive distributed through TestFlight.
Built-in microphone only; Bluetooth input, background capture, PDF and online AI are not implemented.
Current installTap API is supported at the iOS 17 baseline and deprecated beginning iOS 27; migration to its iOS 27 replacement requires that SDK and new validation.
Public-release metadata, contact/support/privacy URLs, remaining questionnaire answers and genuine screenshots are pending.

[Delivery report](docs/implementation-report.md) · [Validation results](docs/validation-report.md) · [Architecture](docs/architecture.md) · [Roadmap](docs/roadmap.md) · [Privacy](docs/privacy.md)
