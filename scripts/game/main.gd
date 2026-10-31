extends Node3D
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ARENA_BUILDER = preload("res://scripts/world/arena_builder.gd")
const GAME_MANAGER = preload("res://scripts/game/game_manager.gd")
const HUD_SCRIPT = preload("res://scripts/ui/hud.gd")
var player: CharacterBody3D
var game_manager: Node
var hud: CanvasLayer
func _ready() -> void:
	Engine.max_fps = 60
	_build_world()
	player = PLAYER_SCENE.instantiate() as CharacterBody3D
	player.position = Vector3(0, 0.2, 12)
	add_child(player)
	game_manager = GAME_MANAGER.new()
	game_manager.name = "GameManager"
	add_child(game_manager)
	game_manager.call("setup", self, player)
	hud = HUD_SCRIPT.new()
	hud.name = "HUD"
	add_child(hud)
	hud.call("setup", player, game_manager)
func _build_world() -> void:
	var builder = ARENA_BUILDER.new()
	builder.name = "Arena"
	add_child(builder)
	builder.call("build", self)
