#!/bin/bash
# Bouwt een Release-versie van Kader en verpakt die in een .dmg met een snelkoppeling naar Programma's.
#
# Gebruik (vanuit de projectmap):
#   scripts/make-dmg.sh
#
# Resultaat: build/Kader-<versie>.dmg, met een universele app (Apple silicon en Intel).
#
# De app wordt gesigned met het Apple Development-certificaat uit het project, niet met een Developer ID
# en zonder notarisatie. Op een andere Mac blokkeert macOS de app daarom bij de eerste keer openen:
# open dan Systeeminstellingen → Privacy en beveiliging en kies "Toch openen".
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
STAGING="$BUILD_DIR/dmg"
APP_NAME="Kader"

echo "▸ Release-build maken…"
xcodebuild \
    -project kader.xcodeproj \
    -scheme kader \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$DERIVED_DATA" \
    -quiet \
    clean build

BUILT_APP="$DERIVED_DATA/Build/Products/Release/kader.app"
if [[ ! -d "$BUILT_APP" ]]; then
    echo "✗ Build niet gevonden op $BUILT_APP" >&2
    exit 1
fi

echo "▸ Handtekening controleren…"
codesign --verify --deep --strict "$BUILT_APP"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$BUILT_APP/Contents/Info.plist")
DMG="$BUILD_DIR/$APP_NAME-$VERSION.dmg"

echo "▸ .dmg samenstellen…"
rm -rf "$STAGING"
mkdir -p "$STAGING"
# De bundelnaam mag verschillen van de productnaam; de handtekening dekt alleen de inhoud.
ditto "$BUILT_APP" "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Programma's"

rm -f "$DMG"
if diskutil image create from --help > /dev/null 2>&1; then
    # Opvolger van hdiutil create (macOS 26 en nieuwer).
    CREATE=(diskutil image create from --format ULFO --volumeName "$APP_NAME $VERSION" "$STAGING" "$DMG")
else
    CREATE=(hdiutil create -volname "$APP_NAME $VERSION" -srcfolder "$STAGING" -format ULFO -ov "$DMG")
fi
# Voortgang alleen tonen als het misgaat.
if ! OUTPUT=$("${CREATE[@]}" 2>&1); then
    echo "$OUTPUT" >&2
    exit 1
fi
rm -rf "$STAGING"

echo "✓ $DMG"
