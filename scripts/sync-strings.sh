#!/bin/bash
# Werkt kader/Localizable.xcstrings bij met de teksten die nu in de code staan, zoals Xcode dat
# doet bij een build in de IDE. Nodig na het toevoegen of wijzigen van teksten buiten Xcode om,
# want xcodebuild vult de catalogus zelf niet aan.
#
# Gebruik (vanuit de projectmap):
#   scripts/sync-strings.sh          catalogus bijwerken
#   scripts/sync-strings.sh --check  alleen controleren; stopt met een fout als de catalogus achterloopt
#
# Vul daarna de ontbrekende vertalingen in (in Xcode of in het bestand zelf). LocalizationTests
# faalt zolang er een tekst zonder Nederlandse vertaling of een ongebruikte tekst in staat.
set -euo pipefail

cd "$(dirname "$0")/.."

CATALOG="kader/Localizable.xcstrings"
DERIVED_DATA="build/DerivedData"

echo "▸ Debug-build maken…"
xcodebuild \
    -project kader.xcodeproj \
    -scheme kader \
    -configuration Debug \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA" \
    -quiet \
    build

STRINGSDATA=$(find "$DERIVED_DATA/Build/Intermediates.noindex/kader.build/Debug/kader.build" -name '*.stringsdata' -not -name 'ExtractedAppShortcutsMetadata.stringsdata')

if [[ "${1:-}" == "--check" ]]; then
    TEMP=$(mktemp -d)
    trap 'rm -rf "$TEMP"' EXIT
    cp "$CATALOG" "$TEMP/Localizable.xcstrings"
    # shellcheck disable=SC2086
    xcrun xcstringstool sync "$TEMP/Localizable.xcstrings" --stringsdata $STRINGSDATA
    if ! diff -u "$CATALOG" "$TEMP/Localizable.xcstrings"; then
        echo "✗ $CATALOG loopt achter op de code. Draai scripts/sync-strings.sh en vul de vertalingen in." >&2
        exit 1
    fi
    echo "✓ $CATALOG is bij."
else
    # shellcheck disable=SC2086
    xcrun xcstringstool sync "$CATALOG" --stringsdata $STRINGSDATA
    echo "✓ $CATALOG bijgewerkt."
fi
