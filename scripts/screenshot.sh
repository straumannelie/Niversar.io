#!/bin/zsh
set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-$HOME/Applications/Xcode.app/Contents/Developer}"

root="${0:A:h:h}"
cd "$root"

simulator_name="${SIMULATOR_NAME:-iPhone 16e}"
derived_data="$root/build/sim"
screenshots="$root/build/screenshots"
app_path="$derived_data/Build/Products/Debug-iphonesimulator/Niversario.app"

simulator_udid() {
    local devices_json
    devices_json="$(mktemp)"
    xcrun simctl list devices available --json > "$devices_json"
    jq -r --arg name "$simulator_name" '
        [.devices[][] | select(.name == $name) | .udid] | first // empty
    ' "$devices_json"
    rm -f "$devices_json"
}

udid="${SIMULATOR_ID:-$(simulator_udid)}"
if [[ -z "$udid" ]]; then
    echo "Simulateur « $simulator_name » introuvable. Passe SIMULATOR_NAME ou SIMULATOR_ID." >&2
    exit 1
fi

echo "==> Simulateur : $simulator_name ($udid)"
xcrun simctl bootstatus "$udid" -b >/dev/null
xcrun simctl status_bar "$udid" override --time 9:41 --batteryLevel 100 --cellularBars 4 --wifiBars 3

echo "==> Compilation (Debug, simulateur)"
xcodebuild \
    -project Niversario.xcodeproj \
    -scheme Niversario \
    -configuration Debug \
    -destination "id=$udid" \
    -derivedDataPath "$derived_data" \
    -quiet \
    build

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist")"

echo "==> Installation et lancement $*"
xcrun simctl terminate "$udid" "$bundle_id" 2>/dev/null || true
xcrun simctl install "$udid" "$app_path"
xcrun simctl launch "$udid" "$bundle_id" "$@" >/dev/null
sleep "${SCREENSHOT_DELAY:-4}"

mkdir -p "$screenshots"
label="${(j:_:)@}"
label="${label//[^A-Za-z0-9_]/}"
screenshot="$screenshots/$(date +%Y%m%d-%H%M%S)${label:+-$label}.png"
xcrun simctl io "$udid" screenshot "$screenshot" >/dev/null 2>&1
echo "==> Capture : $screenshot"
