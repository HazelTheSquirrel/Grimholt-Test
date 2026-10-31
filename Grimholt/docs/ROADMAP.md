# Grimholt: Arena – Roadmap

## Leitbild

Eigenständiger First-Person-Arena-Shooter mit klar lesbaren Gefechten, einer kompakten Waffen-Sandbox und einer unverwechselbaren Grimholt-Identität. Halo 3 ist nur eine abstrakte Qualitätsreferenz, keine Vorlage für geschützte Inhalte.

## Phase 1 – Modularer Offline-Gameplay-Kern

- [x] Godot 4.7.2-Projekt und Hauptszene
- [x] Greybox-Arena mit Kollision, Deckung und Beleuchtung
- [x] First-Person-Bewegung, Mausblick und Sprung
- [x] Pulse Carbine mit Magazin, Reserve, Hitscan und Nachladen
- [x] Arc Scatter mit eigenständiger Nahbereichsrolle und Pellet-Streuung
- [x] Waffenwechsel und getrennte Munitionsstände
- [x] Bot-Gegner mit Verfolgung, einfacher Hindernissteuerung und Sichtlinienprüfung
- [x] Treffer-/Abschussfeedback, Fadenkreuz und HUD
- [x] Score, Match-Timer, Bot-Respawn und Pause/Neustart
- [x] Separate Szenen und GDScript-Verantwortlichkeiten
- [ ] CI-Lauf für den finalen Branch vollständig grün nachweisen
- [ ] Manuelle Sicht- und Spielgefühl-Abnahme in Godot 4.7.2

## Phase 2 – Spielgefühl und Inhalt

- [ ] Bewegungstuning: Sprint, Ducken, Luftkontrolle und saubere Kollision
- [ ] Rückstoß, Streuungs-/Recoil-Feedback und Waffenanimationen
- [ ] Schildsystem, Trefferreaktionen und klare Schadenskommunikation
- [ ] Health-/Ammo-Pickups und Waffen-Pickups
- [ ] Mindestens eine weitere Arena mit vertikalen Routen und Flankenwegen
- [ ] Audio, Partikel, Mündungsfeuer und Treffer-VFX
- [ ] Settings mit persistenter Grafik-, Audio- und Steuerungskonfiguration

## Phase 3 – Bot-Qualität

- [ ] NavigationAgent3D und NavigationMesh-Pfadfindung
- [ ] Taktische Deckungswahl und Flankierungsverhalten
- [ ] Bot-Schwierigkeitsstufen und Verhaltenstests
- [ ] Respawn-Schutz und Spawnpunkt-Bewertung

## Phase 4 – Multiplayer

- [ ] ENet-Lobby und Host/Join-Flow in die modulare Architektur migrieren
- [ ] Serverseitige Autorität für Treffer, Schaden, Munition, Score und Respawn
- [ ] Client-Interpolation, Eingabe-Prediction und Reconciliation
- [ ] Lag Compensation und Validierung von RPC-Eingaben
- [ ] Disconnect, Reconnect, Paketverlust und Mehrclient-Tests
- [ ] Dedicated Server und Match-Konfiguration

## Phase 5 – Release-Qualität

- [ ] Mehrere Modi und Kartenrotation
- [ ] Performanceprofiling und visuelle Regressionstests
- [ ] Windows-Export, Installer und Konfiguration
- [ ] Datenschutz, Serverlogs und Betreiber-Dokumentation

## Technische Leitlinien

1. Keine neue monolithische Gameplay-Datei.
2. Szenen bleiben im Editor sichtbar und sinnvoll aufgeteilt.
3. Gameplay-Logik wird über klare Komponenten und Signale verbunden.
4. Netzwerkautorität gehört ausschließlich auf den Server, sobald Multiplayer migriert wird.
5. Keine Features als abgeschlossen markieren, bevor sie getestet sind.
