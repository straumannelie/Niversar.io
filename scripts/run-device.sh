#!/bin/zsh
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-$HOME/Applications/Xcode.app/Contents/Developer}"

root="${0:A:h:h}"
cd "$root"

derived_data="$root/build"
app_path="$derived_data/Build/Products/Debug-iphoneos/Niversario.app"

connected_iphone_udid() {
    local devices_json
    devices_json="$(mktemp)"
    xcrun devicectl list devices --quiet --json-output "$devices_json" >/dev/null
    jq -r '
        [.result.devices[]
            | select(.hardwareProperties.deviceType == "iPhone")
            | select(.connectionProperties.pairingState == "paired")
            | select(.connectionProperties.tunnelState == "connected")
            | .hardwareProperties.udid]
        | first // empty
    ' "$devices_json"
    rm -f "$devices_json"
}

device_id="${DEVICE_ID:-$(connected_iphone_udid)}"
if [[ -z "$device_id" ]]; then
    echo "Aucun iPhone connecté. Branche-le directement sur le Mac, ou passe DEVICE_ID=<udid>." >&2
    exit 1
fi
echo "==> Appareil : $device_id"

echo "==> Compilation (Debug)"
xcodebuild \
    -project Niversario.xcodeproj \
    -scheme Niversario \
    -configuration Debug \
    -destination "id=$device_id" \
    -derivedDataPath "$derived_data" \
    -allowProvisioningUpdates \
    -quiet \
    build

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist")"

echo "==> Installation"
xcrun devicectl device install app --device "$device_id" "$app_path"

echo "==> Lancement de $bundle_id"
xcrun devicectl device process launch --device "$device_id" --terminate-existing "$bundle_id"
