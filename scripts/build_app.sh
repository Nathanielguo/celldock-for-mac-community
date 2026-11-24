#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
mkdir -p "$ROOT/.build/caches/clang" "$ROOT/.build/caches/swiftpm"
mkdir -p "$ROOT/.build/home"
export HOME="${HOME:-$ROOT/.build/home}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$ROOT/.build/caches}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT/.build/caches/clang}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-$ROOT/.build/caches/swiftpm}"
VERSION="${CELLDOCK_VERSION:-${MAVO_VERSION:-$(plutil -extract CFBundleShortVersionString raw "$ROOT/Resources/Info.plist")}}"
SOURCE_BUILD_VERSION="$(plutil -extract CFBundleVersion raw "$ROOT/Resources/Info.plist")"
BUILD_VERSION="${CELLDOCK_BUILD_VERSION:-$SOURCE_BUILD_VERSION}"
[[ -n "$VERSION" && "$VERSION" != */* ]] || {
  print -u2 "Invalid CellDock version: $VERSION"
  exit 1
}
[[ "$BUILD_VERSION" == <->(|.<->)(|.<->) ]] || {
  print -u2 "Invalid CellDock build version: $BUILD_VERSION"
  exit 1
}
SIGNING_MODE="${CELLDOCK_SIGNING_MODE:-release}"
case "$SIGNING_MODE" in
  release|development|community) ;;
  *)
    print -u2 "Invalid CellDock signing mode: $SIGNING_MODE"
    print -u2 "Use release, development, or community."
    exit 1
    ;;
esac
SIGN_IDENTITY="${CELLDOCK_CODESIGN_IDENTITY:-${MAVO_CODESIGN_IDENTITY:-}}"
if [[ -z "$SIGN_IDENTITY" && "$SIGNING_MODE" != community ]]; then
  SIGN_IDENTITY="$(
  security find-identity -v -p codesigning |
    awk -F'"' -v mode="$SIGNING_MODE" '
      mode == "release" && /"Developer ID Application:/ { print $2; exit }
      mode == "development" && /"Apple Development:/ { print $2; exit }
    '
  )"
fi
[[ -n "$SIGN_IDENTITY" ]] || {
  print -u2 "No compatible $SIGNING_MODE signing identity is available."
  if [[ "$SIGNING_MODE" == community ]]; then
    print -u2 "Community archives require CELLDOCK_CODESIGN_IDENTITY."
  else
    print -u2 "Set CELLDOCK_CODESIGN_IDENTITY to a stable code-signing identity."
  fi
  exit 1
}
SIGN_IDENTITY_RECORD="$({ security find-identity -v -p codesigning || true; } | grep -F "$SIGN_IDENTITY" | head -n 1 || true)"
[[ -n "$SIGN_IDENTITY_RECORD" && "$SIGN_IDENTITY" != "-" ]] || {
  print -u2 "CellDock archives require a certificate-backed code-signing identity."
  print -u2 "Ad-hoc signing is not allowed because it breaks signer pinning and Keychain continuity."
  exit 1
}
SIGN_CERT_SHA1="$(print -r -- "$SIGN_IDENTITY_RECORD" | awk '{ print $2; exit }')"
[[ ${#SIGN_CERT_SHA1} -eq 40 && "$SIGN_CERT_SHA1" != *[^[:xdigit:]]* ]] || {
  print -u2 "Could not resolve the signing certificate SHA-1 fingerprint."
  exit 1
}
APP_REQUIREMENT_OPTIONS=()
HELPER_REQUIREMENT_OPTIONS=()
if [[ "$SIGNING_MODE" == release ]]; then
  [[ "$SIGN_IDENTITY_RECORD" == *'"Developer ID Application:'* ]] || {
    print -u2 "CellDock release archives must use a Developer ID Application identity."
    exit 1
  }
  ARCHIVE_SUFFIX=""
  CODESIGN_OPTIONS=(--options runtime --timestamp)
elif [[ "$SIGNING_MODE" == development ]]; then
  [[ "$SIGN_IDENTITY_RECORD" == *'"Apple Development:'* ]] || {
    print -u2 "CellDock development archives must use a stable Apple Development identity."
    print -u2 "Ad-hoc signing is not allowed because it would break Keychain access."
    exit 1
  }
  ARCHIVE_SUFFIX="-development"
  CODESIGN_OPTIONS=(--timestamp=none)
else
  ARCHIVE_SUFFIX="-community-unnotarized"
  CODESIGN_OPTIONS=(--options runtime --timestamp=none)
  APP_REQUIREMENT_OPTIONS=(
    --requirements
    "=designated => identifier \"app.celldock.mac\" and certificate leaf = H\"$SIGN_CERT_SHA1\""
  )
  HELPER_REQUIREMENT_OPTIONS=(
    --requirements
    "=designated => identifier \"app.celldock.mac.network.helper\" and certificate leaf = H\"$SIGN_CERT_SHA1\""
  )
fi
OUTPUT_DIR="$ROOT/outputs"
APP="$OUTPUT_DIR/CellDock.app"
ZIP="$OUTPUT_DIR/CellDock-$VERSION-arm64$ARCHIVE_SUFFIX.zip"
PUBLISH_ZIP="$OUTPUT_DIR/.CellDock-$VERSION-arm64$ARCHIVE_SUFFIX.$$.zip"
STAGE_DIR="$(mktemp -d /tmp/CellDock-build.XXXXXX)"
STAGE_PACKAGE_DIR="$STAGE_DIR/package"
STAGE_APP="$STAGE_PACKAGE_DIR/CellDock.app"
STAGE_ZIP="$STAGE_DIR/CellDock-$VERSION-arm64$ARCHIVE_SUFFIX.zip"
VERIFY_DIR="$STAGE_DIR/verify"
VERIFY_APP="$VERIFY_DIR/CellDock.app"
ENTITLEMENTS="$ROOT/Resources/CellDock.entitlements"
HELPER_RELATIVE="Contents/Library/PrivilegedHelperTools/CellDockNetworkHelper"
VOWIFI_RUNTIME_RELATIVE="Contents/Library/PrivilegedHelperTools/CellDockVoWiFiRuntime"
PLIST_RELATIVE="Contents/Library/LaunchDaemons/app.celldock.mac.network.helper.plist"
[[ -f "$ENTITLEMENTS" ]] || {
  print -u2 "CellDock app entitlements are missing: $ENTITLEMENTS"
  exit 1
}
cleanup() {
  if [[ -e "$PUBLISH_ZIP" ]]; then
    mkdir -p "$STAGE_DIR/unpublished"
    mv -- "$PUBLISH_ZIP" "$STAGE_DIR/unpublished/"
    print -u2 "Preserved unpublished archive: $STAGE_DIR/unpublished/${PUBLISH_ZIP:t}"
  fi
}
trap cleanup EXIT

cd "$ROOT"
swift build --disable-sandbox -Xswiftc -disable-sandbox \
  -c release \
  --arch arm64
BIN_DIR="$(swift build --disable-sandbox -Xswiftc -disable-sandbox \
  -c release \
  --arch arm64 \
  --show-bin-path)"

mkdir -p "$OUTPUT_DIR"
mkdir -p \
  "$STAGE_APP/Contents/MacOS" \
  "$STAGE_APP/Contents/Frameworks" \
  "$STAGE_APP/Contents/Resources" \
  "$STAGE_APP/Contents/Library/PrivilegedHelperTools" \
  "$STAGE_APP/Contents/Library/LaunchDaemons"
cp "$ROOT/Resources/Info.plist" "$STAGE_APP/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$STAGE_APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD_VERSION" "$STAGE_APP/Contents/Info.plist"
cp "$ROOT/Resources/CellDock.icns" "$STAGE_APP/Contents/Resources/CellDock.icns"
cp "$ROOT/Resources/sim.svg" "$STAGE_APP/Contents/Resources/sim.svg"
cp "$ROOT/Resources/sim1.svg" "$STAGE_APP/Contents/Resources/sim1.svg"
cp "$ROOT/Resources/celldock-module-vertical.svg" "$STAGE_APP/Contents/Resources/celldock-module-vertical.svg"
cp -R "$ROOT/Resources/Localization/"*.lproj "$STAGE_APP/Contents/Resources/"
mkdir -p "$STAGE_APP/Contents/Resources/Sounds"
cp "$ROOT/Resources/Sounds/bleeps.wav" "$STAGE_APP/Contents/Resources/Sounds/bleeps.wav"
cp "$ROOT/Resources/Sounds/ring.mp3" "$STAGE_APP/Contents/Resources/Sounds/ring.mp3"
if [[ -d "$ROOT/Resources/ModuleVoice" ]]; then
  xcrun swift "$ROOT/scripts/build_module_voice_payload.swift" \
    "$ROOT/Resources/ModuleVoice" \
    "$STAGE_APP/Contents/Resources/ModuleVoice.payload" >/dev/null
fi
cp "$BIN_DIR/CellDock" "$STAGE_APP/Contents/MacOS/CellDock"
cp "$BIN_DIR/CellDockNetworkHelper" "$STAGE_APP/$HELPER_RELATIVE"
VOWIFI_GO_ROOT="$ROOT/ThirdParty/vowifi-go"
[[ -f "$VOWIFI_GO_ROOT/go.mod" && -d "$VOWIFI_GO_ROOT/vendor" ]] || {
  print -u2 "Vendored vowifi-go runtime source is missing."
  exit 1
}
mkdir -p "$STAGE_DIR/vowifi"
VOWIFI_RUNTIME_SOURCE="${CELLDOCK_VOWIFI_RUNTIME_SOURCE:-}"
if [[ -n "$VOWIFI_RUNTIME_SOURCE" ]]; then
  [[ -f "$VOWIFI_RUNTIME_SOURCE" ]] || {
    print -u2 "Configured VoWiFi runtime source does not exist: $VOWIFI_RUNTIME_SOURCE"
    exit 1
  }
  # The runtime is unchanged by this release. A verified universal binary from
  # the previous local community build may be supplied when Go is unavailable.
  cp "$VOWIFI_RUNTIME_SOURCE" "$STAGE_APP/$VOWIFI_RUNTIME_RELATIVE"
else
  command -v go >/dev/null 2>&1 || {
    print -u2 "Go is required to build CellDockVoWiFiRuntime; set CELLDOCK_VOWIFI_RUNTIME_SOURCE to an unchanged verified universal binary."
    exit 1
  }
  for GO_ARCH in arm64 amd64; do
    OUTPUT_ARCH="$GO_ARCH"
    [[ "$GO_ARCH" == amd64 ]] && OUTPUT_ARCH="x86_64"
    (
      cd "$VOWIFI_GO_ROOT"
      CGO_ENABLED=0 GOOS=darwin GOARCH="$GO_ARCH" \
        go build -mod=vendor -trimpath -ldflags='-s -w' \
        -o "$STAGE_DIR/vowifi/CellDockVoWiFiRuntime-$OUTPUT_ARCH" \
        ./cmd/celldock-vowifi-runtime
    )
  done
  lipo -create \
    "$STAGE_DIR/vowifi/CellDockVoWiFiRuntime-arm64" \
    "$STAGE_DIR/vowifi/CellDockVoWiFiRuntime-x86_64" \
    -output "$STAGE_APP/$VOWIFI_RUNTIME_RELATIVE"
fi
chmod 0755 "$STAGE_APP/$VOWIFI_RUNTIME_RELATIVE"
cp "$ROOT/Resources/app.celldock.mac.network.helper.plist" "$STAGE_APP/$PLIST_RELATIVE"
xattr -cr "$STAGE_APP"
codesign \
  --force \
  --sign "$SIGN_IDENTITY" \
  "${CODESIGN_OPTIONS[@]}" \
  --identifier app.celldock.mac.vowifi.runtime \
  "$STAGE_APP/$VOWIFI_RUNTIME_RELATIVE"
codesign \
  --force \
  --sign "$SIGN_IDENTITY" \
  "${CODESIGN_OPTIONS[@]}" \
  "${HELPER_REQUIREMENT_OPTIONS[@]}" \
  --identifier app.celldock.mac.network.helper \
  "$STAGE_APP/$HELPER_RELATIVE"
codesign \
  --force \
  --sign "$SIGN_IDENTITY" \
  "${CODESIGN_OPTIONS[@]}" \
  "${APP_REQUIREMENT_OPTIONS[@]}" \
  --entitlements "$ENTITLEMENTS" \
  --identifier app.celldock.mac \
  "$STAGE_APP"
codesign --verify --deep --strict --verbose=2 "$STAGE_APP"

for signed_code in \
  "$STAGE_APP/$VOWIFI_RUNTIME_RELATIVE" \
  "$STAGE_APP/$HELPER_RELATIVE" \
  "$STAGE_APP"; do
  codesign \
    --verify \
    --strict \
    --verbose=2 \
    --test-requirement "=certificate leaf = H\"$SIGN_CERT_SHA1\"" \
    "$signed_code"
done
if [[ "$SIGNING_MODE" == development && -d /Applications/CellDock.app ]]; then
  EXISTING_TEAM_ID="$(codesign -dvv /Applications/CellDock.app 2>&1 | awk -F= '$1 == "TeamIdentifier" && !found { print $2; found=1 }')"
  SIGNED_TEAM_ID="$(codesign -dvv "$STAGE_APP" 2>&1 | awk -F= '$1 == "TeamIdentifier" && !found { print $2; found=1 }')"
  [[ -n "$EXISTING_TEAM_ID" && "$SIGNED_TEAM_ID" == "$EXISTING_TEAM_ID" ]] || {
    print -u2 "Development signing Team ID does not match the installed CellDock app."
    print -u2 "Refusing to replace an app that may own incompatible Keychain records."
    exit 1
  }
fi

ditto -c -k --sequesterRsrc "$STAGE_PACKAGE_DIR" "$STAGE_ZIP"
mkdir -p "$VERIFY_DIR"
ditto -x -k "$STAGE_ZIP" "$VERIFY_DIR"

VERIFY_BINARY="$VERIFY_APP/Contents/MacOS/CellDock"
VERIFY_HELPER="$VERIFY_APP/$HELPER_RELATIVE"
VERIFY_VOWIFI_RUNTIME="$VERIFY_APP/$VOWIFI_RUNTIME_RELATIVE"
VERIFY_PLIST="$VERIFY_APP/$PLIST_RELATIVE"
VERIFY_ENTITLEMENTS="$STAGE_DIR/verify-entitlements.plist"
codesign --verify --deep --strict --verbose=2 "$VERIFY_APP"
codesign --verify --strict --verbose=2 "$VERIFY_HELPER"
codesign --verify --strict --verbose=2 "$VERIFY_VOWIFI_RUNTIME"
codesign --display --entitlements "$VERIFY_ENTITLEMENTS" --xml "$VERIFY_APP"
plutil -lint "$VERIFY_ENTITLEMENTS"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.device.audio-input' "$VERIFY_ENTITLEMENTS")" == "true" ]] || {
  print -u2 "Archive is missing the Audio Input entitlement."
  exit 1
}
[[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.personal-information.addressbook' "$VERIFY_ENTITLEMENTS")" == "true" ]] || {
  print -u2 "Archive is missing the Address Book entitlement."
  exit 1
}
if [[ "$SIGNING_MODE" != development ]]; then
  for hardened_code in "$VERIFY_APP" "$VERIFY_HELPER" "$VERIFY_VOWIFI_RUNTIME"; do
    HARDENED_SIGNING_INFO="$(codesign -dvv "$hardened_code" 2>&1)"
    [[ "$HARDENED_SIGNING_INFO" == *flags=*runtime* ]] || {
      print -u2 "Archive code is missing hardened runtime: $hardened_code"
      exit 1
    }
  done
fi
plutil -lint "$VERIFY_APP/Contents/Info.plist"
plutil -lint "$VERIFY_PLIST"
[[ "$(plutil -extract CFBundleShortVersionString raw "$VERIFY_APP/Contents/Info.plist")" == "$VERSION" ]] || {
  print -u2 "Archive Info.plist version does not match $VERSION."
  exit 1
}
[[ "$(plutil -extract CFBundleVersion raw "$VERIFY_APP/Contents/Info.plist")" == "$BUILD_VERSION" ]] || {
  print -u2 "Archive Info.plist build version does not match $BUILD_VERSION."
  exit 1
}
[[ "$(plutil -extract CFBundleIdentifier raw "$VERIFY_APP/Contents/Info.plist")" == "app.celldock.mac" ]] || {
  print -u2 "Archive app bundle identifier is incorrect."
  exit 1
}
[[ "$(plutil -extract CFBundleExecutable raw "$VERIFY_APP/Contents/Info.plist")" == "CellDock" ]] || {
  print -u2 "Archive app executable name is incorrect."
  exit 1
}
[[ "$(plutil -extract CFBundleDisplayName raw "$VERIFY_APP/Contents/Info.plist")" == "CellDock" ]] || {
  print -u2 "Archive app display name is incorrect."
  exit 1
}
if find "$VERIFY_DIR" -type f \
  \( -name 'THIRD_PARTY_NOTICES.md' \
     -o -name 'COPYING-LGPL-2.1' \
     -o -name 'COPYING-GPL-2.0' \
     -o -name 'COPYING-cJSON-MIT' \) \
  -print -quit | grep -q .; then
  print -u2 "Archive includes a license or notices file excluded from distribution."
  exit 1
fi
if find "$VERIFY_APP/Contents/Resources" -type f \
  \( -name 'THIRD_PARTY_NOTICES.md' -o -name 'MODULE-REPORT.md' \) \
  -print -quit | grep -q .; then
  print -u2 "Archive includes a documentation file excluded from app resources."
  exit 1
fi
[[ ! -e "$VERIFY_APP/Contents/Resources/ModuleVoice-Notices" ]] || {
  print -u2 "Archive includes the unused ModuleVoice-Notices app resource."
  exit 1
}
cmp -s \
  "$ROOT/Resources/sim.svg" \
  "$VERIFY_APP/Contents/Resources/sim.svg" || {
  print -u2 "Archive SIM account icon does not match the source resource."
  exit 1
}
cmp -s \
  "$ROOT/Resources/sim1.svg" \
  "$VERIFY_APP/Contents/Resources/sim1.svg" || {
  print -u2 "Archive Pro account icon does not match the source resource."
  exit 1
}
cmp -s \
  "$ROOT/Resources/celldock-module-vertical.svg" \
  "$VERIFY_APP/Contents/Resources/celldock-module-vertical.svg" || {
  print -u2 "Packaged device module SVG does not match the source resource."
  exit 1
}
cmp \
  "$ROOT/Resources/Sounds/bleeps.wav" \
  "$VERIFY_APP/Contents/Resources/Sounds/bleeps.wav"
cmp \
  "$ROOT/Resources/Sounds/ring.mp3" \
  "$VERIFY_APP/Contents/Resources/Sounds/ring.mp3"
for language in zh-Hans en ja fr; do
  localization_dir="$VERIFY_APP/Contents/Resources/$language.lproj"
  [[ -d "$localization_dir" ]] || {
    print -u2 "Archive is missing the $language localization."
    exit 1
  }
  plutil -lint "$localization_dir/Localizable.strings"
  plutil -lint "$localization_dir/InfoPlist.strings"
done
if [[ -d "$ROOT/Resources/ModuleVoice" ]]; then
  [[ -f "$VERIFY_APP/Contents/Resources/ModuleVoice.payload" ]] || {
    print -u2 "Archive is missing the QDC507 voice runtime."
    exit 1
  }
  cmp \
    "$STAGE_APP/Contents/Resources/ModuleVoice.payload" \
    "$VERIFY_APP/Contents/Resources/ModuleVoice.payload"
  if find "$VERIFY_APP" -type f -name '*.ko' -print -quit | grep -q .; then
    print -u2 "Archive exposes a standalone kernel module."
    exit 1
  fi
fi

[[ "$(lipo -archs "$VERIFY_BINARY")" == "arm64" ]] || {
  print -u2 "Archive executable is not thin arm64."
  exit 1
}
[[ "$(lipo -archs "$VERIFY_HELPER")" == "arm64" ]] || {
  print -u2 "Archive helper is not thin arm64."
  exit 1
}
VERIFY_VOWIFI_ARCHS=" $(lipo -archs "$VERIFY_VOWIFI_RUNTIME") "
[[ "$VERIFY_VOWIFI_ARCHS" == *" arm64 "* && "$VERIFY_VOWIFI_ARCHS" == *" x86_64 "* ]] || {
  print -u2 "Archive VoWiFi runtime is not Universal 2 (arm64 + x86_64)."
  exit 1
}
[[ "$(plutil -extract LSMinimumSystemVersion raw "$VERIFY_APP/Contents/Info.plist")" == "14.0" ]] || {
  print -u2 "Archive Info.plist does not require macOS 14.0."
  exit 1
}
[[ "$(vtool -show-build "$VERIFY_BINARY" | awk '$1 == "minos" { print $2; exit }')" == "14.0" ]] || {
  print -u2 "Archive executable minOS is not 14.0."
  exit 1
}
[[ "$(vtool -show-build "$VERIFY_HELPER" | awk '$1 == "minos" { print $2; exit }')" == "14.0" ]] || {
  print -u2 "Archive helper minOS is not 14.0."
  exit 1
}
[[ "$(codesign -dvv "$VERIFY_BINARY" 2>&1 | awk -F= '$1 == "Identifier" { print $2; exit }')" == "app.celldock.mac" ]] || {
  print -u2 "Archive executable signing identifier is incorrect."
  exit 1
}
[[ "$(codesign -dvv "$VERIFY_HELPER" 2>&1 | awk -F= '$1 == "Identifier" { print $2; exit }')" == "app.celldock.mac.network.helper" ]] || {
  print -u2 "Archive helper signing identifier is incorrect."
  exit 1
}
[[ "$(plutil -extract Label raw "$VERIFY_PLIST")" == "app.celldock.mac.network.helper" ]] || {
  print -u2 "LaunchDaemon label is incorrect."
  exit 1
}
[[ "$(plutil -extract ProgramArguments.0 raw "$VERIFY_PLIST")" == "/Library/PrivilegedHelperTools/CellDockNetworkHelper" ]] || {
  print -u2 "LaunchDaemon helper path is incorrect."
  exit 1
}
[[ "$(/usr/libexec/PlistBuddy -c 'Print :MachServices:app.celldock.mac.network.helper' "$VERIFY_PLIST")" == "true" ]] || {
  print -u2 "LaunchDaemon Mach service is missing."
  exit 1
}

while IFS= read -r dependency; do
  case "$dependency" in
    /System/Library/*|/usr/lib/*) ;;
    *)
      print -u2 "Archive contains a non-system dynamic dependency: $dependency"
      exit 1
      ;;
  esac
done < <(otool -L "$VERIFY_BINARY" | awk '/^[[:space:]]/ { print $1 }')

while IFS= read -r dependency; do
  case "$dependency" in
    /System/Library/*|/usr/lib/*) ;;
    *)
      print -u2 "Archive helper contains a non-system dynamic dependency: $dependency"
      exit 1
      ;;
  esac
done < <(otool -L "$VERIFY_HELPER" | awk '/^[[:space:]]/ { print $1 }')

cp "$STAGE_ZIP" "$PUBLISH_ZIP"
cmp "$STAGE_ZIP" "$PUBLISH_ZIP"
if [[ -e "$ZIP" ]]; then
  ZIP_BACKUP="$OUTPUT_DIR/${ZIP:t}.previous.$(date +%Y%m%d-%H%M%S)"
  mv -- "$ZIP" "$ZIP_BACKUP"
  print "Previous archive backup: $ZIP_BACKUP"
fi
mv -- "$PUBLISH_ZIP" "$ZIP"

# A loose app inside this FileProvider workspace can receive FinderInfo after
# signing, invalidating strict verification. This build emits only the verified
# ZIP and preserves any pre-existing loose app or prior archive for recovery.
print "Verified archive: $ZIP"
