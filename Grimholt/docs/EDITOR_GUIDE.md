# Godot-Editor: Szenenstruktur und Bearbeitung

Das Godot-Projekt liegt unter `Grimholt/project.godot`. Importiere genau diese Datei – nicht den Repository-Ordner und nicht einen eventuell darüberliegenden Download-Ordner.

## Hauptszene öffnen

1. Im Godot-Projektmanager das Projekt `Grimholt` öffnen.
2. Im Dateisystem zu `res://scenes/main.tscn` wechseln.
3. `main.tscn` doppelklicken.
4. Oben links im Szenen-Dock den Szenenbaum aufklappen.

Die Hauptszene enthält jetzt ausdrücklich angelegte Nodes. Sie werden nicht erst vollständig zur Laufzeit per Skript erzeugt.

```text
Grimholt
├── WorldEnvironment
├── Sun
├── TerrainWorld
│   └── GeneratedTerrain (vom Terrain-Tool erzeugt)
│       ├── TerrainSurface
│       └── TerrainCollision
├── PlayerSpawn (Marker3D – editierbarer Startpunkt)
├── PlayerBuildings
└── Player
    ├── CollisionShape3D
    ├── BodyVisual
    ├── CameraPivot
    │   └── Camera3D
    ├── Inventory
    └── HUD
        ├── StatusLabel
        └── Crosshair
```

## Was ist direkt bearbeitbar?

- **TerrainWorld:** Terrain-Generator. Im Inspector lassen sich Ausdehnung, Zellgröße und Seed einstellen. Das generierte Terrain wird im Editor angezeigt.
- **PlayerSpawn:** Marker3D für die horizontale Startposition. Die Höhe wird beim Start anhand der tatsächlich generierten Terrain-Funktion berechnet.
- **Player:** Spieler-Node, Kollisionsform, sichtbarer Platzhalterkörper und Kamera sind einzelne Szenen-Nodes. Alte Spielstände mit einer Position unter dem Gelände werden beim Laden auf den Startpunkt zurückgesetzt.
- **PlayerBuildings:** Container für platzierte Gebäudeteile.
- **WorldEnvironment / Sun:** Himmel, Umgebungslicht und Sonnenlicht.
- **HUD:** Statusanzeige und Fadenkreuz.

Das Terrain-Mesh wird aus den Generator-Einstellungen erzeugt. Die generierte Geometrie ist kein handmodelliertes Einzelmesh; passe dafür die Export-Eigenschaften von `TerrainWorld` an.

## Farb-Legende des aktuellen Prototyps

- Grün: Grasland und Vegetation
- Olivgrün: tiefere, moosige Geländeabschnitte
- Grau: steilere/felsigere Terrainbereiche und Eisenadern
- Braun: Baumstämme und Holzbauteile
- Violett mit goldener Mitte: sammelbare Heilkräuter

Die Farben sind vorläufige Gameplay-Farben, damit Ressourcen und Geländearten im frühen Prototyp gut unterscheidbar sind. Sie sind noch keine finalen Art-Assets.
