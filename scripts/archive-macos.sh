#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
if [[ "$(uname -s)" != "Darwin" ]]; then echo "Requires macOS and Xcode." >&2; exit 1; fi
: "${VREADER_TEAM_ID:?Set your Apple development team ID}"
: "${VREADER_BUNDLE_ID:?Set your final unique bundle identifier}"
if [[ "$VREADER_BUNDLE_ID" == com.example.* ]]; then
  echo "Replace the placeholder bundle identifier before release." >&2
  exit 1
fi
run_dir="$project_root/build/archive-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$run_dir"
xcodebuild -project vReader.xcodeproj -scheme vReader -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$run_dir/vReader.xcarchive" \
  DEVELOPMENT_TEAM="$VREADER_TEAM_ID" PRODUCT_BUNDLE_IDENTIFIER="$VREADER_BUNDLE_ID" \
  archive | tee "$run_dir/archive.log"
echo "Archive prepared for manual Organizer validation. Nothing was uploaded."
