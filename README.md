# VoiceInView

**See what's being said.** Live English Captions.

Native iPhone app designed to caption English speech on device during conferences, classes, meetings and presentations, without sending recognition audio to a server, when on-device English support is available.

## Current status
Implementation and release-preparation source through Phase 9 are present. This is a DEVELOPMENT BUILD, not a certified release candidate.
The project now targets iOS 17 and builds with Xcode 15.2 on macOS Ventura. A compatibility speech engine uses SFSpeechRecognizer with on-device recognition required. The modern iOS 26 engine is retained behind compiler/OS availability checks. See [validation results](docs/validation-report.md) for executed checks; real-device accuracy and offline behavior remain unverified.
On 2026-10-09, the user confirmed successful installation and basic operation of TestFlight builds 0.1.0 (5) and (6) on their iPhone. This does not establish offline accuracy or extended reliability.
The user explicitly authorized continuous progression through Phase 9 despite pending Apple validation. Phase 10 online AI is not implemented.

## Implemented source
- Built-in microphone capture with optional background continuation, contextual permission and diagnostics.
- SpeechTranscribing boundary with offline-only SFSpeechRecognizer on older toolchains/OS versions, plus SpeechAnalyzer/SpeechTranscriber when built with Xcode 26+ and run on iOS 26+.
- Compatibility requests rotate after 50 seconds of audio; incoming audio waits in a bounded queue during finalization. Overflow/timeouts stop visibly. Speech permission and system model availability are explicit.
- Partial/final caption assembly with independent analyzer-run identities.
- Fullscreen reading with pause/stop/exit controls, automatic suspension of live following when rereading, and Back to live.
- Adjustable caption size, line spacing, bold text, high contrast, light/dark/system appearance and optional screen wake.
- Saved phrase bookmarks, accessible from the live session menu and saved session details.
- SwiftData local sessions, incremental final-caption saves, history, rename, confirmed deletion and title/finished-transcript search.
- Transcript correction with undo/redo, original restoration and literal find/replace with match previews.
- A common review screen for Copy, TXT/PDF files and native sharing, with full-text/bookmark selection and optional session details.
- Saved reading positions and jumps from bookmarks.
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
4. Tap the expand arrows for fullscreen reading; the inward arrows restore the tabs. Rotate the iPhone in either mode. Scroll back to reread while listening continues; tap Back to live to follow again.
5. Tap Aa for caption size, line spacing, bold text, high contrast, live following and screen wake.
6. Auto-save is on by default. When off, use the (…) Session actions menu > Save Session before clearing or closing the app. After Stop, the blue circular + starts a new session after confirmation. New Session and session information also remain in the menu.
7. Touch and hold a finished paragraph to Save bookmark. This also saves the current session, including when auto-save is off. Read saved quotes in (…) > Bookmarks or Sessions > open a session > Bookmarks. Removing a bookmark leaves the transcript intact.
8. Sessions: open a saved session. The pencil opens Edit transcript; tap a paragraph to correct it or use Find and replace. Apply changes to the draft, then Save. Undo/Redo and Restore original remain available; Cancel lets you discard the draft. Stop an ongoing session before editing.
9. Tap Review & share to preview exactly what will be copied or exported. Choose Full transcript or Bookmarks, TXT or PDF, and whether to include session details. Edit is also available from this preview. Copy uses the displayed text; Save file and Share use the selected format.
10. Saved sessions remember the paragraph you were reading. Tap a bookmark in session details to jump to its paragraph when it still exists. Tap the session title to rename it.

Leaving/locking the app stops microphone capture by default. Enable Continue in background before starting a session to keep listening while switching apps or locking the screen. Calls and other interruptions still stop capture; restart requires user action. Unfinished captions can be lost on cancellation. With the compatibility engine, a provisional request can contain about 50 seconds of speech; use Pause/Stop to finalize before leaving. Saved sessions are excluded from device backup; export anything you need to retain.
Audio is never uploaded by the app. Saving audio is optional and off for each new session; enable Save audio with transcript in Aa or Settings before starting. Audio-enabled sessions also save their transcript. Stop the session, then open Sessions > Audio & subtitles for playback, seeking, fullscreen captions, M4A sharing, SRT/WebVTT, or audio + text + subtitles together. Native sharing includes Save to Files. TXT/PDF review and editing remain in Review & share. You can delete audio separately. Recording takes additional storage (hundreds of MB per hour); all local session data is excluded from backup.

Subtitles use the captured-audio clock: pauses are removed from both audio and subtitle files. Native word timing is used where available; edited passages use estimated timing within their saved audio range. Old sessions without timing retain their text but cannot produce synchronized subtitles. This does not capture internal audio from YouTube, meeting apps or other apps; their sound must reach the microphone through the speaker. Mixing and background behavior require testing on the actual device and source app.

## Architecture / folders
- VoiceInView/App — application entry.
- VoiceInView/UI — captions, sessions, readiness, settings, diagnostics and policy.
- VoiceInView/ViewModels — observable presentation and session coordination.
- VoiceInView/Services/Audio and Speech — native capture and isolated speech engine.
- VoiceInView/Models and Persistence — transcript assembly, schema, local storage and settings.
- VoiceInView/Utilities — time formatting, transcript review and TXT/PDF export.
- VoiceInViewUnitTests / VoiceInViewTests — compatibility/lifecycle, transcript, storage, settings and UI tests; see the validation report for executed counts. Modern audio conversion tests require Xcode 26/iOS 26.
- scripts — Windows static checks and Mac build/archive validation.
- docs — architecture, ADRs, phase reports, privacy and release material.

## Limitations / release gates
Real offline transcription, latency, 30/60/120-minute reliability, accessibility, database recovery and protection/backup behavior remain unverified. Xcode Cloud produced the archive distributed through TestFlight.
Built-in microphone only; Bluetooth input and online AI are not implemented. Background microphone capture is per-session opt-in.
Current installTap API is supported at the iOS 17 baseline and deprecated beginning iOS 27; migration to its iOS 27 replacement requires that SDK and new validation.
Public-release metadata, contact/support/privacy URLs, remaining questionnaire answers and genuine screenshots are pending.

[Delivery report](docs/implementation-report.md) · [Validation results](docs/validation-report.md) · [Architecture](docs/architecture.md) · [Roadmap](docs/roadmap.md) · [Privacy](docs/privacy.md)
