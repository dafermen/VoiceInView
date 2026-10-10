# Release checklist
This is a gate, not a claim that release is approved.

## Prepared in source
- [x] iOS 17 deployment and native SwiftUI project.
- [x] On-device Apple speech boundary and explicit English model setup.
- [x] Partial/final captions, reading controls, pause/resume and session history.
- [x] Local-only storage, reversible transcript corrections and explicit TXT/PDF export/share.
- [x] Microphone and Speech Recognition usage descriptions in Debug/Release.
- [x] Privacy manifest and policy/metadata drafts.
- [x] AppIcon asset and Mac validation/archive scripts.
- [x] Unit/UI tests and physical validation procedures.
- [x] Persistent capture choices, compact controls and V5 recovery draft lifecycle in build 14 source.
- [ ] Build 14 delivered through TestFlight and new workflow verified on the iPhone.

## Must pass on Apple tooling
- [x] Debug simulator build (Xcode 15.2, iOS 17.2 SDK).
- [x] Latest session workflow: 59 compatible unit tests and two targeted UI scenarios, iOS 17.2 simulator. The earlier media delivery passed 56 unit tests and 12 UI scenarios; the full older UI suite was not rerun for build 14.
- [x] Modern source compiled/archived in Cloud, including Xcode 26.6 Build 11.
- [ ] Modern AudioConversion test executed on Xcode 26+/iOS 26+.
- [x] Release simulator build and bundle/plist/privacy/asset checks (Xcode 15.2).
- [ ] Real compatible iPhone English Dictation/model setup and offline recognition, including 50-second request transitions.
- [ ] Airplane Mode/Wi-Fi-off transcription proof and latency recording.
- [ ] Missing model/unsupported hardware/permission-denied recovery.
- [ ] Start/Stop and Pause/Resume without duplicates or unwanted restart.
- [ ] Save/relaunch/rename/search/delete/export/clipboard/share tests.
- [ ] Low storage/save failure/interruption/route/lock/background tests.
- [ ] Largest Dynamic Type, VoiceOver, contrast, reduced motion and rotation.
- [ ] 30/60/120 minute memory/CPU/battery/thermal sessions.
- [ ] Inspect store/WAL file protection and backup exclusion.
- [ ] Network/privacy/log review after model setup.
- [x] Cloud Build 11 archive exported with distribution signing and uploaded from the Mac (2026-10-10).
- [x] First local upload processed as 0.1.0 (1), assigned to Dev (screenshots 2026-10-10 04:37).
- [x] Same feature archive re-signed, verified and uploaded as 0.1.0 (13) with explicit numbering.
- [x] User confirmed the iPhone update and working audio/background switches after the build 13 delivery; no new screenshot of the installed build number was supplied.
- [ ] Physical acceptance of the latest recording/subtitle features.
- [ ] Full public-release archive/privacy review. Successful upload alone does not certify it.

## Required owner inputs before public release
- [x] Existing bundle ID com.dafermen.vReader and team 7799N4RYUG verified in successful export.
- [ ] Licensing/copyright/publisher decision.
- [ ] Real support URL/contact and published privacy policy URL.
- [ ] Final App Privacy/age-rating/export-compliance answers.
- [ ] Tested device compatibility statement.
- [ ] Approved icon and genuine current screenshots.
- [ ] Final version/build/release notes.
- [ ] App Review notes and submission review.

Before any new delivery, read [distribution runbook](distribution-runbook.md) and [known incidents](build-incidents.md). Cloud automatic export remains affected by the recorded 502; the local workaround exported/uploaded the Build 11 archive as TestFlight 1 and then a re-numbered copy as 13.

Phase 10 online AI is excluded and remains unimplemented.
