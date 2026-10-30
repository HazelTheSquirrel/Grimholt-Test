extends Node3D

# Grimholt arena shooter composition root.
# Systems share one Node3D owner; this avoids cyclic script inheritance.

# --- shooter_core.gd ---
const PLAYER_SCENE := preload("res://scenes/shooter/player.tscn")
const BOT_SCENE := preload("res://scenes/shooter/bot.tscn")
const PORT := 27015
const MAX_PLAYERS := 12
const SCORE_LIMIT := 50
const KILL_SCORE_POINTS := 1
const ROUND_SECONDS := 900
const BOT_COUNT := 5
const INPUT_MIN_INTERVAL_MSEC := 40
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
var pause_layer: CanvasLayer
var pause_panel: PanelContainer
var pause_home: VBoxContainer
var pause_options: VBoxContainer
var pause_option_detail: Label
var is_local_paused := false
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
var last_input_packet_msec: Dictionary = {}
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
	_build_pause_menu()
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
				_sync_player_states.rpc(_collect_player_states())
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

# --- shooter_ui_system.gd ---
const GRIMHOLT_CREST := preload("res://assets/branding/grimholt_crest.svg")

func _build_arena() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.34, 0.39, 0.48)
	env.ambient_light_energy = 0.7
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	_add_box("ArenaFloor", Vector3(0, -0.5, 0), Vector3(48, 1, 48), Color(0.13, 0.17, 0.21))
	_add_box("NorthWall", Vector3(0, 3, -24), Vector3(48, 6, 1), Color(0.20, 0.25, 0.31))
	_add_box("SouthWall", Vector3(0, 3, 24), Vector3(48, 6, 1), Color(0.20, 0.25, 0.31))
	_add_box("EastWall", Vector3(24, 3, 0), Vector3(1, 6, 48), Color(0.20, 0.25, 0.31))
	_add_box("WestWall", Vector3(-24, 3, 0), Vector3(1, 6, 48), Color(0.20, 0.25, 0.31))
	var cover := [[Vector3(-10, 1, -8), Vector3(6, 2, 2)], [Vector3(10, 1, 8), Vector3(6, 2, 2)], [Vector3(0, 1.5, 0), Vector3(3, 3, 3)], [Vector3(-15, 1, 8), Vector3(2, 2, 7)], [Vector3(15, 1, -8), Vector3(2, 2, 7)], [Vector3(0, 0.75, -14), Vector3(9, 1.5, 2)], [Vector3(0, 0.75, 14), Vector3(9, 1.5, 2)]]
	for item in cover:
		_add_box("Cover", item[0], item[1], Color(0.27, 0.33, 0.39))

func _add_box(node_name: String, pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 10
	add_child(menu_layer)

	# Use a full-viewport Control + CenterContainer so the menu is laid out
	# reliably at different window sizes and scaling settings.
	var menu_root := Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(menu_root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 520)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := Label.new()
	title.text = "GRIMHOLT // ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	var crest := TextureRect.new()
	crest.texture = GRIMHOLT_CREST
	crest.custom_minimum_size = Vector2(104, 104)
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(crest)

	var intro := Label.new()
	intro.text = "FREE-FOR-ALL  |  50 KILLS  |  15 MIN"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(intro)

	main_menu_container = VBoxContainer.new()
	main_menu_container.add_theme_constant_override("separation", 8)
	column.add_child(main_menu_container)
	_add_menu_button(main_menu_container, "START SOLO GAME", _on_training_pressed)
	_add_menu_button(main_menu_container, "MATCHMAKING", func(): _show_menu_section("matchmaking"))
	_add_menu_button(main_menu_container, "CUSTOM GAMES", func(): _show_menu_section("custom"))
	_add_menu_button(main_menu_container, "OPTIONS", func(): _show_menu_section("options"))

	matchmaking_container = VBoxContainer.new()
	matchmaking_container.add_theme_constant_override("separation", 8)
	matchmaking_container.visible = false
	column.add_child(matchmaking_container)
	var matchmaking_title := Label.new()
	matchmaking_title.text = "MATCHMAKING"
	matchmaking_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	matchmaking_container.add_child(matchmaking_title)
	var matchmaking_info := Label.new()
	matchmaking_info.text = "Die automatische Spielersuche ist noch nicht verfügbar."
	matchmaking_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	matchmaking_container.add_child(matchmaking_info)
	_add_menu_button(matchmaking_container, "ZURÜCK", func(): _show_menu_section("main"))

	custom_games_container = VBoxContainer.new()
	custom_games_container.add_theme_constant_override("separation", 8)
	custom_games_container.visible = false
	column.add_child(custom_games_container)
	var custom_title := Label.new()
	custom_title.text = "CUSTOM GAMES"
	custom_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	custom_games_container.add_child(custom_title)
	address_input = LineEdit.new()
	address_input.placeholder_text = "Server-IP oder Hostname"
	address_input.text = "127.0.0.1"
	custom_games_container.add_child(address_input)
	_add_menu_button(custom_games_container, "SPIEL HOSTEN", _on_host_pressed)
	_add_menu_button(custom_games_container, "SPIEL BEITRETEN", _on_join_pressed)
	_add_menu_button(custom_games_container, "ZURÜCK", func(): _show_menu_section("main"))

	options_container = VBoxContainer.new()
	options_container.add_theme_constant_override("separation", 8)
	options_container.visible = false
	column.add_child(options_container)
	var options_title := Label.new()
	options_title.text = "OPTIONS"
	options_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_container.add_child(options_title)

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.text = "Vollbild"
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	options_container.add_child(fullscreen_toggle)

	var volume_label := Label.new()
	volume_label.text = "Master-Lautstärke"
	options_container.add_child(volume_label)
	var volume_slider := HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	volume_slider.value_changed.connect(_on_master_volume_changed)
	options_container.add_child(volume_slider)
	_add_menu_button(options_container, "ZURÜCK", func(): _show_menu_section("main"))

	status_label = Label.new()
	status_label.text = "WASD bewegen  |  Maus zielen  |  Linksklick feuern"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status_label)

func _build_pause_menu() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 20
	pause_layer.visible = false
	add_child(pause_layer)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.025, 0.04, 0.78)
	pause_layer.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center)
	pause_panel = PanelContainer.new()
	pause_panel.custom_minimum_size = Vector2(520, 480)
	center.add_child(pause_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pause_panel.add_child(column)
	var heading := Label.new()
	heading.text = "GRIMHOLT // PAUSE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	column.add_child(heading)
	pause_home = VBoxContainer.new()
	pause_home.add_theme_constant_override("separation", 8)
	column.add_child(pause_home)
	_add_menu_button(pause_home, "MATCH VERLASSEN", _leave_match)
	_add_menu_button(pause_home, "OPTIONEN", func(): _show_pause_section("options"))
	_add_menu_button(pause_home, "SPIEL VERLASSEN", _quit_game)
	_add_menu_button(pause_home, "WEITERSPIELEN", _resume_match)
	pause_options = VBoxContainer.new()
	pause_options.add_theme_constant_override("separation", 8)
	pause_options.visible = false
	column.add_child(pause_options)
	var options_heading := Label.new()
	options_heading.text = "OPTIONEN"
	options_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_options.add_child(options_heading)
	_add_menu_button(pause_options, "GRAFIK", func(): _show_pause_option_detail("Grafik", "Vollbild und Anzeigeoptionen werden hier verwaltet."))
	_add_menu_button(pause_options, "SOUND", func(): _show_pause_option_detail("Sound", "Audio-Mix und Lautstärke werden hier verwaltet."))
	_add_menu_button(pause_options, "STEUERUNG", func(): _show_pause_option_detail("Steuerung", "Tastenbelegung und Maus-Empfindlichkeit werden hier verwaltet."))
	_add_menu_button(pause_options, "EXTRAS", func(): _show_pause_option_detail("Extras", "HUD-, Barrierefreiheits- und weitere Spieloptionen werden hier verwaltet."))
	pause_option_detail = Label.new()
	pause_option_detail.text = "Wähle einen Optionsbereich."
	pause_option_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_options.add_child(pause_option_detail)
	_add_menu_button(pause_options, "ZURÜCK", func(): _show_pause_section("home"))

func _toggle_pause_menu() -> void:
	if pause_layer == null or not round_active:
		return
	is_local_paused = not is_local_paused
	pause_layer.visible = is_local_paused
	pause_home.visible = true
	pause_options.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_local_paused else Input.MOUSE_MODE_CAPTURED
	if is_local_paused:
		var local_player: Node = players.get(multiplayer.get_unique_id())
		if local_player != null:
			local_player.set("fire_held", false)

func _show_pause_section(section: String) -> void:
	pause_home.visible = section == "home"
	pause_options.visible = section == "options"

func _show_pause_option_detail(section: String, description: String) -> void:
	pause_option_detail.text = section.to_upper() + "\n\n" + description

func _resume_match() -> void:
	is_local_paused = false
	pause_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _leave_match() -> void:
	is_local_paused = false
	pause_layer.visible = false
	round_active = false
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	bots.clear()
	scores.clear()
	deaths.clear()
	last_input_packet_msec.clear()
	last_shot_times.clear()
	weapon_ammo.clear()
	weapon_reserve.clear()
	reload_deadlines.clear()
	for child in get_children():
		if child is CharacterBody3D:
			child.queue_free()
	menu_layer.visible = true
	_show_menu_section("main")
	status_label.text = "MATCH VERLASSEN"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _quit_game() -> void:
	get_tree().quit()

func _add_menu_button(parent: VBoxContainer, button_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(callback)
	parent.add_child(button)

func _show_menu_section(section: String) -> void:
	main_menu_container.visible = section == "main"
	matchmaking_container.visible = section == "matchmaking"
	custom_games_container.visible = section == "custom"
	options_container.visible = section == "options"

func _on_fullscreen_toggled(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _on_master_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value)

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_top = 18
	top.offset_right = -24
	top.custom_minimum_size.y = 42
	hud_layer.add_child(top)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 22)
	top.add_child(timer_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 22)
	top.add_child(score_label)
	var crosshair := Label.new()
	crosshair.text = "＋"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.add_theme_font_size_override("font_size", 28)
	hud_layer.add_child(crosshair)
	health_label = Label.new()
	health_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	health_label.offset_left = 26
	health_label.offset_bottom = -24
	health_label.offset_top = -70
	health_label.add_theme_font_size_override("font_size", 22)
	hud_layer.add_child(health_label)
	ammo_label = Label.new()
	ammo_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.offset_right = -28
	ammo_label.offset_bottom = -24
	ammo_label.offset_top = -82
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(ammo_label)
	feed_label = Label.new()
	feed_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	feed_label.offset_right = -26
	feed_label.offset_top = 74
	feed_label.offset_left = -330
	feed_label.add_theme_font_size_override("font_size", 16)
	feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(feed_label)
	minimap = Control.new()
	minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	minimap.position = Vector2(24, -210)
	minimap.custom_minimum_size = Vector2(160, 160)
	minimap.draw.connect(_draw_minimap)
	hud_layer.add_child(minimap)

	hitmarker_label = Label.new()
	hitmarker_label.text = "✕"
	hitmarker_label.visible = false
	hitmarker_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hitmarker_label.add_theme_font_size_override("font_size", 34)
	hitmarker_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	hud_layer.add_child(hitmarker_label)

	scoreboard_panel = PanelContainer.new()
	scoreboard_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	scoreboard_panel.offset_left = -310
	scoreboard_panel.offset_top = -250
	scoreboard_panel.offset_right = 310
	scoreboard_panel.offset_bottom = 250
	scoreboard_panel.visible = false
	hud_layer.add_child(scoreboard_panel)
	scoreboard_label = RichTextLabel.new()
	scoreboard_label.bbcode_enabled = true
	scoreboard_label.fit_content = true
	scoreboard_label.scroll_active = false
	scoreboard_panel.add_child(scoreboard_label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and round_active:
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if menu_layer != null and menu_layer.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			start_solo_game()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.keycode == KEY_TAB:
		if event.pressed and not event.echo and scoreboard_panel != null:
			scoreboard_panel.visible = true
			_update_scoreboard()
		elif not event.pressed and scoreboard_panel != null:
			scoreboard_panel.visible = false

# --- shooter_network_system.gd ---
func _on_training_pressed() -> void:
	start_solo_game()

func start_solo_game() -> void:
	if _has_active_network_peer():
		status_label.text = "Bitte zuerst die bestehende Verbindung trennen."
		return
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	bots.clear()
	scores.clear()
	deaths.clear()
	last_input_packet_msec.clear()
	for child in get_children():
		if child is CharacterBody3D:
			child.queue_free()
	_start_match()
	_spawn_player(1)
	for i in range(BOT_COUNT):
		_spawn_bot(i + 1000)
	status_label.text = "SOLO MATCH // OFFLINE MIT %d BOTS" % BOT_COUNT

func _on_host_pressed() -> void:
	status_label.text = "SERVER WIRD GESTARTET ..."
	host_game()

func _on_join_pressed() -> void:
	status_label.text = "VERBINDUNG WIRD AUFGEBAUT ..."
	join_game()

func _has_active_network_peer() -> bool:
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED

func host_game() -> void:
	if _has_active_network_peer():
		status_label.text = "Es besteht bereits eine aktive Netzwerkverbindung."
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		status_label.text = "Host fehlgeschlagen: %s" % error
		return
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	status_label.text = "Server aktiv // UDP %d — Match startet" % PORT
	_start_match()
	_spawn_player(1)
	for i in range(BOT_COUNT):
		_spawn_bot(i + 1000)

func join_game() -> void:
	if _has_active_network_peer():
		status_label.text = "Es besteht bereits eine aktive Netzwerkverbindung."
		return
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address_input.text.strip_edges(), PORT)
	if error != OK:
		status_label.text = "Verbindung fehlgeschlagen: %s" % error
		return
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.multiplayer_peer = peer
	status_label.text = "Verbinde mit %s:%d ..." % [address_input.text.strip_edges(), PORT]

func _on_connected_to_server() -> void:
	status_label.text = "VERBUNDEN // Warte auf Match-Start"

func _on_connection_failed() -> void:
	status_label.text = "VERBINDUNG FEHLGESCHLAGEN // IP und Server prüfen"
	multiplayer.multiplayer_peer = null

func _on_server_disconnected() -> void:
	status_label.text = "SERVERVERBINDUNG GETRENNT"
	multiplayer.multiplayer_peer = null

func _start_match() -> void:
	# Monotonic milliseconds keep the round at exactly 900 real seconds,
	# independent of frame rate and floating-point delta accumulation.
	# Host local starten; RPC nur für weitere Clients verwenden.
	_match_started(ROUND_SECONDS * 1000)

@rpc("authority", "call_local", "reliable")
func _match_started(remaining_msec: int) -> void:
	round_active = true
	round_time = float(remaining_msec) / 1000.0
	round_end_time_msec = Time.get_ticks_msec() + remaining_msec
	next_timer_sync_msec = Time.get_ticks_msec() + 1000
	menu_layer.visible = false
	is_local_paused = false
	if pause_layer != null:
		pause_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

@rpc("authority", "call_local", "reliable")
func _sync_round_timer(remaining_msec: int) -> void:
	if not round_active:
		return
	round_time = float(maxi(0, remaining_msec)) / 1000.0
	round_end_time_msec = Time.get_ticks_msec() + maxi(0, remaining_msec)

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_spawn_player(peer_id)
	for id in players:
		if int(id) != peer_id:
			_spawn_player_remote.rpc_id(peer_id, int(id), players[id].global_position)
	for id in bots:
		_spawn_bot_remote.rpc_id(peer_id, int(id), bots[id].global_position)
	_sync_scores.rpc_id(peer_id, scores, deaths)
	_match_started.rpc_id(peer_id, maxi(0, round_end_time_msec - Time.get_ticks_msec()))

func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		_remove_actor.rpc(peer_id)
		players.erase(peer_id)
		scores.erase(peer_id)
		deaths.erase(peer_id)
		last_input_packet_msec.erase(peer_id)
		last_shot_times.erase(peer_id)
		weapon_ammo.erase(peer_id)
		weapon_reserve.erase(peer_id)
		reload_deadlines.erase(peer_id)
		_sync_scores.rpc(scores, deaths)

func _spawn_player(peer_id: int) -> void:
	if players.has(peer_id):
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = "Player_%d" % peer_id
	player.set_multiplayer_authority(peer_id)
	player.position = SPAWNS[players.size() % SPAWNS.size()]
	add_child(player)
	players[peer_id] = player
	scores[peer_id] = 0
	deaths[peer_id] = 0
	last_shot_times[peer_id] = -1000.0
	weapon_ammo[peer_id] = 30
	weapon_reserve[peer_id] = 120
	_sync_weapon_state.rpc(peer_id, 30, 120, false)
	_spawn_player_remote.rpc(peer_id, player.global_position)
	_sync_scores.rpc(scores, deaths)

@rpc("authority", "call_remote", "reliable")
func _spawn_player_remote(peer_id: int, spawn_position: Vector3) -> void:
	if players.has(peer_id):
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = "Player_%d" % peer_id
	player.set_multiplayer_authority(peer_id)
	player.position = spawn_position
	add_child(player)
	players[peer_id] = player

func _spawn_bot(bot_id: int) -> void:
	if bots.has(bot_id):
		return
	var bot := BOT_SCENE.instantiate()
	bot.name = "Bot_%02d" % bot_id
	bot.position = SPAWNS[(bot_id + 3) % SPAWNS.size()]
	bot.configure(bot_id, self)
	add_child(bot)
	bots[bot_id] = bot
	_spawn_bot_remote.rpc(bot_id, bot.global_position)

@rpc("authority", "call_remote", "reliable")
func _spawn_bot_remote(bot_id: int, spawn_position: Vector3) -> void:
	if bots.has(bot_id):
		return
	var bot := BOT_SCENE.instantiate()
	bot.name = "Bot_%02d" % bot_id
	bot.position = spawn_position
	bot.set_multiplayer_authority(1)
	bot.configure(bot_id, self)
	add_child(bot)
	bots[bot_id] = bot
	bot.set_process(false)
	bot.set_physics_process(false)

@rpc("authority", "call_local", "reliable")
func _remove_actor(actor_id: int) -> void:
	var path := "Player_%d" % actor_id
	var node := get_node_or_null(path)
	if node:
		node.queue_free()
	players.erase(actor_id)

func _collect_bot_states() -> Array:
	var states: Array = []
	for id in bots:
		var bot: CharacterBody3D = bots[id]
		states.append([int(id), bot.global_position, bot.rotation.y, bot.health])
	return states

@rpc("authority", "call_remote", "unreliable")
func _sync_bot_states(states: Array) -> void:
	for state in states:
		var id := int(state[0])
		if bots.has(id):
			bots[id].global_position = bots[id].global_position.lerp(state[1], 0.7)
			bots[id].rotation.y = state[2]
			bots[id].health = int(state[3])

func _is_player_input_valid(input_vector: Vector2, yaw: float, pitch: float) -> bool:
	if not input_vector.is_finite() or not is_finite(yaw) or not is_finite(pitch):
		return false
	if input_vector.length() > 1.05:
		return false
	if absf(pitch) > deg_to_rad(85.5) or absf(yaw) > TAU * 1000.0:
		return false
	return true

func _accept_input_packet(sender: int, now_msec: int) -> bool:
	if not players.has(sender):
		return false
	var previous_packet_msec := int(last_input_packet_msec.get(sender, 0))
	if previous_packet_msec > 0 and now_msec - previous_packet_msec < INPUT_MIN_INTERVAL_MSEC:
		return false
	last_input_packet_msec[sender] = now_msec
	return true

@rpc("any_peer", "call_remote", "unreliable")
func _submit_input(input_vector: Vector2, jump_requested: bool, wants_crouch: bool, yaw: float, pitch: float) -> void:
	if not multiplayer.is_server() or not round_active:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not _is_player_input_valid(input_vector, yaw, pitch):
		return
	var now_msec := Time.get_ticks_msec()
	if not _accept_input_packet(sender, now_msec):
		return
	var player: Node = players[sender]
	player.set("remote_move_input", input_vector.limit_length(1.0))
	player.set("remote_jump_requested", jump_requested)
	player.set("remote_crouch_requested", wants_crouch)
	player.set("remote_yaw", yaw)
	player.set("remote_pitch", pitch)
	player.set("remote_input_received_msec", now_msec)

func _collect_player_states() -> Array:
	var states: Array = []
	for id in players:
		var player: Node3D = players[id]
		var head := player.get_node_or_null("Head") as Node3D
		if head != null:
			states.append([int(id), player.global_position, player.rotation.y, head.rotation.x])
	return states

@rpc("authority", "call_remote", "unreliable")
func _sync_player_states(states: Array) -> void:
	for state in states:
		var id := int(state[0])
		if not players.has(id):
			continue
		var player: Node3D = players[id]
		player.global_position = player.global_position.lerp(state[1], 0.45)
		player.rotation.y = state[2]
		var head := player.get_node_or_null("Head") as Node3D
		if head != null:
			head.rotation.x = state[3]

# --- shooter_weapon_system.gd ---
func request_fire(shooter_id: int) -> void:
	if multiplayer.is_server():
		_server_fire(shooter_id)
	else:
		_request_fire.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_fire() -> void:
	if multiplayer.is_server():
		_server_fire(multiplayer.get_remote_sender_id())

func _server_fire(shooter_id: int) -> void:
	if not multiplayer.is_server() or not round_active or not players.has(shooter_id):
		return
	var shooter: Node3D = players[shooter_id]
	if int(shooter.get("health")) <= 0 or reload_deadlines.has(shooter_id):
		return
	var ammo := int(weapon_ammo.get(shooter_id, 0))
	if ammo <= 0:
		_sync_weapon_state.rpc(shooter_id, ammo, int(weapon_reserve.get(shooter_id, 0)), false)
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last_shot_times.get(shooter_id, -1000.0)) < 0.12:
		return
	var head := shooter.get_node_or_null("Head") as Node3D
	if head == null:
		return
	var origin := head.global_position
	var direction := -head.global_transform.basis.z.normalized()
	weapon_ammo[shooter_id] = ammo - 1
	last_shot_times[shooter_id] = now
	_sync_weapon_state.rpc(shooter_id, ammo - 1, int(weapon_reserve.get(shooter_id, 0)), false)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 120.0)
	query.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target: Object = hit.collider
	if target is CharacterBody3D and target.is_in_group("combatants"):
		var victim_id := int(target.get_meta("actor_id", -1))
		if victim_id != shooter_id:
			_hit_confirm.rpc(shooter_id)
			_apply_damage(victim_id, shooter_id, 34)

func request_reload(player_id: int) -> void:
	if multiplayer.is_server():
		_server_reload(player_id)
	else:
		_request_reload.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_reload() -> void:
	if multiplayer.is_server():
		_server_reload(multiplayer.get_remote_sender_id())

func _server_reload(player_id: int) -> void:
	if not multiplayer.is_server() or not round_active or not players.has(player_id):
		return
	if int(players[player_id].get("health")) <= 0 or reload_deadlines.has(player_id):
		return
	var ammo := int(weapon_ammo.get(player_id, 0))
	var reserve := int(weapon_reserve.get(player_id, 0))
	if ammo >= 30 or reserve <= 0:
		return
	reload_deadlines[player_id] = Time.get_ticks_msec() / 1000.0 + 1.65
	_sync_weapon_state.rpc(player_id, ammo, reserve, true)

func _process_reload_timers() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for id in reload_deadlines.keys():
		if now < float(reload_deadlines[id]):
			continue
		var player_id := int(id)
		var ammo := int(weapon_ammo.get(player_id, 0))
		var reserve := int(weapon_reserve.get(player_id, 0))
		var amount := mini(30 - ammo, reserve)
		weapon_ammo[player_id] = ammo + amount
		weapon_reserve[player_id] = reserve - amount
		reload_deadlines.erase(id)
		_sync_weapon_state.rpc(player_id, ammo + amount, reserve - amount, false)

@rpc("authority", "call_local", "reliable")
func _sync_weapon_state(player_id: int, ammo: int, reserve: int, reloading: bool) -> void:
	if players.has(player_id):
		players[player_id].ammo = ammo
		players[player_id].reserve_ammo = reserve
		players[player_id].reload_time = 1.65 if reloading else 0.0

func bot_fire(bot_id: int, origin: Vector3, direction: Vector3) -> void:
	if multiplayer.is_server() and round_active:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction.normalized() * 90.0)
		if bots.has(bot_id):
			query.exclude = [bots[bot_id].get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var target: Object = hit.collider
			if target is CharacterBody3D and target.is_in_group("combatants"):
				var victim_id := int(target.get_meta("actor_id", -1))
				if victim_id != bot_id:
					_apply_damage(victim_id, bot_id, 8)

# --- shooter_combat_system.gd ---
@rpc("authority", "call_local", "reliable")
func _apply_damage(victim_id: int, attacker_id: int, amount: int) -> void:
	if not multiplayer.is_server() or amount <= 0 or amount > 100:
		return
	if not players.has(attacker_id) and not bots.has(attacker_id):
		return
	var target: Node = null
	if players.has(victim_id):
		target = players[victim_id]
	elif bots.has(victim_id):
		target = bots[victim_id]
	if target == null or int(target.get("health")) <= 0:
		return
	var remaining_health := maxi(0, int(target.get("health")) - amount)
	target.set("health", remaining_health)
	_actor_health.rpc(victim_id, remaining_health)
	if remaining_health == 0:
		if players.has(attacker_id):
			scores[attacker_id] = int(scores.get(attacker_id, 0)) + KILL_SCORE_POINTS
			_sync_scores.rpc(scores, deaths)
		var attacker_name := _actor_name(attacker_id)
		var victim_name := _actor_name(victim_id)
		_kill_feed.rpc("%s  »  %s" % [attacker_name, victim_name])
		if players.has(victim_id):
			deaths[victim_id] = int(deaths.get(victim_id, 0)) + 1
			_sync_scores.rpc(scores, deaths)
			_respawn_player_later(victim_id)
		else:
			_respawn_bot_later(victim_id)
		if players.has(attacker_id) and int(scores.get(attacker_id, 0)) >= SCORE_LIMIT:
			_finish_round("score")

func _actor_name(actor_id: int) -> String:
	if bots.has(actor_id):
		return "BOT-%02d" % (actor_id - 1000)
	return "PLAYER-%d" % actor_id

@rpc("authority", "call_local", "reliable")
func _actor_health(actor_id: int, value: int) -> void:
	if players.has(actor_id):
		players[actor_id].health = value
	if bots.has(actor_id):
		bots[actor_id].health = value

@rpc("authority", "call_local", "reliable")
func _kill_feed(message: String) -> void:
	if feed_label:
		feed_label.text = message + "\n" + feed_label.text
		var lines := feed_label.text.split("\n")
		if lines.size() > 4:
			lines.resize(4)
			feed_label.text = "\n".join(lines)

func _respawn_player_later(peer_id: int) -> void:
	await get_tree().create_timer(3.0).timeout
	if players.has(peer_id) and round_active:
		_respawn_actor.rpc(peer_id, SPAWNS[randi() % SPAWNS.size()], 100)

func _respawn_bot_later(bot_id: int) -> void:
	# Dead bots must leave the arena immediately: no corpse should keep
	# blocking movement or remain as a visible, targetable combatant.
	_remove_bot.rpc(bot_id)
	await get_tree().create_timer(3.0).timeout
	if round_active and not bots.has(bot_id):
		_spawn_bot(bot_id)

@rpc("authority", "call_local", "reliable")
func _remove_bot(bot_id: int) -> void:
	if not bots.has(bot_id):
		return
	var bot: Node = bots[bot_id]
	bots.erase(bot_id)
	if is_instance_valid(bot):
		bot.queue_free()

@rpc("authority", "call_local", "reliable")
func _respawn_actor(actor_id: int, pos: Vector3, hp: int) -> void:
	var actor: Node3D = players.get(actor_id, bots.get(actor_id)) as Node3D
	if actor:
		actor.global_position = pos
		actor.set("health", hp)
		if actor is CharacterBody3D:
			(actor as CharacterBody3D).velocity = Vector3.ZERO

@rpc("authority", "call_local", "reliable")
func _sync_scores(new_scores: Dictionary, new_deaths: Dictionary) -> void:
	scores = new_scores.duplicate(true)
	deaths = new_deaths.duplicate(true)
	_update_scoreboard()

@rpc("authority", "call_local", "reliable")
func _hit_confirm(shooter_id: int) -> void:
	if shooter_id == multiplayer.get_unique_id() and hitmarker_label != null:
		hitmarker_timer = 0.16
		hitmarker_label.visible = true

# --- shooter_match_system.gd ---
func _finish_round(reason: String = "time") -> void:
	if not multiplayer.is_server() or not round_active:
		return
	round_active = false
	var winner := -1
	var best := -1
	var tied := false
	for id in scores:
		var points := int(scores[id])
		if points > best:
			best = points
			winner = int(id)
			tied = false
		elif points == best:
			tied = true
	if tied:
		winner = -1
	_round_finished.rpc(winner, maxi(0, best), reason)

@rpc("authority", "call_local", "reliable")
func _round_finished(winner: int, points: int, reason: String) -> void:
	if winner < 0:
		status_label.text = "RUNDE BEENDET // UNENTSCHIEDEN (%d PUNKTE)" % points
	else:
		status_label.text = "RUNDE BEENDET // %s GEWINNT (%d)" % [_actor_name(winner), points]
	timer_label.text = "DEATHMATCH     SCORE LIMIT" if reason == "score" else "DEATHMATCH     00:00"
	menu_layer.visible = true
	is_local_paused = false
	if pause_layer != null:
		pause_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _format_round_time(remaining_msec: int) -> String:
	# Round up partial seconds so 00:00 is shown only once the clock truly expires.
	var total_seconds := ceili(float(maxi(0, remaining_msec)) / 1000.0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]

# --- shooter_hud_system.gd ---
func _update_scoreboard() -> void:
	if scoreboard_label == null:
		return
	var ranking: Array = []
	for id in scores:
		ranking.append([int(id), int(scores[id]), int(deaths.get(id, 0))])
	ranking.sort_custom(func(a, b):
		if a[1] == b[1]:
			return a[2] < b[2]
		return a[1] > b[1]
	)
	var output := "[center][b]GRIMHOLT // SCOREBOARD[/b]\n[b]PLAYER                         K       D[/b]\n"
	for row in ranking:
		output += "%s    %02d    %02d\n" % [_actor_name(row[0]), row[1], row[2]]
	output += "[/center]"
	scoreboard_label.text = output

@rpc("authority", "call_local", "reliable")
func _update_hud() -> void:
	if hud_layer == null:
		return
	timer_label.text = "DEATHMATCH     " + _format_round_time(maxi(0, round_end_time_msec - Time.get_ticks_msec()))
	var ranking: Array = []
	for id in scores:
		ranking.append([int(id), int(scores[id])])
	ranking.sort_custom(func(a, b): return a[1] > b[1])
	var rows: Array[String] = []
	for row in ranking.slice(0, 5):
		rows.append("%s  %02d" % [_actor_name(row[0]), row[1]])
	score_label.text = "TOP FRAGGERS\n" + "\n".join(rows)
	if scoreboard_panel != null and scoreboard_panel.visible:
		_update_scoreboard()
	var local_player: Node3D = players.get(multiplayer.get_unique_id()) as Node3D
	if local_player:
		health_label.text = "VITALS   %03d / 100" % int(local_player.get("health"))
		ammo_label.text = "RIFLE  |  %02d / %03d\n[ R ] RELOAD" % [int(local_player.get("ammo")), int(local_player.get("reserve_ammo"))]
	else:
		health_label.text = "VITALS   --"
		ammo_label.text = "RIFLE  |  -- / --"

func _draw_minimap() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(160, 160))
	minimap.draw_rect(rect, Color(0.025, 0.055, 0.075, 0.78), true)
	minimap.draw_rect(rect, Color(0.45, 0.65, 0.72, 0.9), false, 2.0)
	for x in [24.0, 80.0, 136.0]:
		minimap.draw_line(Vector2(x, 8), Vector2(x, 152), Color(0.28, 0.39, 0.44, 0.5), 1.0)
	for z in [24.0, 80.0, 136.0]:
		minimap.draw_line(Vector2(8, z), Vector2(152, z), Color(0.28, 0.39, 0.44, 0.5), 1.0)
	var local: Node3D = players.get(multiplayer.get_unique_id()) as Node3D
	if local:
		var p := Vector2(80 + local.global_position.x * 2.7, 80 + local.global_position.z * 2.7)
		minimap.draw_circle(p, 5.0, Color(0.35, 0.95, 0.8))
	for id in players:
		if int(id) == multiplayer.get_unique_id():
			continue
		var p: Vector3 = players[id].global_position
		minimap.draw_circle(Vector2(80 + p.x * 2.7, 80 + p.z * 2.7), 3.5, Color(0.9, 0.35, 0.25))
	for id in bots:
		var p: Vector3 = bots[id].global_position
		minimap.draw_circle(Vector2(80 + p.x * 2.7, 80 + p.z * 2.7), 3.0, Color(0.95, 0.72, 0.28))

