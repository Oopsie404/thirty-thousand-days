#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="$ROOT/build/DerivedData"
APP="$DERIVED/Build/Products/Release/TrueTimeProgress.app"
INSTALL_APP="/Applications/光阴三万.app"

cd "$ROOT"

xcodebuild \
  -project TrueTimeProgress.xcodeproj \
  -scheme TrueTimeProgress \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  build

if [[ ! -d "$APP" ]]; then
  echo "Build completed but app was not found at $APP" >&2
  exit 1
fi

launchctl bootout "gui/$(id -u)/com.hang.TimeProgress.desktopwidget" 2>/dev/null || true
pkill -f "/Applications/TimeProgress.app/Contents/MacOS/TimeProgress" 2>/dev/null || true
pkill -f "/Applications/TrueTimeProgress.app/Contents/MacOS/TrueTimeProgress" 2>/dev/null || true
pkill -f "/Applications/时间进度.app/Contents/MacOS/TrueTimeProgress" 2>/dev/null || true
pkill -f "/Applications/三万天.app/Contents/MacOS/TrueTimeProgress" 2>/dev/null || true
pkill -f "/Applications/光阴三万.app/Contents/MacOS/TrueTimeProgress" 2>/dev/null || true
pkill -f "TrueTimeProgressWidgetExtension" 2>/dev/null || true

OLD_SETTINGS="$HOME/Library/Containers/com.hang.TrueTimeProgress.WidgetExtension/Data/Library/Application Support/TrueTimeProgress/settings.json"
NEW_SETTINGS="$HOME/Library/Containers/com.hang.TrueTimeProgress.Widgets/Data/Library/Application Support/TrueTimeProgress/settings.json"
if [[ -f "$OLD_SETTINGS" && ! -f "$NEW_SETTINGS" ]]; then
  mkdir -p "$(dirname "$NEW_SETTINGS")"
  cp "$OLD_SETTINGS" "$NEW_SETTINGS"
fi

rm -rf /Applications/TrueTimeProgress.app
rm -rf "$INSTALL_APP"
cp -R "$APP" "$INSTALL_APP"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u /Applications/TrueTimeProgress.app 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALL_APP"
pluginkit -r "$APP/Contents/PlugIns/TrueTimeProgressWidgetExtension.appex" 2>/dev/null || true
pluginkit -r /Applications/TrueTimeProgress.app/Contents/PlugIns/TrueTimeProgressWidgetExtension.appex 2>/dev/null || true
pluginkit -e ignore -i com.hang.TrueTimeProgress.WidgetExtension 2>/dev/null || true
pluginkit -e ignore -i com.hang.TrueTimeProgress.Widgets 2>/dev/null || true
pluginkit -a "$INSTALL_APP/Contents/PlugIns/TrueTimeProgressWidgetExtension.appex"
pluginkit -e use -i com.hang.TrueTimeProgress.Widgets

# xcodebuild may register the extension inside DerivedData. Keep only the
# installed copy so WidgetKit never has to choose between duplicate bundle IDs.
pluginkit -r "$APP/Contents/PlugIns/TrueTimeProgressWidgetExtension.appex" 2>/dev/null || true

open "$INSTALL_APP"

echo "Installed $INSTALL_APP"
echo "Open desktop Edit Widgets and search: 光阴三万"
