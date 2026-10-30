extends Node3D

const WorldScript = preload("res://scripts/world/world_generator.gd")
const PlayerScript = preload("res://scripts/player_controller.gd")
const Config = preload("res://scripts/core/world_config.gd")

func _ready() -> void:
    _setup_environment()
    var world: GrimholtWorld = WorldScript.new()
    world.name = "World"
    world.world_seed = Config.DEFAULT_SEED
    add_child(world)
    var player: GrimholtPlayer = PlayerScript.new()
    player.name = "Player"
    add_child(player)
    player.global_position = Vector3(0.0, 43.0, 0.0)
    world.set_player(player)

func _setup_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.16, 0.29, 0.48)
    sky_material.sky_horizon_color = Color(0.62, 0.75, 0.86)
    sky_material.ground_bottom_color = Color(0.16, 0.18, 0.20)
    sky_material.ground_horizon_color = Color(0.52, 0.59, 0.64)
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)
