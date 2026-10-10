# VoiceInView

**See what's being said.** Live English Captions.

Native iPhone app designed to caption English speech on device during conferences, classes, meetings and presentations, without sending recognition audio to a server, when on-device English support is available.

## Documentation / documentación

Start with the [documentation index](docs/README.md). Spanish learning material: [junior/student guide](docs/junior-guide.md) and [code walkthrough](docs/code-walkthrough.md). Before the next delivery, read the [distribution runbook](docs/distribution-runbook.md) and [incident history](docs/build-incidents.md).

## Current status
Implementation and release-preparation source through Phase 9 are present. This is a DEVELOPMENT BUILD, not a certified release candidate.
The project now targets iOS 17 and builds with Xcode 15.2 on macOS Ventura. A compatibility speech engine uses SFSpeechRecognizer with on-device recognition required. The modern iOS 26 engine is retained behind compiler/OS availability checks. See [validation results](docs/validation-report.md) for executed checks; real-device accuracy and offline behavior remain unverified.
On 2026-10-09, the user confirmed successful installation and basic operation of TestFlight builds 0.1.0 (5) and (6) on their iPhone. This does not establish offline accuracy or extended reliability.
On 2026-10-10, the Cloud Build 11 archive (Xcode 26.6 / iOS SDK 26.5) was successfully exported and uploaded from the Mac using Xcode 15.2. Screenshots confirm the first local upload processed as 0.1.0 (1), assigned to Dev. It appeared below older builds 5–8. The same feature archive was subsequently re-signed and uploaded as 0.1.0 (13) with explicit numbering; the user subsequently confirmed the update on the iPhone and that the audio/background switches work. Extended audio/subtitle and offline acceptance tests remain pending. Cloud export still fails with HTTP 502; changing Xcode 27 to 26.6 did not fix it. See the distribution runbook before retrying.
Phase 10 online AI is not implemented.

## Session controls (build 14 source)
Remembered Audio/Background preferences, quick controls beside capture, circular microphone/pause/stop buttons, one-tap + after saving, and explicit Save/Discard with recovery drafts. See [the session workflow](docs/session-workflow.md). This change still requires a new TestFlight delivery; an installed build 13 will not gain it automatically from a GitHub push.

## Implemented source
- Built-in microphone capture with optional background continuation, contextual permission and diagnostics.
- Optional local audio recording, playback with fullscreen captions, M4A export and independent audio deletion.
- Corrected TXT plus synchronized SRT/WebVTT sharing, with native word timing or estimated timing after corrections.
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
3. Choose Audio and Background directly in Captions; both choices are remembered. Tap the circular microphone to start, pause/play to pause/resume, and the square Stop to finish.
4. Tap the expand arrows for fullscreen reading; the inward arrows restore the tabs. Rotate the iPhone in either mode. Scroll back to reread while listening continues; tap Back to live to follow again.
5. Tap Aa for caption size, line spacing, bold text, high contrast, live following and screen wake.
6. After Stop, choose Save Session or Discard. Final captions and optional audio are checkpointed as recovery drafts until you decide. The blue + prepares a new session immediately after saving; if a draft is pending, it offers Save and new session, Discard and new session, or Cancel.
7. Touch and hold a finished paragraph to Save bookmark. This checkpoints the recovery draft without publishing it to the library. Read saved quotes in (…) > Bookmarks or Sessions > open a session > Bookmarks. Removing a bookmark leaves the transcript intact.
8. Sessions: open a saved session. The pencil opens Edit transcript; tap a paragraph to correct it or use Find and replace. Apply changes to the draft, then Save. Undo/Redo and Restore original remain available; Cancel lets you discard the draft. Stop an ongoing session before editing.
9. Tap Review & share to preview exactly what will be copied or exported. Choose Full transcript or Bookmarks, TXT or PDF, and whether to include session details. Edit is also available from this preview. Copy uses the displayed text; Save file and Share use the selected format.
10. Saved sessions remember the paragraph you were reading. Tap a bookmark in session details to jump to its paragraph when it still exists. Tap the session title to rename it.

Leaving/locking the app stops microphone capture by default. Enable the remembered Continue in background preference to keep listening while switching apps or locking the screen. Calls and other interruptions still stop capture; restart requires user action. Unfinished captions can be lost on cancellation. With the compatibility engine, a provisional request can contain about 50 seconds of speech; use Pause/Stop to finalize before leaving. Saved sessions are excluded from device backup; export anything you need to retain.
Audio is never uploaded by the app. Saving audio is optional and initially off. Your selection is remembered across sessions and relaunches. Change it from Captions, Aa or Settings before starting; during capture, audio preference changes apply to the next session. Final captions always get a local recovery draft. Stop the session, then open Sessions > Audio & subtitles for playback, seeking, fullscreen captions, M4A sharing, SRT/WebVTT, or audio + text + subtitles together. Native sharing includes Save to Files. TXT/PDF review and editing remain in Review & share. You can delete audio separately. Recording takes additional storage (hundreds of MB per hour); all local session data is excluded from backup.

Subtitles use the captured-audio clock: pauses are removed from both audio and subtitle files. Native word timing is used where available; edited passages use estimated timing within their saved audio range. Old sessions without timing retain their text but cannot produce synchronized subtitles. This does not capture internal audio from YouTube, meeting apps or other apps; their sound must reach the microphone through the speaker. Mixing and background behavior require testing on the actual device and source app.

## Architecture / folders
- VoiceInView/App — application entry.
- VoiceInView/UI — captions, sessions, readiness, settings, diagnostics and policy.
- VoiceInView/ViewModels — observable presentation and session coordination.
- VoiceInView/Services/Audio and Speech — native capture and isolated speech engine.
- VoiceInView/Models and Persistence — transcript assembly, schema, local storage and settings.
- VoiceInView/Utilities — time formatting, transcript review, TXT/PDF and SRT/WebVTT export.
- VoiceInViewUnitTests / VoiceInViewTests — compatibility/lifecycle, transcript, storage, settings and UI tests; see the validation report for executed counts. Modern audio conversion tests require Xcode 26/iOS 26.
- scripts — Windows static checks and Mac build/archive validation.
- docs — architecture, ADRs, phase reports, privacy and release material.

## Limitations / release gates
Real offline transcription, latency, 30/60/120-minute reliability, accessibility, database recovery and protection/backup behavior remain unverified. Xcode Cloud produced the archive distributed through TestFlight.
Built-in microphone only; Bluetooth input and online AI are not implemented. Background microphone capture is an explicit, remembered opt-in. It can be changed while listening; starting or resuming always requires user action.
Current installTap API is supported at the iOS 17 baseline and deprecated beginning iOS 27; migration to its iOS 27 replacement requires that SDK and new validation.
Public-release metadata, contact/support/privacy URLs, remaining questionnaire answers and genuine screenshots are pending.

[Delivery report](docs/implementation-report.md) · [Validation results](docs/validation-report.md) · [Architecture](docs/architecture.md) · [Roadmap](docs/roadmap.md) · [Privacy](docs/privacy.md)
