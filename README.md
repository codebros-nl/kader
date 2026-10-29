# Kader

[![CI](https://github.com/codebros-nl/kader/actions/workflows/ci.yml/badge.svg)](https://github.com/codebros-nl/kader/actions/workflows/ci.yml)

Kader is een vensterbeheerder voor macOS in de menubalk, in de geest van Rectangle Pro en Magnet. Zet vensters met een sneltoets of door ze naar een schermrand te slepen op een vaste plek, parkeer ze half buiten beeld en bewaar de indeling van al je vensters als layout.

## Functies

- **Sneltoetsen** voor helften, kwarten, derden, maximaliseren, centreren, herstellen en verplaatsen naar een ander scherm. Alle sneltoetsen zijn aan te passen.
- **Snappen** door een venster naar een rand of hoek te slepen, met een voorbeeld van de nieuwe plek. Per rand en hoek instelbaar.
- **Eigen zones**: een raster van zones dat verschijnt als je Shift ingedrukt houdt tijdens het slepen.
- **Parkeren (stashing)**: vensters half buiten beeld schuiven en in één keer terughalen.
- **Layouts**: de indeling van alle vensters opslaan en terugzetten, ook automatisch per schermopstelling.
- **Uitzonderingen**: apps die Kader met rust moet laten.
- **Opstarten bij inloggen** en een instellingenvenster met zijbalk zoals Systeeminstellingen.
- Interface in het Engels en Nederlands.

## Standaard sneltoetsen

Alle sneltoetsen gebruiken ⌃⌥ (Control + Option), zoals in Magnet.

| Actie | Sneltoets |
| --- | --- |
| Linker- / rechterhelft | ⌃⌥ ← / → |
| Bovenste / onderste helft | ⌃⌥ ↑ / ↓ |
| Linksboven / rechtsboven | ⌃⌥ U / I |
| Linksonder / rechtsonder | ⌃⌥ J / K |
| Eerste / middelste / laatste derde | ⌃⌥ D / F / G |
| Eerste / laatste twee derde | ⌃⌥ E / T |
| Maximaliseren | ⌃⌥ ↩ |
| Centreren | ⌃⌥ C |
| Herstellen | ⌃⌥ ⌫ |
| Volgend / vorig scherm | ⌃⌥⌘ → / ← |
| Links / rechts parkeren | ⌃⌥⇧ ← / → |
| Alles terughalen | ⌃⌥⇧ ↑ |

## Vereisten

- macOS 14 (Sonoma) of nieuwer
- Toegang via **Toegankelijkheid** (Systeeminstellingen → Privacy en beveiliging → Toegankelijkheid). Kader vraagt hier bij de eerste start om.
- Voor ontwikkelen: Xcode 27

## Bouwen en draaien

```sh
git clone git@github.com:codebros-nl/kader.git
cd kader
open kader.xcodeproj
```

Kies het schema **kader** en druk op ⌘R. Xcode haalt het pakket [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) zelf op.

Tests draaien vanaf de opdrachtregel:

```sh
xcodebuild test -project kader.xcodeproj -scheme kader -destination "platform=macOS" -only-testing:kaderTests
```

## Scripts

| Script | Wat het doet |
| --- | --- |
| `scripts/make-dmg.sh` | Bouwt een universele Release-versie en verpakt die in `build/Kader-<versie>.dmg`. |
| `scripts/sync-strings.sh` | Werkt `kader/Localizable.xcstrings` bij met de teksten uit de code. Met `--check` alleen controleren. |

De .dmg is gesigned met een Apple Development-certificaat en niet genotariseerd. Op een andere Mac moet je de app de eerste keer toestaan via Systeeminstellingen → Privacy en beveiliging → **Toch openen**.

## Vertalingen

De interface is in het Engels geschreven; de Nederlandse vertaling staat in `kader/Localizable.xcstrings`. `LocalizationTests` faalt zolang een tekst geen Nederlandse vertaling heeft of een vertaling niet meer gebruikt wordt. Voeg je teksten toe buiten Xcode om, draai dan eerst `scripts/sync-strings.sh`.

## Projectstructuur

```
kader/
  App/           opstarten en AppDelegate
  Windows/       vensteracties, schermgeometrie en geschiedenis
  Hotkeys/       sneltoetsen
  Snapping/      snappen door slepen en eigen zones
  Stashing/      vensters parkeren
  Layouts/       layouts opslaan en terugzetten
  Exclusions/    uitgezonderde apps
  Permissions/   toegankelijkheidstoestemming
  Menu/          menubalkmenu
  Settings/      instellingenvenster
kaderTests/      unittests (Swift Testing)
kaderUITests/    UI-tests
scripts/         .dmg en vertalingen
```

## Continue integratie

Bij elke push en pull request naar `main` bouwt GitHub Actions de app en draait de unittests (`.github/workflows/ci.yml`). De GitHub-runners hebben nog geen Xcode 27; de workflow zet het projectformaat daarom tijdelijk terug naar dat van Xcode 26 en bouwt zonder signing.
