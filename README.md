# Grimholt: Arena

Grimholt ist ein eigenständiger, reiner Multiplayer-3D-Arena-Shooter. Es gibt keine Einzelspieler-Kampagne. Das Spielgefühl orientiert sich an klassischen Arena-Shootern und militärischen Multiplayer-Shootern; Karten, Waffen, Figuren, UI und Weltgestaltung bleiben eigenständig.

## Aktueller Prototyp

- Free-for-All-Deathmatch mit 25 Abschüssen als Rundenziel und zehn Minuten Zeitlimit.
- ENet-Host/Join über UDP-Port 27015.
- Fest gespeicherte Greybox-Arena-Szene mit sichtbarer Geometrie, Kollisionen, Licht, Vorschaukamera, Deckung und acht Spawnpositionen.
- First-Person-Steuerung, Mausblick, Springen, Halten von Strg zum Ducken und Hitscan-Gewehr mit prozeduralem Viewmodel.
- 30-Schuss-Magazin, Reserve-Munition und Nachladen.
- 100 Lebenspunkte, Respawn und Kill-Punkte.
- Fünf servergesteuerte Arena-Bots als Gegner.
- Militärisch inspiriertes, eigenständiges HUD: Matchzeit, Top-Fragger, Lebenspunkte, Munition, Killfeed und taktische Minimap.
- Server prüft eingehende Bewegungsupdates anhand der maximal plausiblen Laufgeschwindigkeit.

## Starten

1. Godot 4.7.2 installieren.
2. `Grimholt/project.godot` importieren.
3. Projekt starten.
4. Im Hauptmenü **Start Solo Game** wählen, um offline auf der Karte gegen fünf Bots zu spielen.
5. Für Multiplayer **Custom Games → Spiel hosten** wählen. Andere Spieler geben die öffentliche Server-IP ein und wählen **Spiel beitreten**. UDP-Port 27015 muss am Host erreichbar sein.

Training startet einen lokalen Host mit fünf Bots. Auch beim Multiplayer-Hosting startet der Host das Match und spawnt fünf Bots. Der Standardport ist UDP 27015.

## Steuerung

| Taste | Funktion |
|---|---|
| WASD | Bewegen |
| Maus | Zielen |
| Linksklick | Schießen |
| Leertaste | Springen |
| Strg (halten) | Ducken (Kamera und Kollisionskapsel werden abgesenkt) |
| R | Nachladen |
| ESC | Maus freigeben/einfangen |

## Entwicklungsstand und bekannte Grenzen

Dies ist weiterhin ein früher Gameplay-Prototyp, kein fertiges oder öffentlich serverfestes Spiel. Die Arena, HUD-Elemente und Bots sind Platzhalter. Die Bot-KI nutzt einfache direkte Verfolgung und Hitscan-Angriffe; sie navigiert noch nicht intelligent um Deckung. Die Minimap zeigt Positionsmarker, keine Sichtlinien- oder Aufklärungsdaten.

Noch offen sind unter anderem serverautoritatives Munitions-/Nachladesystem, vollständige serverautoritativ simulierte Bewegung, zuverlässige Replikation unter Paketverlust, Lag Compensation, Anti-Cheat-Härtung, Lobby/Matchmaking, Serverbrowser, dedizierte Serverkonfiguration, Tests mit mehreren echten Clients sowie finale Grafik und Levelgestaltung. Die aktuelle Schussprüfung validiert Feuerrate und Blickrichtung serverseitig, ersetzt aber noch keine vollständige serverautoritativ simulierte Combat-Pipeline.

## Projektstruktur

Das Godot-Projekt liegt unter `Grimholt/`. Shooter-Szenen und -Skripte liegen unter `Grimholt/scenes/shooter/` und `Grimholt/scripts/shooter/`. GitHub Actions importiert das Projekt und führt einen Headless-Starttest aus. Ein erfolgreicher CI-Lauf und ein visueller Test mit mehreren Clients müssen vor einer Freigabe geprüft werden.
