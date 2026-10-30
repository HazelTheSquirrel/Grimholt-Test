# Grimholt

**Grimholt** ist ein Godot-4-Projekt für ein Voxel-Sandbox-RPG mit Rollenspiel-Fokus. Ziel sind Singleplayer-Welten und private Multiplayer-Server ohne zentrale offizielle Spielserver.

## Aktueller technischer Stand

- Seedbasierte prozedurale Voxel-Terrain-Generierung
- 16 × 64 × 16 Voxel pro Chunk
- Chunk-Nachbarschaftsladen rund um den Spieler und Entfernen entfernter Chunks
- Mesh-Erzeugung nur für sichtbare Blockflächen und separate Chunk-Kollisionen
- First-Person-Bewegung mit Laufen, Sprinten und Springen
- Blockabbau per Linksklick und Erdplatzierung per Rechtsklick (Raycast, 6 Meter Reichweite)
- Persistente Speicherung geänderter Blöcke pro Chunk unter `user://worlds/default/chunks/`
- Welt-Metadaten mit Seed und Speicherformatversion unter `user://worlds/default/world.json`
- Geänderte Chunks werden beim Laden wiederhergestellt und beim Verlassen der Welt gespeichert

## Starten

1. Godot 4.7.2 öffnen.
2. Im Projektmanager **Importieren** wählen und `project.godot` auswählen.
3. Projekt öffnen und mit F6/F5 starten.

## Steuerung

| Taste | Funktion |
|---|---|
| W A S D | Bewegen |
| Maus | Umsehen |
| Leertaste | Springen |
| Shift | Sprinten |
| ESC | Maus freigeben |
| Linksklick | Block abbauen |
| Rechtsklick | Erdblock platzieren |

## Speicherung

Weltänderungen werden lokal im Godot-Benutzerverzeichnis gespeichert. Der aktuelle Prototyp verwendet eine feste Welt-ID (`default`) und speichert nur veränderte Voxel, nicht die vollständigen Chunk-Daten. Die Welt wird beim Beenden zusätzlich gesichert. Es gibt noch keine Oberfläche zum Erstellen, Umbenennen oder Löschen mehrerer Welten.

## Projektstruktur

    project.godot
    scenes/main.tscn
    scripts/main.gd
    scripts/player_controller.gd
    scripts/core/world_config.gd
    scripts/world/block_registry.gd
    scripts/world/voxel_chunk.gd
    scripts/world/world_generator.gd
    docs/ROADMAP.md
    .github/workflows/godot-check.yml

## Architektur und Grenzen

Voxel-Daten sind der maßgebliche Weltzustand; Meshes und Kollisionen werden daraus neu aufgebaut. Es gibt keine Node-Instanz pro Block. Chunk-Generierung, Mesh-Aufbau und Speichern laufen derzeit synchron auf dem Hauptthread. Vor großen Welten sind Hintergrundjobs, robustere Save-Transaktionen und Profiling erforderlich.

## Noch nicht implementiert

Biome, Höhlen, Vegetation, Wasser, Inventar, Crafting, Charakterentwicklung, NPCs, Dialoge, Quests, mehrere Welten, Multiplayer, Serveradministration und Windows-Installer sind noch nicht enthalten. Diese Funktionen werden nicht als bereits fertig dargestellt.

## Validierung

GitHub Actions prüft das Projekt mit Godot im Headless-Modus auf Import-/Parserfehler und startet anschließend einen kurzen Headless-Smoke-Test. Ein erfolgreicher CI-Lauf ersetzt keinen manuellen Spieltest mit Grafik, Eingabe und Kollisionen auf Windows.
