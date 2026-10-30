# Grimholt – Entwicklungsplan

## Leitbild

Grimholt ist ein polygonbasiertes Fantasy-Sandbox-RPG mit natürlichem Terrain, modularen Gebäuden, sammelbaren Ressourcen, Berufen, Crafting, Erkundung und Rollenspiel. Kein Voxel- oder Blockspiel. Singleplayer und private Multiplayer-Server sollen dieselben Gameplay-Regeln verwenden; offizielle zentrale Spielserver sind nicht vorgesehen.

## Phase 0 – Technischer Welt-Prototyp

- [x] Godot 4.7.2 Projekt und Hauptszene
- [x] Explizite, im Editor bearbeitbare Hauptszenen-Nodes für Welt, Spieler, Kamera, Inventar und HUD
- [x] Editor-sichtbarer Terrain-Generator mit einstellbarer Ausdehnung, Zellgröße und Seed
- [x] Erste lesbare Farbgebung für Grasland, Moos, Fels und sammelbare Ressourcen
- [x] Wechsel auf Forward+ Renderer
- [x] Polygonales prozedurales Höhen-Terrain mit Mesh-Kollision
- [x] Third-Person-Spielergrundlage und Kamera
- [ ] Hochwertiger Third-Person-Charakter mit Animationen
- [x] Verbindlicher Weltmaßstab: 1 Einheit = 1 Meter; Spieler-Kapsel 1,70 m
- [x] Prozedurale Terrain-Oberflächentextur und lesbare Gelände-Farbzonen
- [x] Editor-sichtbare Himmels-/Umgebungsressource
- [x] Instanzierte Grasbüschel und verstreute Steine als Landschafts-Füllassets
- [x] Unterscheidbare Platzhalter-Silhouetten für Eiche, Birke und Fichte
- [x] Prozedurale Materialien für Baumstämme, Laub, Sträucher, Erz und Kräuter
- [x] Erste Gebäudeabmessungen auf 3-m-Raster und menschliche Referenzmaße abgestimmt
- [ ] Terrain-Streaming, LOD und Profiling
- [ ] Windows-Grafiktest auf Zielhardware

## Phase 1 – Sammeln, Inventar und Berufe

- [x] Datenbasierter Item-Katalog
- [x] Inventar mit Stapeln, Materialprüfung und Verbrauch
- [x] Interaktive Bäume, Erzadern und Kräuter
- [x] Ernteinteraktion im echten Spieler-/Kamera-/Kollisionsablauf durch Headless-Regressionsprüfung abgesichert
- [x] Ressourcenernte mit konfigurierbaren Erträgen
- [x] Grundsystem für Berufserfahrung und Level
- [ ] Werkzeuge, Werkzeughaltbarkeit und Abbauzeiten
- [ ] Ressourcen-Respawn, Spawnregeln und Persistenz
- [ ] Weitere Ressourcen: Stein, Lehm, Fasern, Fisch, Jagdbeute
- [ ] Vollständige Sammelberufe und Spezialisierungen

## Phase 2 – Crafting und Wirtschaft

- [x] Datengetriebene Rezeptdefinitionen
- [x] Materialkosten und Ergebnisgegenstände
- [x] Werkstatt-/Stationskennung in Rezeptdaten
- [x] Erste Schmiede-, Schreinerei- und Alchemie-Rezepte
- [ ] Interaktive Werkstätten und Crafting-Warteschlangen
- [ ] Rezeptfreischaltungen, Qualitätsstufen und seltene Rezepte
- [ ] Schmiedekunst, Lederverarbeitung, Schneiderei, Kochen und weitere Berufe
- [ ] Händler, Marktplätze, Währung und Spielerhandel

## Phase 3 – Bauen und Grundstücke

- [x] Datenbasierte Bauteildefinitionen
- [x] Fundament-, Wand- und Dach-Prototyp
- [x] Materialkosten beim Platzieren
- [ ] Snap-Punkte, Raster- und Bauteilverbindungen
- [ ] Türen, Fenster, Treppen, Dächer und modulare Sets
- [ ] Grundstücke, Baurechte, Schutz und Berechtigungen
- [ ] Gebäude-Persistenz und gemeinschaftliche Siedlungen
- [ ] Gildenhäuser, Werkstätten und öffentliche Gebäude

## Phase 4 – RPG und lebendige Welt

- [ ] Charaktererstellung, Attribute und Ausrüstung
- [ ] Kampf, Waffen, Magie, Trefferreaktionen und Gegner-KI
- [ ] Biome, Höhlen, Dungeons und handgebaute Orte
- [ ] NPCs, Dialoge, Tagesabläufe und Fraktionen
- [ ] Quests, Ruf, Konsequenzen und Rollenspielwerkzeuge
- [ ] Wetter, Tag-Nacht-Wechsel und Umgebungs-Audio
- [ ] Jagd, Kochen, Alchemie und Überlebenssysteme

## Phase 5 – Private Multiplayer-Server

- [ ] Gemeinsame serverautoritative Simulationslogik
- [ ] Dedizierter Headless-Server
- [ ] Synchronisierung von Charakteren, Ressourcen und Gebäuden
- [ ] Private Serverkonfiguration, Passwort und Whitelist
- [ ] Persistente Charaktere, Inventare, Berufe und Welten
- [ ] Administration, Moderation, Logs und Backups
- [ ] Verbindungsabbrüche, Wiederbeitritt und Versionsprüfung

## Phase 6 – Veröffentlichung

- [ ] Hauptmenü und Welt-/Serverauswahl
- [ ] Windows-Export und Installer
- [ ] Grafik-, Audio-, Eingabe- und Barrierefreiheitseinstellungen
- [ ] Performance- und Speichertests auf Zielhardware
- [ ] Dokumentation für private Serverbetreiber

## Architekturregeln

1. Polygonale 3D-Welt; keine Voxel als Weltgrundlage.
2. Ressourcen, Items, Rezepte, Berufe und Bauteile werden datengetrieben definiert.
3. Inventar-, Ressourcen-, Crafting- und Bauänderungen müssen später serverautorisiert sein.
4. Weltzustand und persistente Daten sind von der visuellen Darstellung getrennt.
5. Große Gebiete benötigen Streaming, LOD, Instancing und regelmäßiges Profiling.
6. Singleplayer und Multiplayer verwenden dieselben Gameplay-Regeln.
