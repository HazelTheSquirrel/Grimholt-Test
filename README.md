# Grimholt: Arena

Grimholt ist ein eigenständiger First-Person-Arena-Shooter für **Godot 4.7.2**. Die Qualitätsreferenz ist klassisches Arena-FPS-Design: klare Bewegungsregeln, lesbare Gefechte, präzise Treffer-Rückmeldung und unterschiedliche Waffenrollen. Halo 3 ist ausschließlich eine abstrakte Referenz. Es werden keine geschützten Namen, Karten, Waffenmodelle, Figuren, UI-Layouts, Audioinhalte oder Assets übernommen.

## Spielbarer Prototyp

Der aktive Einstieg lädt eine lokale Free-for-All-Arena mit fünf Bots.

- First-Person-Bewegung mit WASD, Mausblick und Sprung.
- Pulse Carbine mit 30 Schuss, 120 Reserve, Einzelschuss-Hitscan und Nachladen.
- Arc Scatter mit 8 Schuss, 40 Reserve und sieben Projektilstrahlen pro Schuss.
- Waffenwechsel mit Q; beide Waffen behalten ihre getrennten Munitionsstände.
- Bot-Gegner mit Verfolgung, einfacher Hindernissteuerung und Sichtlinienprüfung vor dem Schuss.
- Treffer- und Abschussfeedback, Fadenkreuz, Score, Gesundheit, Munition und Runden-Timer.
- Pausemenü mit Weiterspielen, Runde neu starten und Spiel beenden.
- Bot-Respawn und eine editierbare Greybox-Arena mit Deckung, Beleuchtung und Kollision.
- Eigenständige Szenen und getrennte GDScript-Systeme statt eines einzigen zentralen Gameplay-Skripts.

## Projekt starten

1. Godot **4.7.2** installieren.
2. `Grimholt/project.godot` in Godot öffnen und importieren.
3. Das Projekt starten.

## Steuerung

| Taste | Aktion |
|---|---|
| W / A / S / D | Bewegen |
| Maus | Umschauen und zielen |
| Linksklick halten | Feuern |
| Leertaste | Springen |
| R | Aktive Waffe nachladen |
| Q | Zwischen Pulse Carbine und Arc Scatter wechseln |
| ESC | Pausemenü öffnen/schließen |

## Projektstruktur

- `scenes/main.tscn`: aktiver Einstieg und Match-Komposition.
- `scenes/player/`: Spieler-Körper, Kamera und Waffeninstanzen.
- `scenes/weapons/`: eigenständige Waffen-Viewmodels.
- `scenes/enemies/`: Bot-Szene.
- `scenes/levels/`: Arena-Geometrie, Materialien und Kollision.
- `scenes/ui/`: HUD und Pausemenü.
- `scripts/player/`: Bewegung, Kamera, Gesundheit und Eingabe.
- `scripts/combat/`: Waffenwerte, Feuerrate, Munition und Nachladen.
- `scripts/ai/`: Bot-Bewegung, Hindernissteuerung und Sichtlinie.
- `scripts/game/`: Match-Timer, Spawn, Score und Rundenablauf.
- `scripts/ui/`: HUD- und Menülogik.
- `tests/`: Godot-Headless-Validierung und Gameplay-Smoke-Test.

Die alten Dateien unter `scripts/shooter/` und `scenes/shooter/` bleiben vorerst als Referenz des vorherigen Prototyps im Repository. Sie sind nicht mehr der aktive Spieleinstieg.

## Validierung

GitHub Actions installiert Godot 4.7.2 und führt Projektimport, das Laden aller GDScript-Dateien, einen Headless-Start sowie den modularen Gameplay-Smoke-Test aus. Ein grüner CI-Lauf bestätigt Import, Parser und die getesteten Spielsysteme. Er ersetzt keine visuelle Abnahme im Editor oder längere Spieltests.

## Bewusste Grenzen dieses Prototyps

Der aktuelle aktive Build ist **lokal und offline**. Er ist noch kein vollständiges Multiplayer-Spiel: ENet-Host/Join, serverautoritatives Combat, Lag Compensation, Reconnect, NavigationMesh-Pfadfindung und dedizierte Server fehlen im neuen modularen Gameplay-Pfad. Ebenso fehlen finale 3D-Assets, Animationen, vollständiges Audio, Pickups, mehrere Arenen und ausbalancierte Spielmodi. Die vorhandene alte Netzwerkimplementierung ist als Referenz erhalten, aber nicht in den neuen aktiven Pfad integriert. Das wird nicht als fertig ausgegeben.
