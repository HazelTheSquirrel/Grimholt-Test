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

## Wichtige technische Abgrenzung

Die aktuellen Texturen werden prozedural in Godot erzeugt. Es werden keine externen Bilddateien oder lizenzpflichtigen Texturpakete benötigt. Das ist eine robuste Platzhalter-/Prototypbasis, aber noch kein finales AAA-PBR-Art-Set mit handgemalten Albedo-, Normal-, Roughness- und AO-Maps.

## Testabdeckung

Der CI-Testlauf prüft Import/Parser, Start, Inventar/Crafting/Ressourcen, Spieler-Bodenkollision und Bewegung, Szenenstruktur sowie Maße und Baukosten. Nicht automatisch abgedeckt sind vollständige Maus-/Tastaturbedienung, Langzeit-Performance, alle Grafiktreiber, Speichern/Laden und Multiplayer – diese Funktionen sind teils noch nicht implementiert.
