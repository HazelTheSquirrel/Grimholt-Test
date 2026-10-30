extends Node3D

const SAVE_PATH := "user://grimholt_save.json"
const SAVE_TEMP_PATH := "user://grimholt_save.tmp"
const SAVE_VERSION := 1

@onready var terrain: GrimholtTerrainWorld = $TerrainWorld
@onready var player: GrimholtPlayer = $Player
@onready var building_system: GrimholtBuildingSystem = $PlayerBuildings
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun

func _process(_delta: float) -> void:
    if is_instance_valid(player) and is_instance_valid(terrain):
        terrain.update_streaming(player.global_position)

func _ready() -> void:
    _setup_environment()
    var inventory := player.get_node("Inventory") as GrimholtInventory
    player.inventory = inventory
    player.building_system = building_system
    player.global_position = terrain.get_safe_spawn_position()
    terrain.populate_resources(inventory)
    for child in terrain.get_children():
        if child is GrimholtResourceNode:
            child.harvested.connect(_on_resource_harvested)
    if FileAccess.file_exists(SAVE_PATH):
        _load_game(false)

var depleted_resource_ids: Array[String] = []

func _on_resource_harvested(resource_key: String) -> void:
    if not depleted_resource_ids.has(resource_key):
        depleted_resource_ids.append(resource_key)

func _get_depleted_resource_ids() -> Array[String]:
    return depleted_resource_ids.duplicate()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_game(false)

func _setup_environment() -> void:
    # Keep the Environment resource assigned in the editor.
    var environment := world_environment.environment
    if environment == null:
        environment = Environment.new()
        world_environment.environment = environment
    environment.background_mode = Environment.BG_SKY
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.75
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.sdfgi_enabled = true
    environment.volumetric_fog_enabled = true
    environment.volumetric_fog_density = 0.008
    sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true

func _save_game(show_feedback: bool = true) -> bool:
    if player.inventory == null:
        return false
    var position := player.global_position
    var save_data := {
        "version": SAVE_VERSION,
        "player_position": [position.x, position.y, position.z],
        "inventory": player.inventory.items.duplicate(true),
        "profession_experience": player.professions.experience.duplicate(true),
        "buildings": building_system.get_save_data(),
        "depleted_resources": _get_depleted_resource_ids(),
        "terrain_seed": terrain.terrain_seed
    }
    var file := FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
    if file == null:
        if show_feedback:
            player._set_feedback("Speichern fehlgeschlagen: Datei konnte nicht angelegt werden.")
        return false
    file.store_string(JSON.stringify(save_data, "\t"))
    file.flush()
    file.close()
    if FileAccess.file_exists(SAVE_PATH):
        var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
        if remove_error != OK:
            if show_feedback:
                player._set_feedback("Speichern fehlgeschlagen: Alte Datei ist gesperrt.")
            return false
    var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_TEMP_PATH), ProjectSettings.globalize_path(SAVE_PATH))
    if rename_error != OK:
        if show_feedback:
            player._set_feedback("Speichern fehlgeschlagen (Fehler %d)." % rename_error)
        return false
    if show_feedback:
        player._set_feedback("Spielstand gespeichert.")
    return true

func _load_game(show_feedback: bool = true) -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        if show_feedback:
            player._set_feedback("Kein Spielstand gefunden.")
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        if show_feedback:
            player._set_feedback("Spielstand konnte nicht geöffnet werden.")
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary or int(parsed.get("version", -1)) != SAVE_VERSION:
        if show_feedback:
            player._set_feedback("Spielstand ist ungültig oder hat eine unbekannte Version.")
        return false
    var coordinates: Variant = parsed.get("player_position", [])
    if not coordinates is Array or coordinates.size() != 3:
        if show_feedback:
            player._set_feedback("Spielstand enthält keine gültige Spielerposition.")
        return false
    for coordinate in coordinates:
        if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
            if show_feedback:
                player._set_feedback("Spielstand enthält ungültige Positionsdaten.")
            return false
    var inventory_data: Variant = parsed.get("inventory", {})
    var profession_data: Variant = parsed.get("profession_experience", {})
    var building_data: Variant = parsed.get("buildings", [])
    var depleted_data: Variant = parsed.get("depleted_resources", [])
    var inventory_probe := GrimholtInventory.new()
    var inventory_valid := inventory_probe.set_items_from_save(inventory_data)
    inventory_probe.free()
    var profession_probe := GrimholtProfessionSystem.new()
    var profession_valid := profession_probe.set_experience_from_save(profession_data)
    if not inventory_valid or not profession_valid or not building_data is Array or not depleted_data is Array:
        if show_feedback:
            player._set_feedback("Spielstand enthält ungültige Spielfortschritte.")
        return false
    for entry in building_data:
        if not entry is Dictionary or not GrimholtBuildingSystem.PIECES.has(String(entry.get("piece", ""))):
            if show_feedback:
                player._set_feedback("Spielstand enthält ungültige Gebäudedaten.")
            return false
        var saved_position: Variant = entry.get("position", [])
        if not saved_position is Array or saved_position.size() != 3:
            if show_feedback:
                player._set_feedback("Spielstand enthält ungültige Gebäudepositionen.")
            return false
        for coordinate in saved_position:
            if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
                if show_feedback:
                    player._set_feedback("Spielstand enthält ungültige Gebäudepositionen.")
                return false
    for resource_key in depleted_data:
        if not resource_key is String or not terrain.has_resource_id(resource_key):
            if show_feedback:
                player._set_feedback("Spielstand enthält ungültige Ressourcendaten.")
            return false
    if not building_system.restore_from_save(building_data):
        if show_feedback:
            player._set_feedback("Gebäude konnten nicht wiederhergestellt werden.")
        return false
    if not terrain.restore_depleted_resources(depleted_data):
        if show_feedback:
            player._set_feedback("Ressourcen konnten nicht wiederhergestellt werden.")
        return false
    depleted_resource_ids.clear()
    for resource_key in depleted_data:
        depleted_resource_ids.append(String(resource_key))
    player.inventory.set_items_from_save(inventory_data)
    player.professions.set_experience_from_save(profession_data)
    var restored_position := Vector3(float(coordinates[0]), float(coordinates[1]), float(coordinates[2]))
    # Older saves may contain a position from before terrain/spawn fixes. Never restore a
    # character whose capsule origin is below the current procedural ground surface.
    var ground_height := terrain.height_at(restored_position.x, restored_position.z)
    var recovered_from_underground := restored_position.y < ground_height + 0.05
    if recovered_from_underground:
        restored_position = terrain.get_safe_spawn_position()
    player.global_position = restored_position
    player.velocity = Vector3.ZERO
    if show_feedback:
        player._set_feedback("Alter Spielstand: Position unter dem Gelände – zum Startpunkt versetzt." if recovered_from_underground else "Spielstand geladen.")
    return true
