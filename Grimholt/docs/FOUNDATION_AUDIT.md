# Grimholt – Architektur-Audit

Stand: 31.10.2026  
Engine: Godot 4.7.2  
Aktiver Entwicklungszweig: `rebuild/halo-inspired-fps-foundation`

## Ziel

Grimholt ist ein eigenständiger Arena-FPS. Halo 3 ist ausschließlich eine abstrakte Referenz für lesbare Gefechte, bewusst gestaltete Waffenrollen und klares Match-Feedback. Keine geschützten Assets, Namen, Waffen-/Figurendesigns, Kartenlayouts, UI-Kompositionen oder Audioinhalte werden übernommen.

## Aktiver Build

Der aktive Einstieg ist `scenes/main.tscn` und verwendet einen modularen Offline-Match-Controller.

- Spieler: First-Person-Bewegung, Mausblick, Sprung, Gesundheit, Respawn und Pausezustand.
- Waffen: Pulse Carbine (Hitscan) und Arc Scatter (sieben Pellet-Strahlen), getrennte Magazine/Reserven, Feuerrate und Nachladen.
- Gegner: fünf Bots mit Verfolgung, einfacher Hindernissteuerung, Angriffsdistanz und Sichtlinienprüfung.
- Match: zehnminütiger lokaler Deathmatch-Ablauf, Punkte, Bot-Respawn und Rundenende.
- UI: Score, Timer, Gesundheit, aktive Waffe, Munition, Fadenkreuz, Treffer-/Abschussfeedback und Pausemenü.
- Szenen: Spieler, Waffen, Bots, Arena, HUD und Pausemenü sind im Godot-Editor einzeln sichtbar und editierbar.

## Architektur

Die aktive Gameplay-Grundlage ist auf folgende Verantwortlichkeiten aufgeteilt:

| Bereich | Verantwortung |
|---|---|
| `scripts/game/match_controller.gd` | Match-Lifecycle, Spawn, Score, Timer und Pausekoordination |
| `scripts/player/player_controller.gd` | lokale Bewegung, Kamera, Eingabe, Treffer und Gesundheit |
| `scripts/combat/weapon_controller.gd` | Munitionszustand, Feuerrate, Nachladen und Waffenparameter |
| `scripts/ai/arena_bot.gd` | Zielverfolgung, Hindernissteuerung, Sichtlinie und Schaden |
| `scripts/ui/hud_controller.gd` | HUD-Daten und temporäres Trefferfeedback |
| `scripts/ui/pause_menu.gd` | Pause- und Rundenende-Menü |

Der alte Prototyp unter `scripts/shooter/` und `scenes/shooter/` bleibt als Referenz erhalten, ist aber nicht der aktive Einstieg. Seine frühere zentrale `main.gd`-Datei ist noch nicht in die neue modulare Struktur migriert.

## Validierung

GitHub Actions soll unter Godot 4.7.2 Folgendes ausführen:
1. Projektimport im Headless-Modus.
2. Laden/Validieren aller GDScript-Dateien.
3. Headless-Start der Hauptszene.
4. Gameplay-Smoke-Test für Szenen, Eingaben, Waffenwechsel, HUD und Pause/Resume.

Ein erfolgreicher CI-Lauf bestätigt nur die getesteten technischen Pfade. Fensterlayout, Mausgefühl, Performance und längere Spielsessions benötigen zusätzlich eine manuelle Prüfung im Godot-Editor.

## Noch nicht umgesetzt

- Multiplayer-Host/Join, serverautoritatives Combat, Replikation, Lag Compensation und Reconnect.
- NavigationMesh-Pfadfindung und taktische Deckungswahl für Bots.
- Settings-Menüs mit persistenter Steuerungs-/Grafik-/Audio-Konfiguration.
- Waffen-Pickups, Health-/Ammo-Pickups und weitere Waffen.
- Finale Modelle, Animationen, Audio, Partikeleffekte und mehrere handgebaute Karten.
- Netzwerk-, Last-, Paketverlust- und Disconnect-Tests.

Diese Punkte sind ausdrücklich nicht als fertig zu betrachten. Die frühere ENet-Implementierung bleibt nur als Referenz erhalten und ist nicht in den aktiven Offline-Build integriert.
