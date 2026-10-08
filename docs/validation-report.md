# Validation report — 2026-10-08

## iOS 17 / Xcode 15.2 compatibility migration

The user authorized this direction on 2026-10-08. See [ADR-006](decisions/ADR-006-xcode-15-compatibility.md). This section supersedes the earlier build-blocked status below.

Environment: MacBookPro14,2, macOS Ventura 13.7.8, Xcode 15.2 (15C500b), Swift 5.9.2, iOS Simulator 17.2 (21C62), iPhone 15 simulator. The project now targets iOS 17.0 with Swift 5 language mode and explicit Xcode-compatible file references.

### Implementation

- Added an offline-only SFSpeechRecognizer backend: explicit speech authorization, en-US availability/support checks before capture and each request, requiresOnDeviceRecognition=true, no remote fallback.
- Requests rotate after about 50 seconds of submitted audio. A bounded audio queue preserves frames during finalization; overflow, interruptions and finalization timeouts stop visibly. System models are prepared through iPhone settings; this engine has no in-app model downloader.
- Preserved the modern engine behind Swift compiler 6.2+ and iOS 26 availability checks. It was not compiled/tested with this older toolchain.
- Updated purpose strings, readiness/permission UI, privacy copy, project format, scripts and development instructions. Explicit MainActor annotations resolve SwiftUI isolation errors under Swift 5.9.
- Simulator tests exposed a real orphan-caption failure when deleting a session. The repository now explicitly deletes related captions and clears the active-session cache. The existing deletion regression passed after the correction.

### Executed verification

- Debug simulator build: **passed** (both x86_64 and arm64 slices).
- Release simulator build: **passed**, with minimum iOS 17.0, microphone and speech purpose strings, compiled assets, no background capture modes and the expected privacy manifest checked in the generated bundle. Installed and launched Release independently in the simulator; the caption screen, permission action, reading controls and navigation tabs rendered correctly without an automatic permission prompt.
- Full iOS 17.2 simulator suite after the deletion fix: **40 unit tests and 3 UI tests passed**, zero failures. Tests cover compatibility speech policy/lifecycle, existing microphone/caption view models, transcript assembly/export, time/settings, SwiftData reopen/order/deletion, launch, readiness/privacy navigation and microphone diagnostics. Launch checks include the absence of app/system permission alerts.
- All eight new compatibility speech tests passed: offline request flags, explicit permission and unsupported-device refusal, denied/restricted/unavailable states, rotation/final text, audio queued during finalization, cancellation/late callbacks, timeout and overflow.
- There are 41 unit test methods in source; the additional modern AudioConversion test is excluded by this compiler. The modern iOS 26 engine remains separately unverified.
- Focused final persistence rerun: all three repository tests passed after retaining temporary stores until OS cleanup; the earlier SQLite open-file deletion diagnostics no longer appeared.
- Project structure check: 115 object references resolve; all 37 Swift files are registered in targets; both test targets and local documentation links are valid. Mac shell scripts pass bash -n and git diff --check passes. The Windows PowerShell validator was updated but was not executed on this Mac.

### Evidence

Generated logs and result bundles remain under build/ and are ignored by Git:
- build/compatibility-debug.log: successful Debug compilation.
- build/compatibility-release.log: successful Release compilation.
- build/compatibility/release-launch.png: visually inspected standalone Release launch.
- build/compatibility-tests.log and build/compatibility/Tests.xcresult: first full run, which exposed the deletion failure.
- build/compatibility-tests-fixed.log and build/compatibility/Tests-fixed.xcresult: full suite passed after the fix.
- build/compatibility-repository-tests.log and build/compatibility/Repository-tests.xcresult: three final persistence regressions passed without SQLite cleanup diagnostics.

Run bash scripts/validate-macos.sh for Debug, unit/UI tests, Release and bundle checks. Set VOICEINVIEW_SIMULATOR_ID to choose a particular installed compatible simulator. The focused bash scripts/validate-assembler.sh is still available.

### Physical iPhone follow-up

The iPhone was detected again over USB. The compatibility app compiled for the physical arm64 iPhone platform, and a generic iOS build was signed with an existing Apple Development identity (development bundle ID override: com.dafermen.vReader). Logs: build/device-build.log and build/device-generic-signed-build.log. No signing settings or credentials were added to the repository.

A build addressed directly to the phone timed out with “Waiting to reconnect.” A more detailed developer-image probe returned CoreDevice error 10003: **the device is locked**. This corrects the earlier assumption that the mounting failure alone established an Xcode/iOS compatibility problem. A subsequent lock-state probe reported passcodeRequired=false. Retrying developer-image activation then failed with a different error: 0xe8000076 / kAMDMobileImageMounterImageMountFailed, “Could not support development.” The connection therefore remains blocked after the locked-device error was cleared. Evidence: build/device-ddi.log and build/device-ddi-retry.log.

The signed bundle passed codesign verification outside workspace isolation. Its embedded provisioning profile still does not include this phone; registration/profile refresh remains necessary. The direct-device build could not register it because the destination never became eligible. No installable-for-this-phone build was produced and no app was installed.

Apple documents hardware support updates through xcodebuild -runFirstLaunch -checkForNewerComponents ([component documentation](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components)); the installed Xcode 15.2 help does not expose the newer component-update option. No system/Xcode update or third-party device image was installed. Actual speech tests remain pending.

### Requested installation retry

On the next user-requested retry, USB pairing was available but developer-image activation again failed with error 0xe8000076 (“Could not support development”). The direct-device signed build timed out with the phone marked ineligible/waiting to reconnect. A separate attempt to install the already-signed physical-device app using devicectl device install app also failed during developer-image mounting, before app installation or profile validation. Logs: build/device-ddi-latest.log, build/device-retry-build.log and build/device-install-retry.log. No physical installation or speech test succeeded.

### Remaining device/release gates

Real speech, offline asset availability, accuracy, continuity at request boundaries, microphone/permission recovery, 30/60/120-minute behavior, accessibility, binary privacy/network review and a signed archive remain pending. Mocked speech tests do not prove transcription quality or offline operation. The connected iPhone 15 reported iOS 27.0.1 and Developer Mode enabled, but developer-image activation failed first while locked and then with “Could not support development” on retry. Compatible developer services and a profile including the phone are still required. No build was installed on the physical iPhone.

## Before the compatibility migration: original iOS 26 target blocked
Base commit: 9b4bafb3e8226e83c0516b505b6e42e364f2031d, plus the local assembler fix and regression test described below.

Environment: MacBookPro14,2 (Intel x86_64, 16 GB RAM), macOS Ventura 13.7.8 (22H730), Xcode 15.2 (15C500b), Swift 5.9.2. Selected developer directory: /Applications/Xcode 15.2.app/Contents/Developer.

The project requires Swift 6 and the iOS 26 SDK. Running bash scripts/validate-macos.sh exited with status 1 and "Xcode 26+ is required." It stopped before Debug build, simulator testing or Release build. An initial simctl probe also failed under workspace restrictions; it does not establish whether runtimes are installed. No iOS app was compiled or launched.

Apple lists [Xcode 26 as requiring macOS Sequoia 15.6 or later](https://developer.apple.com/xcode/system-requirements) and [MacBookPro14,2 as a 2017 model whose newest supported OS is Ventura](https://support.apple.com/en-us/108052). Full validation therefore needs a different supported build host, local or remote; an ordinary supported OS/Xcode update on this model cannot meet the requirement.

### Connected iPhone check — 2026-10-08

A USB check detected an iPhone. The initial restricted devicectl probe reported no devices; repeating it outside workspace isolation detected a paired, available iPhone 15. Device details reported iOS 27.0.1 (24A446), a wired connection and Developer Mode enabled. Device identifiers and serial numbers are intentionally omitted from this report.

The details command warned: "The developer disk image could not be mounted on this device" and reported ddiServicesAvailable=false. Xcode remains 15.2. The physical connection and pairing are confirmed, but developer services and app installation/debugging are not validated. No app was installed or launched. Full device testing needs a build host with the required SDK and Xcode support for the connected phone's OS.

### Executed checks
- Native plutil validation passed for project.pbxproj and PrivacyInfo.xcprivacy.
- Project structure: all 37 object references resolve, three targets, both scheme test targets, source directories and both microphone usage descriptions checked.
- Privacy plist tracking flag, asset catalog JSON and opaque RGB 1024x1024 icon checks passed. These are source checks, not a binary privacy audit.
- Swift 5.9.2 parsed all 34 Swift files successfully with swiftc -frontend -parse. This is syntax parsing, not type checking of the app or validation of iOS 26 API signatures/concurrency.
- All three Mac shell scripts passed bash -n; git diff --check passed.
- Seven original TranscriptAssembler XCTests passed against the unchanged source in an isolated native macOS Swift package, including the 10,000-segment case.
- A new regression test reproduced a late-revision ordering error: after runs "One" then "Two", revising the first run produced "Two / One revised.". The assembler now remembers run order even when replacing every existing segment of a run, preserving segment identity and returning "One revised. / Two".
- After the fix, bash scripts/validate-assembler.sh compiled the actual assembler source and ran all eight assembler XCTests: **8 passed, 0 failures**. No Speech/SwiftData/UI substitutes were included; those components were not tested.

### Local evidence and reproduction
Run bash scripts/validate-assembler.sh to repeat the focused tests. The script creates a fresh package from the repository source/test files and retains logs under build/assembler-validation.*. These generated artifacts are ignored by Git.

Evidence from this validation:
- build/validation-local/assembler-tests.log: original seven tests passed.
- build/validation-local/assembler-regression-before.log: new regression failed before the fix (eight tests, one failure).
- build/assembler-validation.9HQRoh/tests.log: all eight tests passed after the fix.
- build/validation-local/swift-parse.log: empty diagnostics from successful syntax parsing before the assembler fix; the modified assembler was subsequently compiled by the focused test run.

The suite now contains 33 unit tests and three UI tests. Only the eight assembler tests have executed; the remaining 25 unit tests and all three UI tests are pending. Microphone capture, real English captions, Airplane Mode, model installation, SwiftData persistence, export/share UI, accessibility, signing and extended reliability remain unverified. No claim of app or release readiness follows from these focused tests.

## Historical Windows validation — 2026-10-07
### Executed and passed on Windows
- OpenStep project syntax parsed, all 37 object references resolved.
- Three targets, synchronized source groups and both shared-scheme test targets checked.
- Microphone purpose in Debug and Release configurations verified.
- Privacy manifest XML and UserDefaults CA92.1 / DiskSpace E174.1 reasons checked.
- Asset catalog JSON parsed; icon is 1024x1024 opaque RGB PNG and visually inspected.
- App Store draft name/subtitle/keyword bytes/description lengths checked against documented limits.
- Authored-file whitespace and local documentation links checked.
- Swift delimiter/source-surface inspection; no application HTTP client, legacy recognizer, audio-file recorder or apparent secret pattern found.
- Mac shell-script syntax checked using Git Bash bash -n.
- 32 unit tests and 3 UI tests confirmed present, not executed.
- Git diff --check required before the final local commit.

### Not executed / not verified at that time
Xcode/Swift compilation, XCTest, simulator launch, microphone capture, actual English captions, Airplane Mode speech, asset installation, physical persistence/share/permission behavior, accessibility, network/privacy binary report, store-sidecar protection, device matrix, signed Release archive and 30/60/120-minute profiling.
xcodebuild is unavailable on this Windows host. These are open acceptance gates, not passing results.

## Next full validation
Run bash scripts/validate-macos.sh on a Mac, resolve compiler/test failures, execute testing.md and reliability.md on physical compatible iPhones, and finish release-checklist.md with owner identity/signing/URLs/license details.
The source is implementation-ready for this validation handoff; App Store readiness is not certified.

## TestFlight preparation (2026-10-08)

- Configured automatic signing for team `7799N4RYUG`, app ID `com.dafermen.vReader`, and matching test target identifiers. Apple registration is pending.
- Release arm64 device build passed with Xcode 15.2 and signing disabled after the configuration change. Bundle metadata verified: version 0.1.0, build 1, minimum iOS 17.0. Log: `build/testflight-preparation-build.log`.
- Prepared branch `codex/testflight-preparation` for Xcode Cloud. Cloud onboarding, a build with an eligible Xcode 26+ SDK, TestFlight upload, and physical speech testing remain pending. This local build is not an uploaded or distribution-signed binary.

## VoiceInView rename (2026-10-08)

- Renamed the Xcode project, shared scheme, app/test targets and source folders to VoiceInView. Updated user-visible captions title, permission descriptions, privacy text, export fallback, metadata, scripts and documentation.
- Kept `com.dafermen.vReader`, the existing test bundle identifiers and the internal `vReader/Sessions.store` location. The schema and model definitions were not changed. Migration from a previously installed development build has not been separately tested.
- Debug simulator build passed. On iPhone SE (3rd generation), iOS 17.2: 40 unit tests and 3 UI tests passed with zero failures, including the new navigation title and transcript export fallback.
- Release simulator build passed. Verified display name/executable `VoiceInView`, unchanged bundle identifier, iOS 17 minimum, microphone/speech purpose strings, compiled assets and privacy manifest.
- Project references, shared-scheme targets, metadata field lengths, shell-script syntax and Git whitespace checks passed. The PowerShell validator was updated but not executed on this Mac.
- Logs/result bundle: `build/rename-validation.log` and `build/validation-20261008-113618/Tests.xcresult`. These checks ran before moving the workspace folder from vReader to VoiceInView; log paths retain the former directory. Earlier validation artifacts belonged to the previous checkout and were deleted when the user replaced that checkout.
- The GitHub repository is now `dafermen/VoiceInView`. App Store Connect name registration, Xcode Cloud onboarding/build and TestFlight upload remain pending.
