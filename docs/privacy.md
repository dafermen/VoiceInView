# Privacy and data flows
Reviewed source and current Apple documentation on 2026-10-08. Archive/device validation remains pending.

| Data or action | Behavior | Location / recipient |
| --- | --- | --- |
| Microphone audio | Captured only during user-started foreground listening; copied briefly into bounded queues | Device memory; no audio files |
| Speech analysis | SFSpeechRecognizer en-US with on-device support checked and required; modern SpeechAnalyzer where available; no remote fallback | Device; installed Apple models |
| Model setup | System English Dictation setup for compatibility engine; explicit Install English Model only for modern engine | Apple's system asset service |
| Final captions | Auto-save by default; can disable before a session | Local SwiftData store |
| Partial captions | Provisional, displayed in memory; not saved | Device memory |
| Session metadata | UUID, title, dates, active-listening duration, language and ended status | Local SwiftData store |
| Preferences | Caption size, wake, appearance and auto-save | App's UserDefaults domain |
| Disk capacity | Checked for storage readiness and low-storage safeguard | Local value, not transmitted |
| Export / Copy / Share | Only after user action | Destination chosen by user; may transmit or sync text |
| Diagnostics | Microphone check shows volume only | Device memory |

No account, analytics, advertising, tracking, OpenAI key, server endpoint or custom network client exists.
On-device support is checked before each compatibility request. Modern model reserve does not install assets at Start. Device support is rechecked before each run.
Microphone and Speech Recognition purpose strings are declared. The compatibility engine requests speech authorization through an explicit user action and sets requiresOnDeviceRecognition=true only after verifying supportsOnDeviceRecognition. The modern SpeechAnalyzer engine does not request legacy speech authorization.

## Persistence and deletion
SwiftData uses an explicit application-support store with CloudKit disabled. The transcript directory is excluded from backup and created with complete-until-first-user-authentication protection.
A finalized segment save commits incrementally; unfinished sessions can be reopened after interruption. Unsaved/partial text can be lost on cancellation or termination. Compatibility results remain provisional until request finalization (normally around 50 seconds); backgrounding can lose that current chunk.
Session deletion cascades to related captions, but this is logical deletion and not a forensic secure-erase guarantee. Exported copies and clipboard content are controlled separately by the destination/user.
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
Owner identity, contact and a public policy URL remain required before distribution.
Re-review actual data flows, App Privacy answers and current requirements whenever SDKs or features change.

Sources:
https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition
https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest
https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
https://developer.apple.com/app-store/app-privacy-details/
https://developer.apple.com/app-store/review/guidelines/
