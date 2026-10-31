extends Node3D
class_name MatchController

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const BOT_SCENE: PackedScene = preload("res://scenes/enemies/arena_bot.tscn")
const BOT_COUNT: int = 5
const MATCH_LENGTH: int = 600

@onready var hud: HUDController = $HUD

var player: PlayerController
var remaining_time: float = MATCH_LENGTH
var _match_running: bool = true

func _ready() -> void:
    _spawn_player()
    _spawn_bots()
    hud.set_time(MATCH_LENGTH)

func _process(delta: float) -> void:
    if not _match_running:
        return
    remaining_time = maxf(0.0, remaining_time - delta)
    hud.set_time(ceili(remaining_time))
    if remaining_time <= 0.0:
        _match_running = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _spawn_player() -> void:
    player = PLAYER_SCENE.instantiate() as PlayerController
    add_child(player)
    player.global_position = Vector3(0, 1.1, 25)
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
        var bot := BOT_SCENE.instantiate() as ArenaBot
        add_child(bot)
        bot.global_position = spawn_points[index]
        bot.set_target(player)
        bot.eliminated.connect(_on_bot_eliminated)

func _on_bot_eliminated(_bot: ArenaBot, killer: Node) -> void:
    if killer == player:
        player.add_score(1)
    get_tree().create_timer(2.0).timeout.connect(_respawn_bot)

func _respawn_bot() -> void:
    if not _match_running:
        return
    var bot := BOT_SCENE.instantiate() as ArenaBot
    add_child(bot)
    bot.global_position = Vector3(randf_range(-22.0, 22.0), 1.1, randf_range(-22.0, 22.0))
    bot.set_target(player)
    bot.eliminated.connect(_on_bot_eliminated)
