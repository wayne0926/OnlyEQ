#!/bin/bash
# Build OnlyEQ.app from the SwiftPM package (no Xcode required).
#   ./scripts/build-app.sh            debug build, host arch
#   ./scripts/build-app.sh release    universal (arm64 + x86_64) release build
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
APP="build/OnlyEQ.app"
SPARKLE_ROOT=".build/artifacts/sparkle/Sparkle"
SPARKLE_FRAMEWORK="$SPARKLE_ROOT/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"

if [ "$CONFIG" = "release" ]; then
    # CLT has no xcbuild, so multi-arch needs per-triple builds + lipo.
    swift build -c release --triple arm64-apple-macosx14.4
    swift build -c release --triple x86_64-apple-macosx14.4
    mkdir -p build
    lipo -create \
        .build/arm64-apple-macosx/release/OnlyEQ \
        .build/x86_64-apple-macosx/release/OnlyEQ \
        -output build/OnlyEQ-universal
    BIN="build/OnlyEQ-universal"
    RESOURCE_BUNDLE=".build/arm64-apple-macosx/release/OnlyEQ_OnlyEQ.bundle"
else
    swift build -c "$CONFIG"
    BIN="$(swift build -c "$CONFIG" --show-bin-path)/OnlyEQ"
    RESOURCE_BUNDLE="$(swift build -c "$CONFIG" --show-bin-path)/OnlyEQ_OnlyEQ.bundle"
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp Resources/Info.plist "$APP/Contents/"
cp "$BIN" "$APP/Contents/MacOS/OnlyEQ"
# SwiftPM links binary frameworks through @rpath but does not know this custom
# app bundle's Frameworks location. Add it before signing the bundle.
install_name_tool -add_rpath '@executable_path/../Frameworks' "$APP/Contents/MacOS/OnlyEQ"
[ -d "$RESOURCE_BUNDLE" ] && cp -R "$RESOURCE_BUNDLE" "$APP/Contents/Resources/"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"
if [ ! -d "$SPARKLE_FRAMEWORK" ]; then
    echo "Sparkle framework not found at $SPARKLE_FRAMEWORK" >&2
    exit 1
fi
# ditto preserves the framework's symlinks and nested helper signatures.
ditto "$SPARKLE_FRAMEWORK" "$APP/Contents/Frameworks/Sparkle.framework"
cp "$SPARKLE_ROOT/LICENSE" "$APP/Contents/Resources/Sparkle-LICENSE.txt"

# Ad-hoc sign with an explicit identifier-based designated requirement. A plain
# ad-hoc signature gets a cdhash-based requirement that changes on every build,
# so TCC (System Audio Recording) forgets the grant and re-prompts after each
# rebuild. Pinning the requirement to the bundle identifier keeps the grant.
codesign --force --sign - \
    --identifier com.onlyeq.app \
    --requirements '=designated => identifier "com.onlyeq.app"' \
    "$APP"

echo "Built $APP"
