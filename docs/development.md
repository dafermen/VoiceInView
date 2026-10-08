# Development
Use a Mac with Xcode 26+ and iOS 26+ SDK and simulator runtime. Windows is suitable for editing only.
Open vReader.xcodeproj. Select scheme vReader and an installed iPhone simulator.
The project uses Xcode file-system synchronized source groups; new source files inside the app/test groups are discovered by Xcode.

From the project root on macOS:
~~~sh
xcodebuild -list -project vReader.xcodeproj
xcodebuild -showdestinations -project vReader.xcodeproj -scheme vReader
xcodebuild -project vReader.xcodeproj -scheme vReader -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project vReader.xcodeproj -scheme vReader -destination 'platform=iOS Simulator,id=REPLACE_WITH_AVAILABLE_SIMULATOR_UDID' test
~~~
Replace the simulator identifier using showdestinations. Do not assume an installed device name.
For physical iPhone: choose your team in Signing & Capabilities, replace the placeholder bundle ID with a unique ID, enable Developer Mode if required, select the device and Run.
No team, signing assets or secrets are included. Version 0.1.0, build 1.
No background audio entitlement is declared. Review actual lifecycle requirements in the relevant phase.

## Phase 1 validation
The shared scheme runs vReaderUnitTests (mocked state tests) and vReaderTests (UI launch smoke test).
Microphone permission is requested only by the real Start Listening action; tests do not require real capture.
Build both Debug and Release on Mac and check the generated Info.plist microphone description.
The selected iOS 26 SDK uses installTap. Newer Apple documentation deprecates it at iOS 27, where installAudioTap becomes available; verify a migration with that SDK before upgrading the baseline.
Real microphone acceptance requires the physical iPhone checks in testing.md.