extends Node3D
class_name MatchController

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const BOT_SCENE: PackedScene = preload("res://scenes/enemies/arena_bot.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const BOT_COUNT: int = 5
const MATCH_LENGTH: int = 600

@onready var hud: HUDController = $HUD

var player: PlayerController
var pause_menu: PauseMenuController
var remaining_time: float = MATCH_LENGTH
var _match_running: bool = true
var _is_paused: bool = false

func _ready() -> void:
	pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenuController
	add_child(pause_menu)
	pause_menu.resume_requested.connect(_resume_match)
	pause_menu.restart_requested.connect(_restart_match)
	pause_menu.quit_requested.connect(_quit_game)
	_spawn_player()
	_spawn_bots()
	hud.set_time(MATCH_LENGTH)

func _process(delta: float) -> void:
	if not _match_running or _is_paused:
		return
	remaining_time = maxf(0.0, remaining_time - delta)
	hud.set_time(ceili(remaining_time))
	if remaining_time <= 0.0:
		_match_running = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_menu.show_match_result(player.score)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as PlayerController
	add_child(player)
	player.global_position = Vector3(0, 1.1, 25)
	player.pause_requested.connect(_toggle_pause)
	player.hit_confirmed.connect(hud.show_hit_marker)
	player.weapon_changed.connect(hud.set_weapon)
	player.health_changed.connect(hud.set_health)
	player.ammo_changed.connect(hud.set_ammo)
	player.score_changed.connect(hud.set_score)

func _spawn_bots() -> void:
	var spawn_points: Array[Vector3] = [
		Vector3(-20, 1.1, -20), Vector3(20, 1.1, -20),
		Vector3(-20, 1.1, 20), Vector3(20, 1.1, 20),
		Vector3(0, 1.1, -24)
	]
	for index in range(BOT_COUNT):
		_spawn_bot(spawn_points[index])

func _spawn_bot(spawn_position: Vector3) -> void:
	var bot := BOT_SCENE.instantiate() as ArenaBot
	add_child(bot)
	bot.global_position = spawn_position
	bot.set_target(player)
	bot.eliminated.connect(_on_bot_eliminated)

func _on_bot_eliminated(_bot: ArenaBot, killer: Node) -> void:
	if killer == player:
		player.add_score(1)
		hud.show_kill_marker()
	get_tree().create_timer(2.0).timeout.connect(_respawn_bot)

func _respawn_bot() -> void:
	if not _match_running:
		return
	_spawn_bot(Vector3(randf_range(-22.0, 22.0), 1.1, randf_range(-22.0, 22.0)))

func _toggle_pause() -> void:
	if not _match_running:
		return
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	player.set_local_paused(_is_paused)
	pause_menu.set_menu_visible(_is_paused)

func _resume_match() -> void:
	_is_paused = false
	get_tree().paused = false
	player.set_local_paused(false)
	pause_menu.set_menu_visible(false)

func _restart_match() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
