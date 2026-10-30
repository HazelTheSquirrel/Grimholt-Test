# Legacy-RPG-Bestand

Die Dateien unter `scripts/main.gd`, `scripts/player_controller.gd`, `scripts/components/`, `scripts/data/`, `scripts/systems/`, `scripts/world/` sowie die Tests `tests/extended_gameplay_test.gd`, `tests/gameplay_systems_test.gd` und `tests/player_physics_test.gd` stammen aus dem früheren RPG-Prototyp.

Sie sind **nicht Teil des aktiven Arena-Shooter-Startpfads**. `project.godot` startet ausschließlich `scenes/main.tscn`, dessen Composition Root unter `scripts/shooter/main.gd` liegt. Die RPG-Dateien bleiben vorerst unverändert erhalten, damit keine früheren Arbeiten verloren gehen. Sie werden durch die separate GDScript-Ladeprüfung weiterhin auf Syntax-/Ladefehler geprüft, aber nicht als aktive Gameplay-Funktionen gewertet.

Eine physische Verschiebung wird bewusst zurückgestellt, bis alle internen `res://`-Abhängigkeiten des alten RPG-Bestands inventarisiert und umgestellt werden können. Ein unvollständiges Verschieben würde die alten Dateien unbrauchbar machen.
