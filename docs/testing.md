# Testing through Phase 9
The project now builds with Xcode 15.2/iOS 17. On the iOS 17.2 simulator, 56 compatible unit tests and 12 UI scenarios passed across the full and focused validation runs. The modern AudioConversion test is excluded by the older compiler. See validation-report.md for logs and remaining gates. Simulator tests do not verify actual speech, offline model availability or a physical iPhone.


## Automated suite
- ListeningViewModelTests: 12 permission/start/stop/error/lifecycle tests.
- TranscriptAssemblerTests: 9 partial/final/duplicate/repeated-text/run-order/late-revision/merge/10,000-segment regressions.
- CaptionViewModelTests: 5 readiness/finalization/pause-resume/background-option/reset tests.
- TranscriptRepositoryTests: 6 upsert/rename/delete/order/reopen, V1/V2-to-V3 migration, bookmark snapshot, correction/original preservation and reading-position tests.
- TranscriptExportTests: 6 Unicode/metadata/filename, literal one/all replacement, undo/redo, corrected bookmark export and multipage PDF tests.
- AppSettingsTests: 2 preference/readiness tests.
- LegacySpeechTranscriberTests: offline request flags, authorization/support refusal, request rotation, queued audio, cancellation, timeout and overflow.
- AudioConversionTests: 1 sample-rate conversion test, only compiled with Swift 6.2+ and requiring iOS 26.
- SessionClockTests: 1 invalid/long-duration test.
- SessionMediaTests: 6 scenarios covering recording/decoding, export, capture timeline, subtitle construction, migration and deletion.
- HomeScreenTests: 12 tests covering launch without permission prompts, settings/readiness/privacy, microphone diagnostics, reading options, both landscape orientations, fullscreen during listening and rereading/bookmarking during incoming captions. Reader/media scenarios use deterministic DEBUG-only speech/audio fixtures and isolated stores. The player scenario covers correction, subtitle sharing and audio deletion. These fixtures do not prove real microphone accuracy.
Run bash scripts/validate-macos.sh. Do not infer device speech support from passing mocked/simulator tests.

## Phase 1 microphone diagnostics
Settings > Microphone Check: launch without permission prompt; Start and grant permission; speak/check meter; Stop clears meter/indicator. Repeat 20 times.
Deny access on a fresh permission reset, check error/Settings recovery. Background/lock/call/Siri and input changes must stop safely, with no automatic restart. Verify built-in mic is used.
Volume monitoring is not speech recognition and cannot prove offline captions.

## Phase 2 actual offline speech
1. Record device model, iOS, Xcode/SDK/build and English asset status.
2. While online, Settings > Offline Readiness, allow microphone and Speech Recognition if requested. With the compatibility engine, prepare English (US) Dictation in iPhone Settings if support is unavailable and refresh; no in-app model downloader exists for this engine. With the modern engine, Install English Model explicitly.
3. Enable Airplane Mode and turn Wi-Fi off; reopen/refresh readiness.
4. Captions > Start Listening, speak a known English passage. Observe provisional revisions and final text without duplicate ranges.
5. Record measured/observed start latency, live-caption delay, accuracy and failures; no numbers are provided before observation.
6. For the compatibility engine, speak continuously across several 50-second request boundaries; check for missing/repeated words and ensure preceding final chunks remain saved. Stop and inspect finalization. Test unsupported hardware/locale and missing assets without silent download or cloud fallback.

## Phase 3 reading/accessibility
Pause/Resume retains earlier final captions and excludes paused time. Stop ends capture and exposes Save/Discard. New Session is one tap after Save; a pending draft requires an explicit decision.
Use Aa to adjust caption size and following; use (…) Session actions for manual saving, New Session and full status information. Check largest Dynamic Type, light/dark/system appearance, contrast, VoiceOver and Reduce Motion. Rotate while listening, paused and stopped in both directions; verify captions, elapsed time and chosen text size remain intact and controls remain reachable.
Disable live following, load earlier captions and re-enable follow. Confirm screen wake only while listening/viewing captions and normal sleep on Stop/background.
Enter/exit fullscreen while listening, paused and rereading; check Pause/Stop/Exit remain accessible and tabs return on exit. Test notched iPhones as well as small screens.
Scroll back during incoming speech and confirm the same paragraph stays visible, then use Back to live. Load earlier captions in a transcript longer than 300 paragraphs. Check provisional text revisions do not flash or animate repeatedly.
Change line spacing, bold text and high contrast, then relaunch. Test these with largest Dynamic Type and both color schemes.
Long-press a finished paragraph > Save bookmark; view it through (…) > Bookmarks and Sessions > session > Bookmarks. Bookmarking checkpoints the draft without publishing it. Remove a bookmark and confirm the transcript remains; delete its session and confirm its bookmarks disappear. Update from a V1 store and verify earlier sessions survive.
Perform a 30-minute read-along.

## Phase 4 storage and recovery
Start/speak/stop, choose Save Session, force normal app termination/relaunch and open Sessions. Check title/date/duration/language, rename, title/finished-transcript search and confirmed delete.
Interrupt/terminate during listening: finalized saved segments should recover as an unfinished session; provisional text is not guaranteed.
Exercise low storage/write/startup failures. Errors must be visible, saving retry must not duplicate captions, and failed store opening must not destroy data.
Current session deletion is disabled until Stop; discarded drafts must remove text and audio without affecting other sessions.

## Phase 5 export
Open a saved session > Review & share; select TXT or PDF and use Save file/Share. Inspect UTF-8 text or rendered PDF and selected metadata. Exercise Copy separately. Audio & subtitles is the separate player/media export flow.
Cancel native dialogs and confirm the session remains. Test unusual/long titles and large transcripts. Explicit destination sharing may transmit text.

## Transcript editing and review
In Sessions, stop any current session before editing it. Correct a paragraph, apply it to the draft, undo/redo, save, close and reopen. Verify both the corrected wording and the original restoration. Cancel a dirty paragraph and a dirty transcript; confirm each explicit discard leaves saved text intact. Try multiline, accented and emoji text.

Find a repeated misspelling. Preview the matches, replace one, then replace all. Check whole-word/case options, literal punctuation, deletion via an empty replacement and Undo. Search the session history for the corrected wording.

Review & share must show the same corrections in full text, bookmarks, clipboard, TXT and PDF. Toggle session details; inspect a long PDF's first, middle and last pages. Save both formats in Files, reopen them and share a test file to a chosen destination. Cancel each native picker and ensure the session remains unchanged. No external destination is exercised automatically by UI tests.

Scroll a long saved session, leave and reopen it. Jump to a bookmark, reopen again and verify the last read paragraph is visible. Existing bookmark snapshots without a current paragraph remain readable. Migrate an existing installation containing sessions/bookmarks without deleting the app.

After Stop, verify Save/Discard appear; after Save, the portrait decision footer disappears. The circular + opens a new session immediately when saved, and requests a decision only for a pending draft. Check portrait, both landscape orientations and fullscreen.

## Phase 6 readiness/settings
Change Audio/Background in Captions and Settings, then relaunch. Choices persist without starting the microphone. During capture, Audio changes affect the next session and Background changes affect the current session. Stop leaves a recovery draft until Save/Discard. Reopen without deciding and recover the draft from Sessions.
Test all actual readiness states, permission recovery and unknown/low disk space. Test Offline Mode is guidance, not Airplane Mode detection.
The 64 MB check reserves transcript headroom; initial model download may need much more.

## Phase 7 reliability
Follow reliability.md for 30/60/120-minute memory/CPU/battery/thermal/latency measurements.
Test calls/Siri, accessory input/configuration changes, media-service resets, lock/background, low battery/storage and missing model changes.
Unchanged built-in input can continue across accessory setup events; actual input loss or stopped-engine changes must stop capture.
Inject queue overflow/missing-frame/slow-finalization failures in debug builds and restore code before release.

## Phases 8–9 production gates
Inspect built privacy manifest/report, permission wording, store/WAL protection and backup exclusion, logs and actual network behavior after model setup.
Verify no automatic uploads, no audio saved unless explicitly enabled, independent audio deletion, session deletion, protected recording files and explicit sharing behavior. Follow media-and-subtitles.md for pause/resume, playback, timing and background device tests.
Run Release simulator validation and signed device archive; check icon/dark/tinted variants, genuine screenshots and all release-checklist.md items.

## Evidence record
For each run record date, source commit, device/OS/SDK, scenario, result, latency/metrics, failure and retest. The user confirmed basic operation of TestFlight 0.1.0 (5) and (6) on their iPhone on 2026-10-09. The detailed physical scenarios above, including the revised reader during live speech, still require individual verification.
