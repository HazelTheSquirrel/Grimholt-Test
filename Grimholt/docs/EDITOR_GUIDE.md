# Godot-Editor: Szenenstruktur und Spielersteuerung

Das Godot-Projekt liegt unter `Grimholt/project.godot`. Importiere genau diese Datei.

## Maßstab und Spieler

Grimholt verwendet verbindlich **1 Godot-Einheit = 1 Meter**. Die Spieler-Kapsel ist exakt **1,75 m** hoch und **0,60 m** breit (Radius 0,30 m). Ihr Ursprung liegt am Boden; die Kollisionsform sitzt mittig bei Y = 0,875 m. Die Kamera sitzt auf 1,58 m Augen-/Kopfhöhe.

## Szenenstruktur

```text
Player (CharacterBody3D)
├── CollisionShape3D          # CapsuleShape3D: 1,75 m
├── BodyVisual                # getrennte Darstellung
├── CameraPivot               # Maussteuerung / Blickrichtung
│   └── Camera3D              # Third-Person, per Mausrad bis Ego
├── InteractionComponent      # Raycast, Fokus und Interaktionsaufruf
├── Inventory
└── HUD
    ├── StatusLabel
    └── Crosshair
```

## Bewegung

- WASD: Bewegung relativ zur Kamera
- Shift: Sprint (4,2 m/s gehen; 6,2 m/s sprinten)
- Leertaste: Springen
- Maus: Kamera drehen
- Mausrad: Kameraabstand stufenweise zwischen Ego- und Third-Person
- ESC: Maus freigeben; Mausklick: wieder einfangen

Die horizontale Geschwindigkeit wird über Beschleunigungs- und Bremswerte aufgebaut, nicht direkt auf die Zielgeschwindigkeit gesetzt. Am Boden gelten 14 m/s² Beschleunigung und 18 m/s² Verzögerung; in der Luft ist die Steuerung auf 4 m/s² reduziert. Die Gravitation kommt aus Godots Projekteinstellung.

## Interaktionsarchitektur

`GrimholtInteractionComponent` ist eine eigenständige Komponente am Spieler. Sie fragt vom Kamerazentrum aus bis zu 5 m nach einem Physik-Treffer und akzeptiert Ziele mit einer Methode `interact(actor)`. Optional liefert ein Ziel `get_interaction_prompt()` für die HUD-Anzeige.

- Ressourcenobjekte implementieren `interact(actor)` und leiten die Aktion an ihr Inventar-/Harvest-System weiter.
- Türen können `GrimholtInteractableDoor` verwenden. Das Script schaltet den Öffnungswinkel weich um.
- Weitere RP-Objekte (Türen, Truhen, Schalter, Gesprächspartner) implementieren denselben Vertrag, ohne den Player-Controller zu ändern.

Die Interaktion verändert Gameplay-Zustand über das Zielobjekt. Die Komponente kümmert sich nur um Fokus, Reichweite und Aufruf. Für späteren Multiplayer muss die eigentliche Zustandsänderung serverseitig autorisiert werden.

## Welt und weitere Nodes

```text
Grimholt
├── WorldEnvironment
├── Sun
├── TerrainWorld
├── PlayerSpawn
├── PlayerBuildings
└── Player
```

Terrain, Weltzustand und Darstellung bleiben getrennt. Der Third-Person-Charakter ist weiterhin ein Platzhalter-Mesh; Animationen und ein finaler Charakter-Controller sind noch nicht vorhanden.
