# Grimholt – Entwicklungsplan

## Leitbild

Ein Voxel-Sandbox-RPG mit starkem Rollenspiel-Fokus: erkundbare Fantasy-Welt, glaubwürdige Orte und NPCs, Charakterentwicklung und freie Spielerentscheidungen. Singleplayer und private Multiplayer-Server sollen dieselbe Simulationslogik verwenden. Es gibt keine offiziellen zentralen Spielserver.

## Phase 0 – Technischer Prototyp

- [x] Godot-Projekt und Startszene
- [x] First-Person-Bewegung
- [x] Seedbasierte Terrain-Grundlage
- [x] Voxel-Chunks mit 16 × 64 × 16 Zellen
- [x] Chunk-Streaming um den Spieler
- [x] Sichtflächen-Meshes und Chunk-Kollisionen
- [ ] Laufzeitprüfung in Godot 4.7.2 auf Windows

## Phase 1 – Belastbare Sandbox-Basis

- [x] Blockabbau und Platzieren mit Raycast
- [x] Chunk-Änderungen und Nachbar-Chunk-Updates
- [x] Welt-Metadaten und persistente Chunk-Speicherung
- [ ] Spawn-/Weltverwaltung und Fehlerbehandlung
- [ ] Hintergrundjobs für Generierung und Mesh-Aufbau
- [ ] Profiling und automatisierte Gameplay-Tests

## Phase 2 – Welt und Erkundung

- [ ] Biome mit eigenständigen Höhen-, Klima- und Materialprofilen
- [ ] Höhlen, Erzlager, Vegetation und natürliche Strukturen
- [ ] Flüsse, Seen und Wasserlogik
- [ ] Tageszeit, Wetter und Beleuchtung
- [ ] Handgebaute Orte und prozedurale Ergänzungen

## Phase 3 – Charakter und Sandbox-Spielschleife

- [ ] Charaktererstellung und Third-Person-Kamera
- [ ] Inventar, Ausrüstung und Gegenstandsdefinitionen
- [ ] Sammeln, Werkzeuge, Abbaugeschwindigkeit und Crafting
- [ ] Gesundheit, Ausdauer, Attribute und Fähigkeiten
- [ ] Kampf, Trefferlogik und Loot

## Phase 4 – RPG und Rollenspiel

- [ ] Interaktionssystem und Dialogeditor-Daten
- [ ] NPCs mit Tagesabläufen, Bedürfnissen und Reaktionen
- [ ] Questketten, Fraktionen, Ruf und Konsequenzen
- [ ] Händler, Berufe, Wirtschaft und Spielerhäuser
- [ ] Emotes, Charakterprofile und Rollenspiel-Chat

## Phase 5 – Private Multiplayer-Server

- [ ] Dedizierter Headless-Server
- [ ] Serverautorität für Bewegung, Inventar und Weltänderungen
- [ ] Private Serverkonfiguration, Passwort und Whitelist
- [ ] Persistente Charaktere und Welten
- [ ] Administration, Moderation und Backups
- [ ] Verbindungsabbrüche, Wiederbeitritt und Versionsprüfung

## Phase 6 – Veröffentlichung

- [ ] Hauptmenü und Welt-/Serverauswahl
- [ ] Windows-Export und Installer
- [ ] Grafik-, Audio-, Eingabe- und Barrierefreiheitseinstellungen
- [ ] Update- und Fehlerberichtssystem
- [ ] Dokumentation für private Serverbetreiber

## Architekturregeln

1. Keine Node-Instanz pro Voxel.
2. Weltzustand ist Datenbestand; Mesh und Kollision sind daraus abgeleitete Darstellung.
3. Seed und Generatorversion müssen reproduzierbare Welten ermöglichen.
4. Client-Eingaben sind im Multiplayer niemals autoritativ.
5. Singleplayer nutzt dieselben Spielregeln wie ein lokaler Serverprozess.
6. Neue Systeme erhalten klare Datenverträge und werden isoliert testbar gehalten.
