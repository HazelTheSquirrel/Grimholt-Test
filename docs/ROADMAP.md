# Grimholt – technische Roadmap

## Prototyp 0.1 (jetzt)

- Startszene und Laufzeitaufbau
- Prozedurale Höhenfeld-Landschaft
- Terrain-Mesh und Kollisionskörper
- First-Person-Character mit Bewegung, Sprint und Sprung
- Basis-HUD

## Nächste Schritte

1. **Chunk-Welt:** Terrain in Chunks aufteilen, Nachbarschaftsgrenzen sauber verbinden und nur sichtbare Bereiche laden.
2. **Voxel-Interaktion:** Block-/Materialdaten pro Chunk, gezieltes Abbauen und Platzieren, Mesh- und Kollisionsupdates nur für betroffene Chunks.
3. **Persistenz:** Weltseed und Änderungen speichern, damit veränderte Welten nach Neustarts erhalten bleiben.
4. **Character-Ausbau:** Third-Person-Umschaltung, Animationen, Statuswerte und Inventar.
5. **RPG-RP-Systeme:** Interaktionssystem, NPCs, Dialoge und Quests.
6. **Netzwerk:** Autoritativer Dedicated-Server; Singleplayer soll dieselbe Simulationslogik lokal verwenden.

## Architekturprinzipien

- Godot 4.x / GDScript
- Weltgenerierung deterministisch über Seed
- Keine Node-Instanz pro Terrain-Voxel
- Daten und Darstellung getrennt halten
- Große Welt erst nach Chunking und Profiling ausbauen
- Multiplayer-Simulation serverautoritativ planen
