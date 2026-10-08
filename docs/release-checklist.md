# Release checklist
This is a gate, not a claim that release is approved.

## Prepared in source
- [x] iOS 26 deployment and native SwiftUI project.
- [x] On-device Apple speech boundary and explicit English model setup.
- [x] Partial/final captions, reading controls, pause/resume and session history.
- [x] Local-only storage and explicit text export/share.
- [x] Microphone usage description in Debug/Release.
- [x] Privacy manifest and policy/metadata drafts.
- [x] AppIcon asset and Mac validation/archive scripts.
- [x] Unit/UI tests and physical validation procedures.

## Must pass on Apple tooling
- [ ] Debug simulator build.
- [ ] All unit and UI tests.
- [ ] Release simulator build and bundle/plist/privacy/asset checks.
- [ ] Real compatible iPhone English model installation.
- [ ] Airplane Mode/Wi-Fi-off transcription proof and latency recording.
- [ ] Missing model/unsupported hardware/permission-denied recovery.
- [ ] Start/Stop and Pause/Resume without duplicates or unwanted restart.
- [ ] Save/relaunch/rename/search/delete/export/clipboard/share tests.
- [ ] Low storage/save failure/interruption/route/lock/background tests.
- [ ] Largest Dynamic Type, VoiceOver, contrast, reduced motion and rotation.
- [ ] 30/60/120 minute memory/CPU/battery/thermal sessions.
- [ ] Inspect store/WAL file protection and backup exclusion.
- [ ] Network/privacy/log review after model setup.
- [ ] Signed device archive and Organizer validation.

## Required owner inputs before distribution
- [ ] Final bundle ID and signing team.
- [ ] Licensing/copyright/publisher decision.
- [ ] Real support URL/contact and published privacy policy URL.
- [ ] Final App Privacy/age-rating/export-compliance answers.
- [ ] Tested device compatibility statement.
- [ ] Approved icon and genuine current screenshots.
- [ ] Final version/build/release notes.
- [ ] App Review notes and submission review.

Phase 10 online AI is excluded and remains unimplemented.
