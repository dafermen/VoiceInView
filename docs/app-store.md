# App Store preparation — Phase 9
Status: release materials prepared; NOT a validated release candidate and NOT submitted.
Current Apple guidelines, privacy details and metadata/icon documentation checked 2026-10-07.

## Positioning and metadata
Name: VoiceInView. App Store Connect registration and name availability remain pending.
Subtitle: Live English Captions (21 characters).
Tagline: See what's being said.
Draft description, keywords, version/build and release notes: app-store-metadata.json.
Do not publish draft claims until the feature, offline and supported-device tests pass.

## Owner inputs still required
Publisher/copyright/license decision, public Support URL with contact, published Privacy Policy URL, privacy contact and App Store Connect access.
Signing uses team `7799N4RYUG` and the existing bundle identifier `com.dafermen.vReader`. The display-name change does not change that identity. No signing material or secrets are stored in source.

## Supported device and offline representation
iOS 17 minimum. The compatibility engine requires on-device English support and Speech Recognition permission; builds with Xcode 26+ use the modern speech engine on iOS 26+ when available. Establish a real tested device matrix before submission. OS version alone does not guarantee compatibility.
Prepare English Dictation or install the modern engine's English model while online, then validate Airplane Mode with Wi-Fi off. Initial model preparation is not offline. No cloud fallback or online AI is present.
Captions can be wrong due to distance, noise, accent, speed, obstruction, simultaneous speakers and device hardware.
Capture is foreground-only. Lock/background/interruption stops it; no automatic resume.

## Screenshots and icon
Prepared 1024x1024 opaque caption-bubble icon in the AppIcon asset catalog; design approval and Xcode asset validation pending. Check system-generated dark/tinted appearance.
Capture actual app screens from a validated build at current App Store Connect-required iPhone sizes:
- Live captions with a non-sensitive sample speech source.
- Paused/readable history and text-size controls.
- Saved sessions and transcript.
- Offline Readiness and explicit English model setup.
- Settings/privacy.
Do not use fabricated feature screenshots or imply live captioning is validated while it is not.

## Launch and versioning
Generated native launch screen, explicit store-loading/failure/retry states and no first-launch microphone prompt.
Version 0.1.0, build 1. Increment build numbers for each uploaded binary; choose final public version before submission.

## App Privacy draft
Based on current source: no developer collection or tracking, no account/advertising/analytics. Local audio/transcripts are not transmitted by the app; user sharing uses the chosen destination.
Confirm this against the built binary, Apple's asset service behavior and the final archive privacy report. The publisher must submit accurate answers; draft notes are not filed declarations.

## Age rating / export compliance
Complete the current age-rating questionnaire for actual features; no public feed, messaging, ads or developer-provided mature content exists.
No custom cryptography implementation is included; storage protection uses OS facilities. Review the actual encryption questionnaire and applicable requirements before setting export-compliance declarations. No automatic exemption statement is added to Info.plist.

## App Review notes draft
No login. On a supported iPhone, Settings > Offline Readiness checks microphone, English model and storage. Install the model with Internet, then use Captions > Start Listening. Audio stays local. Pause/Resume retains earlier captions; Stop saves finalized segments when auto-save is on. Sessions supports rename/delete/export. Locking or leaving the app stops capture.
Provide exact tested device/OS details, permission setup instructions and known limitations after validation.

## Validation
Run scripts/validate-macos.sh, manual iPhone checklist and reliability matrix. Run scripts/archive-macos.sh with final team/identifier and inspect the archive in Organizer. Do not upload until release-checklist.md is complete.
No Release compilation, archive validation, accessibility/device profiling or submission was possible on Windows.

Sources:
https://developer.apple.com/app-store/review/guidelines/
https://developer.apple.com/app-store/app-privacy-details/
https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
https://developer.apple.com/documentation/xcode/configuring-your-app-icon
