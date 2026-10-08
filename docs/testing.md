# Testing
## Execution status
Windows host: Apple build, XCTest execution, simulator and real iPhone checks NOT RUN.
Static checks PASSED: OpenStep project syntax, 37 object references, three targets, two scheme test targets, Debug/Release microphone purpose, source group paths, test presence, local documentation links and whitespace. These checks are not Swift compilation.
Phase 0 acceptance remains unverified; its home screen has evolved into the Phase 1 capture screen by explicit user authorization.

## Automated tests
Shared vReader scheme includes:
- vReaderUnitTests: twelve mocked tests for grant/start/stop/repeat, denied access, pending grant, Stop/background during permission, startup/cleanup failures, interruption/route/configuration/media events, background/foreground behavior and denied/unknown permission.
- vReaderTests: launch shows capture controls, Stop initially disabled, no launch permission prompt, captions disclosure.
Run Product > Test or the commands in development.md. Unit tests do not operate microphone hardware. No passing XCTest result is claimed yet.

## Phase 1 manual iPhone procedure
Use an iOS 26+ physical iPhone. Record device/OS, Xcode/SDK, date, build result, XCTest result and actual observations.
1. Install and launch: vReader title, capture section, state, meter and Start/Stop. No microphone dialog at launch.
2. Fresh permission: tap Start Listening. Verify system dialog shows the usage description. Grant permission. Expect Listening and system microphone indicator.
3. Speak near the built-in microphone: meter rises with sound and falls in silence. No captions or audio playback. A zero level in a quiet room is not an error.
4. Stop: expect Ready, zero meter and microphone indicator clears after system delay. Repeat start/stop at least 20 times; no crash, duplicate tap or stuck listening.
5. Deny on a fresh install/permission reset: expect clear denied/restricted message, no listening and Open Settings. Enable access in Settings, return, then tap Start; no automatic capture.
6. While permission is pending, tap Stop if controls are accessible. Also background while the permission prompt is open, then resolve it. Returning must not start capture from that stale request.
7. Background or lock while listening: capture stops. Unlock/return: no automatic restart; explicitly Start again.
8. Receive a call or invoke Siri: expect stopped listening/error and no automatic restart. End the interruption and explicitly restart.
9. Connect/disconnect an audio accessory: where a route notification occurs, expect safe stop and a message. Restart uses the built-in phone microphone. Route behavior differs by accessory; record observations.
10. Unavailable input, audio session conflict or engine failure: expect a recoverable error rather than Listening. Simulator can supplement checks but does not prove device capture.
11. Debug missing-buffer failure: temporarily stop yielding levels at the tap in a local debugging build. After approximately five seconds, expect a stopped session and missing-audio error. Restore code before commit.
12. Airplane Mode: repeat Start, speak, Stop. Microphone monitoring requires no Internet. This is not an offline transcription test.
13. Accessibility: light/dark, portrait/landscape, largest Dynamic Type and VoiceOver. Controls readable/scrollable, state/error described and touch targets usable.
14. Run Debug and Release simulator builds; inspect the generated app Info.plist for NSMicrophoneUsageDescription in both configurations.
15. Check permission restrictions on a managed/restricted device if available. Apple may report denied; do not expect a separate restricted enum.

## Pending future validation
Phase 2: en-US model readiness, actual Airplane Mode transcription, partial/final text assembly and measured latency.
Later: distance/noise, accents/speaking speed, technical speech, multi-speaker situations, low storage/battery, Bluetooth support and 30/60/120 minute profiling.
