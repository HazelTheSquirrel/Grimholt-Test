# Grimholt

**Grimholt** ist ein Godot-4-Projekt für ein Voxel-Sandbox-RPG mit Rollenspiel-Fokus. Ziel sind Singleplayer-Welten und private Multiplayer-Server ohne zentrale offizielle Spielserver.

## Aktueller technischer Stand

- Seedbasierte prozedurale Voxel-Terrain-Generierung
- 16 × 64 × 16 Voxel pro Chunk
- Chunk-Nachbarschaftsladen rund um den Spieler und Entfernen entfernter Chunks
- Mesh-Erzeugung nur für sichtbare Blockflächen
- Separate statische Kollisionskörper pro Chunk
- Zentrale Block-IDs und Materialfarben
- First-Person-Bewegung mit Laufen, Sprinten und Springen

## Starten

1. Godot 4.7.2 öffnen.
2. Im Projektmanager **Importieren** wählen und project.godot auswählen.
3. Projekt öffnen und mit F6/F5 starten.

## Steuerung

| Taste | Funktion |
|---|---|
| W A S D | Bewegen |
| Maus | Umsehen |
| Leertaste | Springen |
| Shift | Sprinten |
| ESC | Maus freigeben |
| Linksklick | Maus wieder einfangen |

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

## Architektur

- world_config.gd: zentrale Weltparameter und Dimensionen.
- block_registry.gd: stabile Block-IDs und visuelle Grunddefinitionen.
- voxel_chunk.gd: Voxel-Daten eines Chunks sowie Mesh-/Kollisionsaufbau.
- world_generator.gd: Seed, Chunk-Verwaltung, Streaming und Weltabfragen.
- player_controller.gd: Spielersteuerung ohne direkte Abhängigkeit von Terrain-Details.

Voxel liegen in einem PackedByteArray, nicht als einzelne Nodes. Chunk-Meshes enthalten nur Flächen, deren Nachbarzelle Luft ist. Die aktuelle Generierung und Mesh-Erstellung laufen noch synchron auf dem Hauptthread. Das ist für den kleinen Prototypen bewusst einfach gehalten und muss vor großen Welten durch einen Worker-/Job-Ansatz ergänzt werden.

## Noch nicht implementiert

Blockabbau/-platzierung, Speichern veränderter Voxel, Biome/Vegetation/Höhlen, Inventar, Crafting, Charakterentwicklung, NPCs, Dialoge, Quests, persistente Welten, Multiplayer und Installer sind noch nicht enthalten. Diese Funktionen sind ausdrücklich nächste Entwicklungsziele und werden nicht als bereits fertig dargestellt.
