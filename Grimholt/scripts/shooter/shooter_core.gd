extends Node3D

const PLAYER_SCENE := preload("res://scenes/shooter/player.tscn")
const BOT_SCENE := preload("res://scenes/shooter/bot.tscn")
const PORT := 27015
const MAX_PLAYERS := 12
const SCORE_LIMIT := 50
const KILL_SCORE_POINTS := 1
const ROUND_SECONDS := 900
const BOT_COUNT := 5
const TRANSFORM_MIN_INTERVAL_MSEC := 40
const MAX_REPORTED_SPEED := 12.0
const TRANSFORM_DISTANCE_TOLERANCE := 0.5
const SPAWNS := [Vector3(-17, 1, -17), Vector3(17, 1, 17), Vector3(-17, 1, 17), Vector3(17, 1, -17), Vector3(0, 1, -18), Vector3(0, 1, 18), Vector3(-18, 1, 0), Vector3(18, 1, 0)]

var players: Dictionary = {}
var bots: Dictionary = {}
var scores: Dictionary = {}
var deaths: Dictionary = {}
var round_time := float(ROUND_SECONDS)
var round_end_time_msec := 0
var next_timer_sync_msec := 0
var round_active := false
var hud_layer: CanvasLayer
var menu_layer: CanvasLayer
var status_label: Label
var address_input: LineEdit
var main_menu_container: VBoxContainer
var matchmaking_container: VBoxContainer
var custom_games_container: VBoxContainer
var options_container: VBoxContainer
var score_label: Label
var timer_label: Label
var ammo_label: Label
var health_label: Label
var feed_label: Label
var minimap: Control
var scoreboard_panel: PanelContainer
var scoreboard_label: RichTextLabel
var hitmarker_label: Label
var hitmarker_timer := 0.0
var last_positions: Dictionary = {}
var last_position_times: Dictionary = {}
var last_transform_packet_msec: Dictionary = {}
var last_shot_times: Dictionary = {}
var weapon_ammo: Dictionary = {}
var weapon_reserve: Dictionary = {}
var reload_deadlines: Dictionary = {}
var bot_sync_timer := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_configure_inputs()
	_build_menu()
	_build_hud()
	if OS.has_feature("dedicated_server"):
		host_game()

func _configure_inputs() -> void:
	for pair in [["move_forward", KEY_W], ["move_backward", KEY_S], ["move_left", KEY_A], ["move_right", KEY_D], ["jump", KEY_SPACE], ["reload", KEY_R], ["crouch", KEY_CTRL], ["crouch", KEY_C]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var event := InputEventKey.new()
		event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], event)

func _process(delta: float) -> void:
	if multiplayer.is_server():
		_process_reload_timers()
	if round_active:
		var now_msec := Time.get_ticks_msec()
		var remaining_msec := maxi(0, round_end_time_msec - now_msec)
		round_time = float(remaining_msec) / 1000.0
		if multiplayer.is_server():
			bot_sync_timer += delta
			if bot_sync_timer >= 0.05:
				bot_sync_timer = 0.0
				_sync_bot_states.rpc(_collect_bot_states())
			if now_msec >= next_timer_sync_msec:
				_sync_round_timer.rpc(remaining_msec)
				next_timer_sync_msec = now_msec + 1000
			if remaining_msec == 0:
				_finish_round()
	_update_hud()
	if hitmarker_timer > 0.0:
		hitmarker_timer = maxf(0.0, hitmarker_timer - delta)
		hitmarker_label.visible = hitmarker_timer > 0.0
	if minimap != null:
		minimap.queue_redraw()
