# Grimholt: Arena

Grimholt ist ein eigenständiger First-Person-Arena-Shooter. Die spielerische Qualitätsreferenz ist klassisches Arena-FPS-Design: klare Bewegungsregeln, lesbare Gefechte, präzise Treffer-Rückmeldung, unterschiedliche Waffenrollen und ein fokussiertes HUD. Halo 3 ist ausschließlich eine abstrakte Referenz. Sämtliche Namen, Karten, Waffen, Figuren, UI-Elemente, Audioinhalte und Assets werden eigenständig entwickelt.

## Aktueller Entwicklungszweig

Der Branch `rebuild/halo-inspired-fps-foundation` enthält den Neuaufbau der Gameplay-Grundlage. Der alte Prototyp bleibt vorerst in den historischen Pfaden erhalten, damit bestehende Implementierungen und Assets nicht versehentlich verloren gehen.

### Neuer spielbarer Kern

- First-Person-Controller mit WASD, Mausblick und Springen.
- Eigenständige Pulse-Carbine-Szene mit Hitscan-Trefferprüfung, Feuerrate, Magazin und Nachladen.
- Spieler-Gesundheit und Trefferreaktion.
- Fünf Arena-Bots mit einfacher Verfolgung und Angriff.
- Kill-Punkte und Bot-Respawn.
- Eine Greybox-Arena mit sichtbarer Geometrie, Licht, Kollision und Deckung.
- HUD als eigene Godot-Szene mit Score, Timer, Gesundheit und Munition.
- Gameplay-Systeme sind auf einzelne GDScript-Dateien verteilt; sichtbare Objekte und UI liegen in editierbaren `.tscn`-Szenen.

## Projekt öffnen

1. Godot **4.7.2** installieren.
2. Die Datei `Grimholt/project.godot` öffnen/importieren.
3. Das Projekt starten.

## Steuerung

| Eingabe | Aktion |
|---|---|
| WASD | Bewegen |
| Maus | Umschauen und zielen |
| Linksklick halten | Feuern |
| Leertaste | Springen |
| R | Nachladen |
| ESC | Maus freigeben |

Nach dem Start wird direkt eine lokale Arena-Runde mit fünf Bots geladen. Linksklick in das Spielfenster fängt die Maus wieder ein.

## Architektur

- `scenes/player/`: Spieleraufbau und Kamera.
- `scenes/weapons/`: Waffen- und Viewmodel-Szenen.
- `scenes/enemies/`: Gegner-Szenen.
- `scenes/levels/`: Levelgeometrie und Kollision.
- `scenes/ui/`: HUD und weitere UI-Szenen.
- `scripts/player/`: Bewegung und Spielergesundheit.
- `scripts/combat/`: Waffenlogik und Trefferprüfung.
- `scripts/ai/`: Bot-Verhalten.
- `scripts/game/`: Match-Aufbau, Spawn und Score.
- `scripts/ui/`: HUD-Datenbindung.
- `assets/`: eigenständige Grafiken und Materialien.

## Bekannte Grenzen

Dieser Branch ist ein lokaler Gameplay-Neuaufbau und noch kein vollständiges Multiplayer-Spiel. Bot-Navigation, Deckungswahl, serverautoritatives Netzwerk-Combat, Lag Compensation, Multiplayer-Reconnect, Audio, Animationen, mehrere Waffen, Pickups, Menüs und umfangreiche automatisierte Tests sind noch ausstehend. Der Code wurde über die Repository-Schnittstelle geschrieben; ein echter Godot-4.7.2-Editor-/Headless-Lauf muss vor einer Freigabe ausgeführt werden.
