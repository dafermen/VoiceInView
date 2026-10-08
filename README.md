# vReader

Native iPhone app designed to caption English speech on device during conferences, classes, meetings and presentations, even without Internet after compatible English assets are installed.

## Current status
Implementation and release-preparation source through Phase 9 are present. This is a DEVELOPMENT BUILD, not a certified release candidate.
No Xcode build, XCTest execution or physical iPhone validation has been run: the development host is Windows. Static checks passed; they do not prove Swift compilation, transcription accuracy or offline/runtime behavior.
The user explicitly authorized continuous progression through Phase 9 despite pending Apple validation. Phase 10 online AI is not implemented.

## Implemented source
- Foreground built-in microphone capture, contextual permission and diagnostics.
- SpeechTranscribing boundary with Apple SpeechAnalyzer/SpeechTranscriber, en-US readiness and explicit model installation.
- Partial/final caption assembly with independent analyzer-run identities.
- Scaled/adjustable caption text, light/dark/system appearance, live-follow, pause/resume, active-listening duration and optional screen wake.
- SwiftData local sessions, incremental final-caption saves, history, rename, confirmed deletion and title/finished-transcript search.
- Text file export, Copy and native Share.
- Persistent settings and guided Offline Readiness / Test Offline Mode.
- Bounded queues, cancellation/overflow/stall/finalization guards and storage monitoring.
- Privacy manifest, in-app policy, publication draft, icon, App Store metadata drafts and release checklist.

## Requirements
Development: Mac with Xcode 26+ and iOS 26+ SDK/runtime.
Use: iPhone with iOS 26.0+, SpeechTranscriber hardware support, supported en-US assets and microphone consent. OS version alone does not guarantee engine compatibility.
Final device matrix is pending. Initial English model installation needs Internet and additional disk space.
No account, cloud recognition, OpenAI key or third-party package is required.

## Build and test on Mac
Open vReader.xcodeproj, select shared scheme vReader and an iOS 26+ iPhone simulator.
From the project root:
~~~sh
bash scripts/validate-macos.sh
~~~
The script builds Debug, runs unit/UI tests, builds Release and checks the simulator bundle. Physical iPhone checks remain manual.
For device installation, replace com.example.vReader and select your signing team in Xcode.
See [development](docs/development.md), [testing](docs/testing.md) and [release checklist](docs/release-checklist.md).

## How to use after validation
1. Settings > Offline Readiness: allow microphone and explicitly install the English model while online.
2. Test Offline Mode: enable Airplane Mode and turn Wi-Fi off, then return to Captions.
3. Start Listening; read live captions. Pause/Resume retains earlier final text. Stop finalizes the session.
4. Auto-save is on by default. When off, use Save Session before clearing or closing the app.
5. Sessions: open/rename/search/delete or export/copy/share.

Leaving/locking the app stops microphone capture; restart requires user action. Unfinished sentences can be lost on cancellation. Saved sessions are excluded from device backup; export anything you need to retain.
Audio is never stored or uploaded by the app. Explicit sharing may transmit text through the chosen destination.

## Architecture / folders
- vReader/App — application entry.
- vReader/UI — captions, sessions, readiness, settings, diagnostics and policy.
- vReader/ViewModels — observable presentation and session coordination.
- vReader/Services/Audio and Speech — native capture and isolated speech engine.
- vReader/Models and Persistence — transcript assembly, schema, local storage and settings.
- vReader/Utilities — time formatting and text export.
- vReaderUnitTests / vReaderTests — 32 unit tests and 3 UI tests (not executed).
- scripts — Windows static checks and Mac build/archive validation.
- docs — architecture, ADRs, phase reports, privacy and release material.

## Limitations / release gates
Real offline transcription, latency, 30/60/120-minute reliability, accessibility, database recovery, protection/backup behavior and release archiving are unverified.
Built-in microphone only; Bluetooth input, background capture, PDF and online AI are not implemented.
Current installTap API is supported at the iOS 26 baseline and deprecated beginning iOS 27; migration to its iOS 27 replacement requires that SDK and new validation.
Publisher/license, final bundle ID/team, contact/support/privacy URLs, questionnaire answers and genuine screenshots are pending.

[Delivery report](docs/implementation-report.md) · [Validation results](docs/validation-report.md) · [Architecture](docs/architecture.md) · [Roadmap](docs/roadmap.md) · [Privacy](docs/privacy.md)
