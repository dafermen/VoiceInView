# Testing through Phase 9
The project now builds with Xcode 15.2/iOS 17. On the iOS 17.2 simulator, 40 unit tests and 3 UI tests passed. The modern AudioConversion test is excluded by the older compiler. See validation-report.md for logs and remaining gates. Simulator tests do not verify actual speech, offline model availability or a physical iPhone.


## Automated suite
- ListeningViewModelTests: 12 permission/start/stop/error/lifecycle tests.
- TranscriptAssemblerTests: 8 partial/final/duplicate/repeated-text/run-order/late-revision/merge/10,000-segment regressions.
- CaptionViewModelTests: 4 readiness/finalization/pause-resume/background-start tests.
- TranscriptRepositoryTests: 3 upsert/rename/delete/order/reopen tests.
- TranscriptExportTests: 2 Unicode/metadata/filename tests.
- AppSettingsTests: 2 preference/readiness tests.
- LegacySpeechTranscriberTests: offline request flags, authorization/support refusal, request rotation, queued audio, cancellation, timeout and overflow.
- AudioConversionTests: 1 sample-rate conversion test, only compiled with Swift 6.2+ and requiring iOS 26.
- SessionClockTests: 1 invalid/long-duration test.
- HomeScreenTests: 3 launch, settings/readiness/privacy and retained microphone-diagnostic tests.
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
Pause/Resume retains earlier final captions and excludes paused time. Stop ends the session; New Session confirms clearing unsaved content.
Check largest Dynamic Type, adjustable caption size, light/dark/system appearance, contrast, VoiceOver, Reduce Motion and rotation.
Disable live following, load earlier captions and re-enable follow. Confirm screen wake only while listening/viewing captions and normal sleep on Stop/background.
Perform a 30-minute read-along.

## Phase 4 storage and recovery
Start/speak/stop with auto-save on, force normal app termination/relaunch and open Sessions. Check title/date/duration/language, rename, title/finished-transcript search and confirmed delete.
Interrupt/terminate during listening: finalized saved segments should recover as an unfinished session; provisional text is not guaranteed.
Exercise low storage/write/startup failures. Errors must be visible, saving retry must not duplicate captions, and failed store opening must not destroy data.
Current session deletion is disabled until New Session.

## Phase 5 export
Open saved session > Export Text File to On My iPhone; inspect UTF-8 text and metadata. Copy to Notes and use Share Transcript.
Cancel native dialogs and confirm the session remains. Test unusual/long titles and large transcripts. Explicit destination sharing may transmit text.

## Phase 6 readiness/settings
Change preferences and relaunch. Check auto-save off requires Save Session; changing auto-save is disabled during a started unfinished session.
Test all actual readiness states, permission recovery and unknown/low disk space. Test Offline Mode is guidance, not Airplane Mode detection.
The 64 MB check reserves transcript headroom; initial model download may need much more.

## Phase 7 reliability
Follow reliability.md for 30/60/120-minute memory/CPU/battery/thermal/latency measurements.
Test calls/Siri, accessory input/configuration changes, media-service resets, lock/background, low battery/storage and missing model changes.
Unchanged built-in input can continue across accessory setup events; actual input loss or stopped-engine changes must stop capture.
Inject queue overflow/missing-frame/slow-finalization failures in debug builds and restore code before release.

## Phases 8–9 production gates
Inspect built privacy manifest/report, permission wording, store/WAL protection and backup exclusion, logs and actual network behavior after model setup.
Verify no automatic uploads, no stored audio, deletion and explicit sharing behavior.
Run Release simulator validation and signed device archive; check icon/dark/tinted variants, genuine screenshots and all release-checklist.md items.

## Evidence record
For each run record date, source commit, device/OS/SDK, scenario, result, latency/metrics, failure and retest. Every physical scenario above is currently pending.
