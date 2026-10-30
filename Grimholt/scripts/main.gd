extends Node3D

@onready var terrain: GrimholtTerrainWorld = $TerrainWorld
@onready var player: GrimholtPlayer = $Player
@onready var building_system: GrimholtBuildingSystem = $PlayerBuildings
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun

func _ready() -> void:
    _setup_environment()
    var inventory := player.get_node("Inventory") as GrimholtInventory
    player.inventory = inventory
    player.building_system = building_system
    player.global_position = Vector3(0.0, terrain.height_at(0.0, 0.0) + 5.0, 0.0)
    terrain.populate_resources(inventory)

func _setup_environment() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.10, 0.20, 0.34)
    sky_material.sky_horizon_color = Color(0.67, 0.75, 0.78)
    sky_material.ground_bottom_color = Color(0.12, 0.15, 0.14)
    sky_material.ground_horizon_color = Color(0.43, 0.50, 0.43)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.ambient_light_energy = 0.75
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.sdfgi_enabled = true
    environment.volumetric_fog_enabled = true
    environment.volumetric_fog_density = 0.008
    world_environment.environment = environment
    sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
