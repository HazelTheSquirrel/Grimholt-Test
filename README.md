# Grimholt

**Grimholt** ist ein Fantasy-Sandbox-RPG in Godot 4.7.2. Die technische und visuelle Grundlage ist eine polygonbasierte 3D-Welt mit natürlichem Terrain, modularen Gebäuden und sammelbaren Weltressourcen – ausdrücklich kein Voxel- oder Blockspiel.

Das langfristige Ziel sind eine lebendige Fantasywelt, umfangreiche Berufe und Handwerksketten, Spielerbau, Erkundung und Rollenspiel. Das Spiel soll sowohl im Singleplayer als auch auf privat betriebenen Multiplayer-Servern funktionieren. Es sind keine offiziellen zentralen Spielserver vorgesehen.

## Download und Start

1. Dieses Repository über **Code → Download ZIP** herunterladen oder mit Git klonen.
2. Den Ordner `Grimholt` aus dem Repository beibehalten – er enthält das vollständige Godot-Projekt.
3. Godot **4.7.2** starten.
4. Im Godot-Projektmanager **Importieren** wählen und die Datei `Grimholt/project.godot` auswählen.
5. Projekt öffnen und mit F6/F5 starten.

**Wichtig:** Nicht die Repository-Wurzel, sondern `Grimholt/project.godot` ist die Godot-Projektdatei.

## Aktueller Prototyp

Der aktuelle Repository-Stand ist ein technischer Gameplay-Vertikalschnitt und noch kein fertiges Spiel:

- Godot 4.7.2 mit Forward+ Renderer.
- Prozedural erzeugtes polygonales Höhen-Terrain mit Mesh-Kollision.
- Third-Person-Spielersteuerung und Schulterkamera.
- Interaktionsbasierte Ressourcengewinnung über natürliche Weltobjekte:
  - Bäume liefern Rundholz.
  - Eisenadern liefern Eisenerz.
  - Kräuter liefern Alchemiezutaten.
- Datenbasierter Item-Katalog und Inventar.
- Erste Crafting-Rezepte für Eisenbarren, Holzplanken und Heiltränke.
- Berufserfahrung und einfache Levelberechnung für Schmiedekunst, Schreinerei und Alchemie.
- Modulares Platzieren von Holzfundamenten, Wänden und Dachsegmenten im Baumodus.
- Automatisierte Headless-Prüfungen für Projektimport, Start, Inventar, Crafting, Berufserfahrung und Ressourcenernte.

Die aktuell erzeugten Ressourcen und Bauteile sind Platzhalter-Prototypen. Hochwertige Charaktermodelle, Animationen, finale Umgebungsassets, vollständige Gebäude-Snap-Verbindungen und eine ausgearbeitete Benutzeroberfläche sind noch nicht enthalten.

## Steuerung

| Eingabe | Funktion |
|---|---|
| W A S D | Bewegen |
| Maus | Kamera drehen |
| Shift | Sprinten |
| Leertaste | Springen |
| E | Anvisierte Ressource ernten |
| C | Holzplanken herstellen (benötigt Rundholz) |
| B | Baumodus ein-/ausschalten |
| 1 | Holzfundament auswählen |
| 2 | Holzwand auswählen |
| 3 | Dachsegment auswählen |
| Linksklick im Baumodus | Bauteil platzieren |
| ESC | Maus freigeben |

## Spielsysteme und Designrichtung

### Welt und Ressourcen

Die Spielwelt besteht aus polygonalem Terrain, natürlichen Landschaftsformen und eigenständigen 3D-Objekten. Ressourcen sind Vorkommen in der Welt, keine abbaubaren Würfel. Geplant sind unter anderem Erzadern, Baumarten, Kräuter, Pilze, Jagdbeute, Stein, Lehm und seltene magische Materialien.

Ressourcen sollen über passende Werkzeuge und Sammelberufe gewonnen werden. Vorkommen, Respawn-Regeln, Werkzeugstufen und Ressourcenknoten werden serverseitig verwaltet werden, sobald Multiplayer implementiert wird.

### Berufe und Crafting

Die Datenstruktur ist auf voneinander abhängige Produktionsketten ausgelegt. Vorgesehene Sammelberufe sind Bergbau, Holzfällerei, Jagd, Fischerei und Kräuterkunde. Herstellungsberufe umfassen unter anderem Schmiedekunst, Schreinerei, Lederverarbeitung, Schneiderei, Alchemie und Kochen.

Der Prototyp enthält bereits ein kleines Rezept- und Berufssystem. Werkstattanforderungen, Rezeptfreischaltungen, Qualitätsstufen, Spezialisierungen und Wirtschaft sind Ausbauziele.

### Bausystem

Gebäude sollen aus modularen polygonalen Bauteilen entstehen, nicht aus Voxelblöcken. Vorgesehen sind Fundamente, Böden, Wände, Fenster, Türen, Dächer, Treppen, Zäune, Werkstätten und Lager. Das aktuelle Baumodus-Grundgerüst platziert einfache Holzfundamente, Wände und Dächer und zieht die Materialkosten aus dem Inventar ab.

### Multiplayer und private Server

Die Architektur soll langfristig serverautoritative Singleplayer- und Multiplayer-Simulation ermöglichen. Inventar, Ressourcen, Crafting, Bauplatzierung, Charakterdaten und Weltzustand dürfen im Multiplayer nicht vom Client allein bestimmt werden. Dedicated Server, private Serverkonfiguration, Persistenz, Administration und Backups sind noch nicht implementiert.

## Projektstruktur

```text
Grimholt/
├── project.godot
├── scenes/
├── scripts/
│   ├── data/
│   ├── systems/
│   └── world/
├── tests/
└── docs/
    └── ROADMAP.md

.github/
└── workflows/
    └── godot-check.yml
README.md
.gitignore
```

Alle Godot-Projektdateien, Skripte, Szenen, Tests und die spielbezogene Roadmap liegen gesammelt im Ordner `Grimholt/`. Die GitHub-Actions-Konfiguration bleibt außerhalb, damit GitHub sie automatisch erkennt.

## Technische Leitlinien

1. Polygonbasierte Weltgeometrie; keine Voxel- oder Blockwelt als Spielgrundlage.
2. Datengetriebene Definitionen für Items, Ressourcen, Rezepte, Berufe und Bauteile.
3. Weltobjekte und Ressourcen haben persistente IDs und serverseitig kontrollierte Zustände (für die spätere Multiplayer-Ausbaustufe).
4. Terrain, Vegetation, Gebäude und Props benötigen LOD, Instancing, Streaming und Profiling, bevor die Welt groß wird.
5. Singleplayer und Multiplayer sollen dieselben Gameplay-Regeln verwenden.
6. Keine offiziellen zentralen Spielserver; private Server bleiben das Ziel.

## Noch nicht fertig

Es fehlen unter anderem finale Art-Assets, Charaktererstellung, ausgereifte Animationen, Werkzeugsystem und Abbauzeiten, Respawn und Persistenz von Ressourcen, vollständige Berufe und Rezeptfreischaltungen, Händler und Spielerwirtschaft, Gebäude-Snap-System, Baurechte und Grundstücke, NPCs, Quests, Kampf, Speichern/Laden von Charakteren und Gebäuden, Multiplayer, Serveradministration sowie Windows-Installer.

## Validierung

GitHub Actions importiert und parst das Projekt mit Godot 4.7.2, führt einen Headless-Starttest aus und testet die zentralen Inventar-, Crafting-, Berufs- und Ressourcenernte-Funktionen. Diese automatisierten Prüfungen ersetzen keinen manuellen visuellen Spieltest unter Windows.
