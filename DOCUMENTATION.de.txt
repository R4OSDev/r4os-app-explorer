EXPLORER.R4X
============

EXPLORER.R4X ist die gehostete Desktop-Dateimanager-App.

Projektstruktur seit 0.51.20:
- `build.zig` baut die App als eigenes SDK-Projekt.
- `build.zig.zon` bindet `r4os_sdk` als Paket.
- `module.R4MF` beschreibt Artefakt, Zielpfad, R4DESK-/R4DRAW-Imports und Contract.

Build:

    cd Code\System\Software\Explorer
    ..\..\..\DevTools\Zig\zig.exe build

Ergebnis:

    Code\System\Software\Explorer\zig-out\EXPLORER.R4X

Contract:
- R4XStart-Entry: `explorer_main`
- App-Klasse: `gui`
- R4L-Imports: `R4SYS`, `R4DESK`, `R4DRAW`, `R4NET`, `R4DEV`
- Zielpfad im Image: `C:\R4OS\SOFTWARE\DESKTOP\EXPLORER.R4X`

Bedienung:
- Die Menues `File`, `Edit` und `View` bedienen die vorhandenen Dateiaktionen.
  `File > New` bietet `Folder` und `Text Document`; `View` schaltet die
  Adresszeile und aktualisiert die Ansicht.
- Doppelklicks auf Laufwerke und Ordner oeffnen die jeweilige Ansicht.
- `Ctrl+A` markiert alle Eintraege der aktuellen Ansicht. `Delete` loescht die
  ganze Auswahl nach einer zweiten ausdruecklichen Bestaetigung; andere
  Dateiaktionen verlangen weiterhin wieder eine einzelne Auswahl.
