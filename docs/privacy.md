# Privacy and data flows
Source data-flow description updated for optional recording and subtitles; status reconciled 2026-10-10. An archive has been exported/uploaded, but a full binary privacy audit and physical protection/network checks remain pending.

| Data or action | Behavior | Location / recipient |
| --- | --- | --- |
| Microphone audio | User-started listening, optional background continuation, bounded queues; optional Save audio selected before a session | Memory by default; opt-in local protected CAF recording, M4A export |
| Speech analysis | SFSpeechRecognizer en-US with on-device support checked and required; modern SpeechAnalyzer where available; no remote fallback | Device; installed Apple models |
| Model setup | System English Dictation setup for compatibility engine; explicit Install English Model only for modern engine | Apple's system asset service |
| Final captions | Incremental recovery draft always; explicit Save publishes to library, Discard deletes | Local SwiftData store |
| Transcript corrections and reading position | Original recognition is retained; corrections and last read paragraph are stored separately | Local SwiftData store |
| Partial captions | Provisional, displayed in memory; not saved | Device memory |
| Session metadata | UUID, title, dates, active-listening duration, language and ended status | Local SwiftData store |
| Preferences | Caption size, wake, appearance, remembered audio/background choices | App's UserDefaults domain |
| Disk capacity | Checked for storage readiness and low-storage safeguard | Local value, not transmitted |
| Export / Copy / Share | Only after user action | Destination chosen by user; may transmit or sync text, audio and subtitle files |
| Diagnostics | Microphone check shows volume only | Device memory |

No account, analytics, advertising, tracking, OpenAI key, server endpoint or custom network client exists.
On-device support is checked before each compatibility request. Modern model reserve does not install assets at Start. Device support is rechecked before each run.
Microphone and Speech Recognition purpose strings are declared. The compatibility engine requests speech authorization through an explicit user action and sets requiresOnDeviceRecognition=true only after verifying supportsOnDeviceRecognition. The modern SpeechAnalyzer engine does not request legacy speech authorization.

Audio/background choices initially default off but persist after the user changes them. The microphone still starts only on explicit Start/Resume. Recording choice is fixed for the active session; background continuation can change while listening.

## Persistence and deletion
SwiftData uses an explicit application-support store with CloudKit disabled. The transcript and recording directory is excluded from backup and created with complete-until-first-user-authentication protection.
A finalized segment save commits incrementally; unfinished sessions can be reopened after interruption. Unsaved/partial text can be lost on cancellation or termination. Compatibility results remain provisional until request finalization (normally around 50 seconds); backgrounding can lose that current chunk.
Session deletion removes its recording, synchronized timing, draft marker, related captions, bookmarks and saved corrections/reading position, but this is logical deletion and not a forensic secure-erase guarantee. Exported copies and clipboard content are controlled separately by the destination/user.
Deleting the app removes its local data; backup exclusion means users should export transcripts they wish to retain.
Verify SQLite/WAL sidecar protection and backup exclusion on device before release.

## Manifest inventory
PrivacyInfo.xcprivacy declares:
- UserDefaults CA92.1: app-owned preferences only.
- DiskSpace E174.1: local storage readiness, write-failure prevention and user-visible capacity state.
- No tracking domains, no tracking, no collected-data declarations.

No explicit file timestamp or boot-time APIs are used by application source. Audit the built archive/privacy report and any future dependencies; this source-level manifest is not a guarantee that a final binary audit passes.

## Policy and production status
User-facing policy is accessible in Settings. Public draft: privacy-policy-draft.md.
Owner identity, contact and a public policy URL remain required for public release.
Re-review actual data flows, App Privacy answers and current requirements whenever SDKs or features change.

Sources:
https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition
https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest
https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
https://developer.apple.com/app-store/app-privacy-details/
https://developer.apple.com/app-store/review/guidelines/

The live level indicator reuses the microphone's local RMS-derived level; it is not a separate recording or a transcription-quality score. Suggested session titles use local date/time formatting. Phrase playback reads the existing local recording. These controls add no network service or new data destination.
