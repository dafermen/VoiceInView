#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This validation requires macOS with Xcode 26 or later." >&2
  exit 1
fi
xcodebuild -version
major="$(xcodebuild -version | awk '/Xcode/{split($2,v,"."); print v[1]}')"
if (( major < 26 )); then echo "Xcode 26+ is required." >&2; exit 1; fi
run_dir="$project_root/build/validation-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$run_dir"
xcrun simctl list devices available -j > "$run_dir/simulators.json"
simulator_id="${VREADER_SIMULATOR_ID:-}"
if [[ -z "$simulator_id" ]]; then
  simulator_id="$(python3 - "$run_dir/simulators.json" <<'PY'
import json, re, sys
data = json.load(open(sys.argv[1]))
for runtime, devices in data["devices"].items():
    version = re.search(r"iOS-(\d+)", runtime)
    if version and int(version.group(1)) >= 26:
        for device in devices:
            if device.get("isAvailable") and "iPhone" in device["name"]:
                print(device["udid"])
                raise SystemExit(0)
raise SystemExit("Install an iOS 26+ iPhone simulator runtime.")
PY
)"
fi
derived="$run_dir/DerivedData"
xcodebuild -project vReader.xcodeproj -scheme vReader -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$derived" \
  CODE_SIGNING_ALLOWED=NO build | tee "$run_dir/debug-build.log"
xcodebuild -project vReader.xcodeproj -scheme vReader -configuration Debug \
  -destination "platform=iOS Simulator,id=$simulator_id" -derivedDataPath "$derived" \
  -resultBundlePath "$run_dir/Tests.xcresult" CODE_SIGNING_ALLOWED=NO test | tee "$run_dir/tests.log"
xcodebuild -project vReader.xcodeproj -scheme vReader -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$derived" \
  CODE_SIGNING_ALLOWED=NO build | tee "$run_dir/release-build.log"
app="$derived/Build/Products/Release-iphonesimulator/vReader.app"
plutil -lint "$app/Info.plist" "$app/PrivacyInfo.xcprivacy"
python3 - "$app" <<'PY'
import pathlib, plistlib, sys
app = pathlib.Path(sys.argv[1])
with (app / "Info.plist").open("rb") as f:
    info = plistlib.load(f)
assert info.get("NSMicrophoneUsageDescription"), "Missing microphone purpose"
assert not info.get("UIBackgroundModes"), "Unexpected background capture"
assert (app / "Assets.car").exists(), "Missing compiled assets"
with (app / "PrivacyInfo.xcprivacy").open("rb") as f:
    privacy = plistlib.load(f)
assert privacy.get("NSPrivacyTracking") is False, "Unexpected tracking"
print("Release simulator bundle checks passed.")
PY
echo "Validation artifacts: $run_dir"
echo "Physical iPhone, Airplane Mode, accessibility, privacy and extended-session gates still require manual checks."
