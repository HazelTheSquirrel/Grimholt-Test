# Grimholt

**Grimholt** ist ein kleines Godot-4.7.2-Testprojekt. Es bildet die technische Grundlage für ein späteres RPG-RP-Spiel.

## Aktueller Stand

- Prozedural generierte Landschaft mit Höhenvariation
- Farblich unterscheidbare Gras-, Erd-, Fels- und Uferbereiche
- Wasserfläche als Orientierungspunkt
- Statische Terrain-Kollision
- Spielbarer First-Person-Character
- Laufen, Sprinten, Springen und Maussteuerung
- HUD mit Steuerungshinweisen

## Starten

1. Godot **4.7.2** öffnen.
2. Im Projektmanager **Importieren** wählen.
3. Die Datei `project.godot` aus diesem Repository auswählen.
4. Projekt öffnen und mit **F6/F5** starten.

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

```
project.godot
scenes/
  main.tscn
scripts/
  main.gd
  player_controller.gd
  world_generator.gd
```

## Technische Hinweise

Die Landschaft wird beim Start aus zwei `FastNoiseLite`-Feldern aufgebaut. Aus den Höhenwerten entsteht ein zusammenhängendes Terrain-Mesh inklusive Trimesh-Kollision. Der Character ist ein `CharacterBody3D` mit Capsule-Collider und First-Person-Kamera.

Dieses Repository ist ausdrücklich ein **Testprojekt**, kein fertiges Spiel. Noch nicht enthalten sind Chunk-Streaming, Speichern/Laden, Inventar, Abbauen/Platzieren, NPCs, Quests oder Multiplayer. Die nächste Ausbaustufe sollte die Welt in Chunks aufteilen, bevor größere Welten erzeugt werden.
