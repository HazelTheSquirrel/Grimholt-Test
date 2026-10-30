extends Node3D

const TerrainScript = preload("res://scripts/world/terrain_world.gd")
const PlayerScript = preload("res://scripts/player_controller.gd")
const InventoryScript = preload("res://scripts/systems/inventory.gd")
const BuildingScript = preload("res://scripts/systems/building_system.gd")

func _ready() -> void:
    _setup_environment()
    var terrain: GrimholtTerrainWorld = TerrainScript.new()
    terrain.name = "TerrainWorld"
    add_child(terrain)
    var building_system: GrimholtBuildingSystem = BuildingScript.new()
    building_system.name = "PlayerBuildings"
    add_child(building_system)
    var player: GrimholtPlayer = PlayerScript.new()
    player.name = "Player"
    add_child(player)
    var inventory: GrimholtInventory = InventoryScript.new()
    inventory.name = "Inventory"
    player.add_child(inventory)
    player.inventory = inventory
    player.building_system = building_system
    player.global_position = Vector3(0.0, terrain.height_at(0.0, 0.0) + 2.0, 0.0)
    terrain.populate_resources(inventory)

func _setup_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.10, 0.20, 0.34)
    sky_material.sky_horizon_color = Color(0.58, 0.67, 0.72)
    sky_material.ground_bottom_color = Color(0.12, 0.15, 0.14)
    sky_material.ground_horizon_color = Color(0.42, 0.48, 0.43)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.sdfgi_enabled = true
    environment.volumetric_fog_enabled = true
    environment.volumetric_fog_density = 0.012
    world_environment.environment = environment
    add_child(world_environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)
