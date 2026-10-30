# Grimholt – Maßstab und visuelle Materialbasis

## Verbindlicher Weltmaßstab

**1 Godot-Einheit = 1 Meter.** Alle neuen Meshes, Kollisionsformen, Baupläne und Interaktionsabstände verwenden Meter.

| Element | Prototypmaß | Grundlage |
|---|---:|---|
| Spielfigur | 1,70 m | festgelegte menschliche Referenzgröße |
| Spieler-Kapsel | 0,60 m Durchmesser | vereinfachte Gameplay-Kollision |
| Kamera-Pivot | 1,55 m | ungefähr Augen-/Kopfbereich |
| Türöffnung (später) | 0,90 m × 2,10 m | komfortable lichte Durchgangsmaße |
| Gebäudewand | 3,00 m Rasterbreite × 2,40 m Höhe | frühes modulares Gebäuderaster |
| Fundament | 3,00 m × 3,00 m × 0,25 m | Rastermaß |
| Baum-Prototyp | ca. 10 m bis Kronenspitze | bewusst junge/mittelgroße Spielbaum-Variante |
| Baumstamm | 7,40 m | vereinfachter Stamm, Krone darüber |
| Strauch | ca. 1,2 m | niedrige Vegetationsschicht |

Die Baum-Prototypen sind absichtlich kleiner als ausgewachsene Naturbäume, damit die Startregion lesbar bleibt und Waldvarianten später unterschiedliche Alters- und Größenstufen bekommen. Sie stellen keine ausgewachsene Stieleiche dar: Europäische Stieleichen erreichen typischerweise etwa 30–35 m; Hänge-Birken typischerweise 15–25 m. Quellen: [European Atlas of Forest Tree Species – Stieleiche](https://forest.jrc.ec.europa.eu/en/european-atlas/qr-trees/pedunculate-oak/) und [European Atlas – Hänge-Birke](https://forest.jrc.ec.europa.eu/en/european-atlas/qr-trees/silver-birch/).

Für Türen dient 2,10 m lichte Höhe und 0,90 m lichte Breite als frühe Planungsreferenz. Die endgültigen mittelalterlichen/fantastischen Gebäudesets dürfen davon stilistisch abweichen, müssen aber weiterhin mit der Spielfigur kollisionsfrei funktionieren.

## Materialstrategie

- Terrain: prozedurale Noise-Textur, triplanare Projektion, zusätzliche Vertex-Farben für Gras, Moos, Fels und steile Hänge.
- Holz: prozedurale Oberflächenvariation, matte raue Oberfläche.
- Vegetation: getrennte Materialien für Stamm, Laub und Sträucher.
- Erz: dunkles Gestein mit metallisch akzentuierten Erzflächen.
- Kräuter: klar unterscheidbare Blüten- und Stängelfarben.
- Bauteile: eigene Materialdefinitionen, vorläufig ohne finale handgemalte PBR-Textursets.

## Sichtbare Boden- und Himmelsmaterialien

Das Terrain verwendet jetzt einen eigenen triplanaren Shader: Wiese und Moos werden anhand der Biom-Vertexfarben gemischt, steile Flächen wechseln zu Schieferfels und große Höhen erhalten Schnee/Eis. Die Projektion erfolgt in Weltkoordinaten, damit Texturen an Chunk-Grenzen nicht durch lokale UV-Neustarts springen. Die Umgebung nutzt eine eigens erstellte 2:1-Panorama-SVG mit Dämmerungshimmel, Wolken und Sonnenlicht über `PanoramaSkyMaterial`. Die vorhandenen SVG-Oberflächen sind damit nicht nur lose Asset-Dateien, sondern direkt an Terrain und Himmel angeschlossen.

## Wichtige technische Abgrenzung

Die aktuellen Texturen werden prozedural in Godot erzeugt. Es werden keine externen Bilddateien oder lizenzpflichtigen Texturpakete benötigt. Das ist eine robuste Platzhalter-/Prototypbasis, aber noch kein finales AAA-PBR-Art-Set mit handgemalten Albedo-, Normal-, Roughness- und AO-Maps.

## Testabdeckung

Der CI-Testlauf prüft Import/Parser, Start, Inventar/Crafting/Ressourcen, Spieler-Bodenkollision und Bewegung, Szenenstruktur sowie Maße und Baukosten. Nicht automatisch abgedeckt sind vollständige Maus-/Tastaturbedienung, Langzeit-Performance, alle Grafiktreiber, Speichern/Laden und Multiplayer – diese Funktionen sind teils noch nicht implementiert.


## Großwelt – 10.000 km²

Die Weltgrundfläche ist auf **100.000 × 100.000 m** (10.000 km²) ausgelegt. Sie wird nicht als ein einzelnes Mesh geladen: Der Generator hält eine 3×3-Nachbarschaft aus 1-km-Abschnitten um den Spieler aktiv. Jeder Abschnitt besitzt eigene Terrain-Kollision, deterministische Höhenwerte, Vegetations-Instancing und dieselbe globale Noise-Abtastung an den Abschnittsgrenzen.

### Landschaftsaufbau

- Kontinentale Hügel und breite Hochlandformen aus mehrskaligem Simplex-/FBM-Noise.
- Gebirgsrücken mit höhenabhängiger Fels- und Schneefärbung.
- Ein mäandrierender Flusskorridor mit breiter Erosionssenke und tieferem Flussbett-Profil.
- Fünf Höhen-/Klimazonen: Wiesen/Mischwald, dichter Wald, Hochland/Nadelwald, alpines Felsland und Heide.
- Deterministisch platzierte Waldkronen, Stämme und Grasbüschel je Chunk.
- Prozedurale Noise-Albedo-Textur mit nahtloser Noise-Generierung und triplanarer Projektion.

### Noch nicht als fertig behaupten

Der aktuelle Meilenstein erzeugt die Großlandschaft und streamt Terrain-Chunks. Sichtbare Wasseroberflächen mit Uferübergängen, begehbare Höhleninnenräume, echte Tal-/Schlucht-Setpieces, markante handgebaute Orte, Flora-Varianten je Biom, Tierwelt, Navmesh und Terrain-LOD sind weitere Arbeitspakete. Die prozedurale Noise-Textur ist eine eigenständige Texturbasis, aber noch kein vollständiges handgemaltes PBR-Set aus Albedo, Normal, Roughness und AO.


## Gewässer, Höhlen, Landmarken und Streaming-Erweiterung

- Flussoberflächen werden pro Chunk aus derselben globalen Mäanderfunktion abgeleitet. Dadurch treffen die Segmente an Chunk-Grenzen auf denselben Flussverlauf; die Uferzone wird durch die aus dem Höhenfeld geformte Senke freigehalten.
- Eine Wasserfall-Landmarke mit Fallfläche und Becken liegt im Chunk (3, -2).
- Ein Dungeon-Eingang im Chunk (-7, -4) führt in einen geformten Tunnel mit wiederholten Felsbögen, begehbarem Boden samt Kollision und einer Endkammer.
- Weitere feste POIs: zerstörter Wachturm (3, -2), verlassenes Dorf (-4, 2), Steinkreis (6, 5).
- Vegetationsmaterialien variieren nach Biom; Baumstamm- und Grasfarben sind je Klimazone angepasst.
- Terrain-LOD: 32 × 32 Zellen für den direkten Nachbarchunk, 12 × 12 für die äußere aktive Nachbarschaft.
- Neue Chunks werden gestaffelt mit maximal einem Chunk-Neubau pro Prozess-Frame eingereiht, damit nicht alle Chunk-Nodes im selben Frame erzeugt werden.

### Technische Grenze

Das gestaffelte Einreihen ist noch keine echte Worker-Thread-Berechnung: Noise-Abtastung, Mesh-Erzeugung und Node-Aufbau laufen weiterhin auf dem Hauptthread. Für echte asynchrone Erzeugung müssen reine Mesh-Daten in Worker-Threads berechnet und Nodes anschließend sicher auf dem Hauptthread erstellt werden. LOD-Übergangsmorphing, Wasserphysik, Höhlen-Navigation/Beleuchtung und Performanceprofiling bleiben weitere Qualitätsarbeit.


## Startpunkt und eigenes Seamless-Texturpaket

Der Weltstart erzeugt den zentralen 1-km-Chunk inklusive Terrain-Trimesh-Kollision synchron, bevor der Spieler auf seine Startposition gesetzt wird. Der Spawn liegt bei X/Z = 0 und 1,25 m über dem Höhenfeld; die Physik setzt den Charakter anschließend kontrolliert auf dem Boden ab. Ein 28-m-Radius um den Startpunkt wird von zufälligen Bauminstanzen freigehalten, damit der Spawn nicht in einem Baumcluster liegt.

Unter `assets/textures` liegen acht eigens erstellte, kachelbare 256×256-SVG-Texturen: Wiese, Waldboden, Schieferfels, Erde, Kies/Sand, Schnee/Eis, Baumrinde und Blätter. Die Wiederholmuster sind periodisch angelegt und haben keine externen Bildabhängigkeiten. Unter `assets/materials` liegen wiederverwendbare Godot-Standardmaterialien. Das Terrain verwendet triplanares Mapping und Vertexfarben zur Biomeinfärbung; Baumstämme und Kronen verwenden die Rinden- und Blättertexturen.

Der erweiterte Gameplay-Test prüft, dass die Startkollision vorliegt, die Spawnhöhe korrekt gesetzt wurde und alle Texturen/Materialien geladen werden können. Ein Headless-Test ersetzt keine visuelle Abnahme im Editor oder auf der Ziel-GPU.
