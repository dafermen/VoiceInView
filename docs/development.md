# Development and validation
The source is checked out at /Users/dariomeneses/Projects/VoiceInView on macOS Ventura 13.7.8 with Xcode 15.2. The compatibility target is iOS 17.0 with Swift 5 language mode (Swift 5.9 compiler).
Required: Xcode 15.2+ and a compatible iOS 17+ SDK/runtime. The project uses explicit file references and build phases; add new files to their target in Xcode. The modern speech files are conditionally compiled with compiler(>=6.2) and gated to iOS 26; older compilers use LegacySpeechTranscriber. See [ADR-006](decisions/ADR-006-xcode-15-compatibility.md) for the compatibility decision.
A device running a much newer iOS can still need newer Xcode developer services. The connected iOS 27.0.1 phone initially failed to mount its developer image; a detailed follow-up identified a locked-device error. After that error cleared, a retry failed with “Could not support development.” The current developer-image services and phone provisioning therefore still block physical installation; see validation-report.md for both diagnostics.

## Windows static checks
~~~powershell
pwsh -File scripts/validate-static.ps1
~~~
Checks project OpenStep syntax/references, scheme, source groups, permission configurations, manifest XML, metadata limits, icon/asset files, source delimiters/surfaces and script syntax when Git Bash exists.
It does not compile Swift or execute XCTest.

## Mac simulator build and tests
~~~sh
bash scripts/validate-macos.sh
~~~
Script checks Xcode version, selects an available iOS 17+ iPhone simulator, builds Debug, runs shared-scheme tests, builds Release and checks the generated bundle's microphone/speech purposes, deployment target, assets and privacy manifest.
Optional: export VOICEINVIEW_SIMULATOR_ID with an available iPhone simulator UDID.
Results/logs are retained under a unique build/validation timestamp directory. No existing results are deleted.
Use xcodebuild -showdestinations -project VoiceInView.xcodeproj -scheme VoiceInView to inspect destinations.
Both VoiceInViewUnitTests and VoiceInViewTests are in the shared scheme. Unit tests use mocks/in-memory or uniquely scoped temporary stores; they do not request microphone access.

## Focused assembler tests on older Macs
~~~sh
bash scripts/validate-assembler.sh
~~~
Requires macOS 13+ and Swift 5.9+ with XCTest (the current Xcode 15.2 host can run it). The script copies the unmodified assembler source and its XCTest file into an isolated, dependency-free temporary Swift package under build/, then executes those tests. Logs and generated package files stay in that directory. This does not build the iOS application or test Speech, SwiftData, microphone capture or UI. This focused script does not replace the full simulator suite.

## Physical iPhone
Open VoiceInView.xcodeproj. Signing uses team `7799N4RYUG` and bundle identifier `com.dafermen.vReader`; the identifier still needs registration with Apple for distribution. Enable Developer Mode as needed. Select an iOS 17+ compatible device and Run.
Use testing.md for microphone/offline/persistence/accessibility and reliability.md for long runs.
Do not store signing profiles, credentials or secrets in Git.

## Signed archive
After simulator/device checks:
~~~sh
export VOICEINVIEW_TEAM_ID='YOUR_TEAM_ID'
export VOICEINVIEW_BUNDLE_ID='YOUR_UNIQUE_BUNDLE_ID'
bash scripts/archive-macos.sh
~~~
The script rejects placeholder identifiers, archives for a physical iOS destination and uploads nothing. Xcode signing/profiles must already be configured. Review the archive in Organizer, including privacy/asset/signing reports.
All publication inputs and release-checklist.md gates must be resolved before distribution.

## Store/version rules
Source version 0.1.0/build 1. Local schema version 4 with additive V1→V2→V3→V4 migrations, no CloudKit. UIBackgroundModes includes audio; continuation is per-session opt-in.
Never delete/recreate a failed store automatically. Add a migration plan for future deployed schema changes.
Use small conventional local commits. The origin remote is https://github.com/dafermen/VoiceInView.git.

## First TestFlight build with Xcode Cloud
Apple requires Xcode 26 or later and the iOS 26 SDK or later for current uploads. Xcode 15.2 remains useful for local compatibility development, but its archives do not meet that upload requirement. Use an eligible stable Xcode version in the cloud build environment; the app's minimum iOS version remains 17.

1. Open `VoiceInView.xcodeproj` in Xcode and choose **Integrate > Create Workflow**. Select the VoiceInView product and team `7799N4RYUG`. Sign in with the Apple account used for MetodoMogollon if requested.
2. Review the workflow: shared scheme `VoiceInView`, eligible stable Xcode 26 or later, and an **Archive** action for iOS with **TestFlight (Internal Testing Only)** distribution preparation. If these options are unavailable in the initial assistant, edit the workflow in App Store Connect after onboarding.
3. Grant Xcode Cloud access to `dafermen/VoiceInView` on GitHub. Use `main` for the first build after the rename commit has been pushed.
4. If Apple requests an app record, use name `VoiceInView`, bundle ID `com.dafermen.vReader`, primary language English (US), and SKU `voiceinview-ios`. Register the bundle ID with this team if it is missing. If the app name is unavailable, choose an available display name without changing the bundle ID.
5. After the archive succeeds, open VoiceInView in App Store Connect > TestFlight. Resolve any required build information, create an internal testing group, and add your own eligible App Store Connect user and the build. Accept the invitation on the iPhone and install through TestFlight.

No Capacitor, npm, CocoaPods, or custom post-clone script is needed for this native project. The MetodoMogollon post-clone script should not be copied here. The first cloud build must also validate the modern speech code, which cannot be compiled by local Xcode 15.2. Cloud onboarding, upload, and real-device speech tests are still pending.

References: [Apple's initial setup](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow), [distribution workflow](https://developer.apple.com/documentation/xcode/creating-a-workflow-that-builds-your-app-for-distribution), [SDK requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a).
