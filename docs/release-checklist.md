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

## Must pass on Apple tooling
- [x] Debug simulator build (Xcode 15.2, iOS 17.2 SDK).
- [x] Compatibility suite: 56 unit tests and 12 UI scenarios across final full/focused runs, iOS 17.2 simulator.
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
- [ ] Latest upload finished processing and is assigned to Dev; record effective TestFlight version/build.
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

Before any new delivery, read [distribution runbook](distribution-runbook.md) and [known incidents](build-incidents.md). Cloud automatic export remains affected by the recorded 502; the local workaround succeeded once for Build 11.

Phase 10 online AI is excluded and remains unimplemented.
