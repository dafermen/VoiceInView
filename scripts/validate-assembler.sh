#!/bin/bash
# Focused macOS XCTest validation; does not build or launch the iOS app.
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This validation requires macOS and Swift 5.9+ with XCTest." >&2
  exit 1
fi
mkdir -p "$project_root/build"
run_dir="$(mktemp -d "$project_root/build/assembler-validation.XXXXXX")"
package_dir="$run_dir/Assembler"
mkdir -p "$package_dir/Sources/VoiceInView" "$package_dir/Tests/VoiceInViewTests"
cp "$project_root/VoiceInView/Models/TranscriptAssembler.swift" "$package_dir/Sources/VoiceInView/"
cp "$project_root/VoiceInViewUnitTests/TranscriptAssemblerTests.swift" "$package_dir/Tests/VoiceInViewTests/"
cat > "$package_dir/Package.swift" <<'SWIFT'
// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "VoiceInViewAssemblerValidation",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "VoiceInView"),
        .testTarget(name: "VoiceInViewTests", dependencies: ["VoiceInView"])
    ]
)
SWIFT
export CLANG_MODULE_CACHE_PATH="$run_dir/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$run_dir/ModuleCache"
echo "Validation artifacts: $run_dir"
# The generated package contains only the two local files above, no dependencies
# or plugins. Disable the nested SwiftPM sandbox to run in restricted workspaces.
swift test --package-path "$package_dir" --disable-sandbox 2>&1 | tee "$run_dir/tests.log"
