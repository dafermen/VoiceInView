# Development and validation
The source lives in C:\Projects\vReader on the current Windows host. Transfer the source ZIP or clone the local repository to a Mac to build.
Required: Xcode 26+, iOS 26+ SDK and iPhone simulator runtime. Current native capture API is selected for iOS 26; reassess the iOS 27 successor before upgrading SDK-specific code.

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
Script checks Xcode version, selects an available iOS 26+ iPhone simulator, builds Debug, runs shared-scheme tests, builds Release and checks the generated bundle's microphone purpose, assets and privacy manifest.
Optional: export VREADER_SIMULATOR_ID with an available iPhone simulator UDID.
Results/logs are retained under a unique build/validation timestamp directory. No existing results are deleted.
Use xcodebuild -showdestinations -project vReader.xcodeproj -scheme vReader to inspect destinations.
Both vReaderUnitTests and vReaderTests are in the shared scheme. Unit tests use mocks/in-memory or uniquely scoped temporary stores; they do not request microphone access.

## Physical iPhone
Open vReader.xcodeproj, select your team in Signing & Capabilities and a unique final bundle identifier. Enable Developer Mode as needed. Select an iOS 26+ compatible device and Run.
Use testing.md for microphone/offline/persistence/accessibility and reliability.md for long runs.
Do not store signing profiles, credentials or secrets in Git.

## Signed archive
After simulator/device checks:
~~~sh
export VREADER_TEAM_ID='YOUR_TEAM_ID'
export VREADER_BUNDLE_ID='YOUR_UNIQUE_BUNDLE_ID'
bash scripts/archive-macos.sh
~~~
The script rejects placeholder identifiers, archives for a physical iOS destination and uploads nothing. Xcode signing/profiles must already be configured. Review the archive in Organizer, including privacy/asset/signing reports.
All publication inputs and release-checklist.md gates must be resolved before distribution.

## Store/version rules
Source version 0.1.0/build 1. Local schema version 1, no CloudKit. No background audio entitlement.
Never delete/recreate a failed store automatically. Add a migration plan for future deployed schema changes.
Use small conventional local commits. No remote/push was configured during this work.
