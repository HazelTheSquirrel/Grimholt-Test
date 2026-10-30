# Grimholt: Arena – Roadmap

## Leitbild
Eigenständiger Multiplayer-3D-Arena-Shooter mit klassischem Free-for-All-Deathmatch. Keine Einzelspieler-Kampagne. Inspirationsquellen sind Halo 3 und Battlefield: Bad Company 2, ohne deren geschützte Inhalte zu übernehmen.

## Phase 1 – Spielbarer Deathmatch-Kern
- [x] Godot 4.7.2-Projekt auf Arena-Shooter umstellen
- [x] Prozedurale Greybox-Arena mit Deckung und Spawnpunkten
- [x] First-Person-Steuerung, Mausblick und Springen
- [x] ENet-Host/Join-Grundlage
- [x] Free-for-All, 50 Abschüsse, 15 Minuten
- [x] Lebenspunkte, Treffer, Kills und Respawn-Grundlage
- [x] Gewehr mit Magazin, Reserve-Munition und Nachladen
- [x] Servergesteuerte Bots als Match-Gegner
- [x] Serverseitige Bewegungsphysik mit validierten Eingabe-RPCs und periodischen Positions-Snapshots
- [ ] Vollständig serverautoritatives Combat inklusive Lag Compensation
- [x] Offline-Solo-Start ohne ENet-Server
- [x] Halte-Ducken mit abgesenkter Kamera und Kollisionskapsel
- [x] Prozedurales First-Person-Gewehr-Viewmodel
- [x] Serverseitige Plausibilitätsprüfung für Schussrichtung und Feuerrate
- [ ] Mehrclient-Tests, Paketverlust- und Disconnect-Tests
- [x] Serverseitige Munitions- und Nachladeautorität
- [x] Rate-Limit und Wertebereichsprüfung für Eingabe-RPCs

## Phase 2 – HUD und Spielgefühl
- [x] Eigenständiges militärisches HUD
- [x] Match-Timer und Top-Fragger-Anzeige
- [x] Lebenspunkte- und Munitionsanzeige
- [x] Killfeed
- [x] Taktische Minimap mit Spieler-/Bot-Markern
- [x] Trefferindikator und Abschussbestätigung
- [ ] Schadensrichtung
- [x] Scoreboard-Grundlage mit Kills und Deaths
- [ ] Ping und Assist
- [x] Prozedurales Schuss- und Nachlade-Audiofeedback
- [ ] Waffenanimationen und Trefferreaktionen
- [ ] Einstellungen für HUD-Skalierung, Audio und Eingabe

## Phase 3 – Waffen und Karten
- [ ] Zweite und dritte Waffe mit eigenständigen Rollen
- [ ] Waffenwechsel und Waffen-Pickups
- [ ] Munitions- und Gesundheits-Pickups
- [ ] Nachlade- und Feuermodi, Rückstoß und Streuung
- [ ] Mehrere handgebaute Karten mit klarer Lesbarkeit
- [ ] Kartenrotation und Spawn-Schutz
- [ ] Vertikale Routen, Flankenwege und ausgewogene Deckung

## Phase 4 – Bots und Multiplayer
- [x] Servergesteuerte Bot-Gegner
- [x] Einfache Zielsuche, Verfolgung und Schusslogik
- [ ] Navigation um Hindernisse und Nutzung von Deckung
- [ ] Schwierigkeitsstufen und Bot-Verhaltensprofile
- [ ] Lobby, Serverbrowser und private Matches
- [ ] Team-Deathmatch als zusätzlicher Modus
- [ ] Dedicated Server, Konfiguration und Administration
- [ ] Lag Compensation, robuste Replikation und Anti-Cheat

## Phase 5 – Qualität und Veröffentlichung
- [ ] Automatisierte Gameplay- und Multiplayer-Tests
- [ ] Godot-Headless-CI erfolgreich nachweisen
- [ ] Visuelle Abnahme und Performanceprofiling
- [ ] Finale Charaktere, Waffen, Animationen und Umgebungen
- [ ] Windows-Export und Installer
- [ ] Datenschutz, Serverlogs und Betreiber-Dokumentation

## Technische Leitlinien
1. Eigenständige Spielwelt, Waffen, Figuren, Karten und UI.
2. Multiplayer ist die einzige Spielrichtung.
3. Serverautorität für Treffer, Schaden, Punkte, Respawn und Matchzustand.
4. Keine falschen HUD-Daten: Minimap und Scoreboard zeigen nur tatsächlich vorhandene Zustände.
5. Prototyp-Platzhalter werden vor einer Veröffentlichung durch geprüfte Assets ersetzt.
