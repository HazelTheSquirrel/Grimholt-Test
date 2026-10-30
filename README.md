# Grimholt: Arena

Grimholt wird zu einem **reinen Multiplayer-3D-Arena-Shooter** umgebaut. Das frühere Fantasy-Sandbox-RPG ist nicht mehr die Spielrichtung.

## Spielidee

Klassisches, schnelles Arena-Deathmatch mit dem Gefühl der Arena-Shooter-Ära: klare Kartenlayouts, lesbare Gefechte, kontrollierbare Waffen-Spawns und ein direktes Punktelimit. Halo 3 und Battlefield: Bad Company 2 sind Inspirationsquellen für das Spielgefühl, nicht für kopierte Inhalte. Welt, Fraktionen, Waffen, Karten und visuelle Identität werden eigenständig entwickelt.

- Ausschließlich Multiplayer; keine Einzelspieler-Kampagne.
- Free-for-All als erster Modus; Team-Modi können später ergänzt werden.
- Abschüsse bringen Punkte; zuerst 25 Punkte gewinnt.
- LAN/Internet-Host über ENet, Standardport UDP 27015.
- Geplantes Ziel: serverautoritatives Gameplay und dedizierte Server.

## Start

1. Godot 4.7.2 installieren.
2. Grimholt/project.godot importieren.
3. Projekt starten.
4. Auf einem Rechner Spiel hosten wählen.
5. Andere Spieler geben die Server-IP ein und wählen Server beitreten.

## Steuerung

- WASD: Bewegung
- Maus: Zielen
- Linksklick: Schießen
- Leertaste: Springen
- ESC: Maus freigeben/einfangen

## Entwicklungsstand

Der aktuelle Branch enthält den ersten technischen Arena-Schnitt: prozedural aufgebaute Testarena, FPS-Spieler, ENet-Host/Join-Oberfläche, Deathmatch-Punktestand und Treffer-/Kill-RPC-Grundlage. Noch nicht fertig sind Waffenmodelle, Animationen, Audio, echte Respawn-Logik, Lag Compensation, Anti-Cheat-Härtung, Lobby/Matchmaking, Team-Modi, Kartenrotation, Menüs und finale Art-Assets.

Der Umbau erfolgt schrittweise. Die alte RPG-Implementierung bleibt vorerst in der Git-Historie nachvollziehbar und wird erst nach Prüfung vollständig aus dem Projekt entfernt.
