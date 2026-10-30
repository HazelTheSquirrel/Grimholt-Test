# Grimholt: Arena

Grimholt ist ein eigenständiger, reiner Multiplayer-3D-Arena-Shooter. Es gibt keine Einzelspieler-Kampagne. Das Spielgefühl orientiert sich an klassischen Arena-Shootern und militärischen Multiplayer-Shootern; Karten, Waffen, Figuren, UI und Weltgestaltung bleiben eigenständig.

## Aktueller Prototyp

- Free-for-All-Deathmatch mit 50 Abschüssen als Rundenziel und exakt 15 Minuten Echtzeit-Limit. Die Uhr zählt rückwärts; das Match endet sofort, sobald ein Spieler 50 Punkte erreicht, oder exakt bei 00:00. Läuft die Zeit ab, gewinnt der Spieler mit dem höchsten Punktestand; bei Gleichstand endet die Runde unentschieden. Ein Teammodus ist derzeit noch nicht implementiert.
- ENet-Host/Join über UDP-Port 27015.
- Fest gespeicherte Greybox-Arena-Szene mit sichtbarer Geometrie, Kollisionen, Licht, Vorschaukamera, Deckung und acht Spawnpositionen.
- First-Person-Steuerung, Mausblick, Springen, Halten von Strg zum Ducken und Hitscan-Gewehr mit prozeduralem Viewmodel.
- 30-Schuss-Magazin, Reserve-Munition und Nachladen.
- 100 Lebenspunkte, Respawn und exakt **1 Punkt pro bestätigtem Kill**; ein bereits besiegtes Ziel kann keine weiteren Punkte geben.
- Der Countdown basiert auf einer monotonen Echtzeituhr und wird regelmäßig an Clients synchronisiert; Teilsekunden werden aufgerundet, damit 00:00 erst beim tatsächlichen Ablauf erscheint.
- Fünf servergesteuerte Arena-Bots als Gegner; Bot-Kills erhöhen nicht den FFA-Spielerpunktestand.
- Militärisch inspiriertes, eigenständiges HUD: Matchzeit, Top-Fragger, Lebenspunkte, Munition, Killfeed und taktische Minimap.
- Vollständige K/D-Scoreboard-Ansicht per Tab, Trefferbestätigung und automatisches Gewehrfeuer bei gehaltenem Linksklick.
- Lokale Waffen- und Nachlade-Rückmeldung; finale Audioaufnahmen und räumlicher Mix stehen noch aus.
- Server prüft eingehende Bewegungsupdates mit fester Paket-Ratenbegrenzung, Plausibilitätsgrenzen und Geschwindigkeits-Toleranz. Das ist Härtung, aber noch keine vollständig serverautoritativ simulierte Bewegung.

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


## Architektur und eigene Assets

Die frühere zentrale `main.gd` ist jetzt ein schlanker Composition Root. Die Gameplay-Logik liegt in getrennten GDScript-Schichten: `shooter_core.gd`, `shooter_ui_system.gd`, `shooter_network_system.gd`, `shooter_weapon_system.gd`, `shooter_combat_system.gd`, `shooter_match_system.gd` und `shooter_hud_system.gd`. Das ist eine erste wartbare Trennung; die nächste Ausbaustufe sollte daraus unabhängig instanzierte Manager mit klaren Datenverträgen machen.

Unter `Grimholt/assets/` liegen eigens für Grimholt gezeichnete SVG-Dateien: Gildenwappen, Waffeninsignie und gekacheltes Arenaboden-Material. Wappen und Bodenmaterial sind bereits im Menü bzw. in der Arena eingebunden. `actor_visual.gd` ergänzt Spieler und Bots außerdem um eigens zusammengesetzte Rüstungsdetails statt ausschließlich unveränderter Kapsel-Silhouetten. Es werden keine fremden Marken- oder Spielassets eingebunden.

## Entwicklungsstand und bekannte Grenzen

Dies ist weiterhin ein früher Gameplay-Prototyp, kein fertiges oder öffentlich serverfestes Spiel. Die Arena-Geometrie, HUD-Elemente und Bot-KI sind weiterhin frühe Prototyp-Inhalte; die neuen SVG-Dateien ersetzen nicht die noch fehlenden finalen 3D-Modelle, Animationen und Audioaufnahmen. Die Bot-KI nutzt einfache direkte Verfolgung und Hitscan-Angriffe; sie navigiert noch nicht intelligent um Deckung. Die Minimap zeigt Positionsmarker, keine Sichtlinien- oder Aufklärungsdaten.

Noch offen sind unter anderem vollständig serverautoritativ simulierte Bewegung, zuverlässige Replikation unter Paketverlust, Lag Compensation, Anti-Cheat-Härtung, Lobby/Matchmaking, Serverbrowser, dedizierte Serverkonfiguration, Tests mit mehreren echten Clients sowie finale Grafik, Levelgestaltung und finale Audioassets. Die alten RPG-Skripte und RPG-Tests liegen weiterhin in den historischen Pfaden, werden aber nicht vom aktiven Shooter-Startpfad verwendet; siehe Grimholt/docs/LEGACY_RPG.md. Die physische Verschiebung bleibt aus, bis interne res://-Abhängigkeiten inventarisiert sind. Das aktuelle Headless-Smoke-Testskript prüft Szenenstart, Eingabeaktionen, Solo-Spawn, Bots und HUD; es ersetzt keine echten Mehrspieler- und Eingabetests. Die aktuelle Schussprüfung validiert Feuerrate und Blickrichtung serverseitig, ersetzt aber noch keine vollständige serverautoritativ simulierte Combat-Pipeline.

## Projektstruktur

Das Godot-Projekt liegt unter `Grimholt/`. Shooter-Szenen und -Skripte liegen unter `Grimholt/scenes/shooter/` und `Grimholt/scripts/shooter/`. GitHub Actions importiert das Projekt und führt einen Headless-Starttest aus. Ein erfolgreicher CI-Lauf und ein visueller Test mit mehreren Clients müssen vor einer Freigabe geprüft werden.
