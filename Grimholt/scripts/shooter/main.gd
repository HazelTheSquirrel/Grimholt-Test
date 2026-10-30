extends Node3D

const PLAYER_SCENE := preload("res://scenes/shooter/player.tscn")
const BOT_SCENE := preload("res://scenes/shooter/bot.tscn")
const PORT := 27015
const MAX_PLAYERS := 12
const SCORE_LIMIT := 25
const ROUND_SECONDS := 600
const BOT_COUNT := 5
const SPAWNS := [Vector3(-17, 1, -17), Vector3(17, 1, 17), Vector3(-17, 1, 17), Vector3(17, 1, -17), Vector3(0, 1, -18), Vector3(0, 1, 18), Vector3(-18, 1, 0), Vector3(18, 1, 0)]

var players: Dictionary = {}
var bots: Dictionary = {}
var scores: Dictionary = {}
var round_time := ROUND_SECONDS
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
var last_positions: Dictionary = {}
var last_position_times: Dictionary = {}
var last_shot_times: Dictionary = {}
var bot_sync_timer := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_configure_inputs()
	_build_menu()
	_build_hud()
	if OS.has_feature("dedicated_server"):
		host_game()

func _configure_inputs() -> void:
	for pair in [["move_forward", KEY_W], ["move_backward", KEY_S], ["move_left", KEY_A], ["move_right", KEY_D], ["jump", KEY_SPACE], ["reload", KEY_R]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
		var event := InputEventKey.new()
		event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], event)

func _process(delta: float) -> void:
	if multiplayer.is_server() and round_active:
		round_time = maxf(0.0, round_time - delta)
		bot_sync_timer += delta
		if bot_sync_timer >= 0.05:
			bot_sync_timer = 0.0
			_sync_bot_states.rpc(_collect_bot_states())
		if round_time <= 0.0:
			_finish_round()
	_update_hud()
	if minimap != null:
		minimap.queue_redraw()

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
	add_child(menu_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -230
	panel.offset_top = -260
	panel.offset_right = 230
	panel.offset_bottom = 260
	menu_layer.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := Label.new()
	title.text = "GRIMHOLT // ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)

	var intro := Label.new()
	intro.text = "FREE-FOR-ALL  |  25 KILLS  |  10 MIN"
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
	last_positions.clear()
	last_position_times.clear()
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
	round_active = true
	round_time = ROUND_SECONDS
	# Host local starten; RPC nur für weitere Clients verwenden.
	_match_started(round_time)

@rpc("authority", "call_local", "reliable")
func _match_started(seconds: int) -> void:
	round_active = true
	round_time = seconds
	menu_layer.visible = false

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_spawn_player(peer_id)
	for id in players:
		if int(id) != peer_id:
			_spawn_player_remote.rpc_id(peer_id, int(id), players[id].global_position)
	for id in bots:
		_spawn_bot_remote.rpc_id(peer_id, int(id), bots[id].global_position)
	_sync_scores.rpc_id(peer_id, scores)
	_match_started.rpc_id(peer_id, int(ceil(round_time)))

func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		_remove_actor.rpc(peer_id)
		players.erase(peer_id)
		scores.erase(peer_id)
		last_positions.erase(peer_id)
		last_position_times.erase(peer_id)
		last_shot_times.erase(peer_id)
		_sync_scores.rpc(scores)

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
	last_positions[peer_id] = player.global_position
	last_position_times[peer_id] = Time.get_ticks_msec() / 1000.0
	last_shot_times[peer_id] = -1000.0
	_spawn_player_remote.rpc(peer_id, player.global_position)
	_sync_scores.rpc(scores)

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

@rpc("any_peer", "call_remote", "unreliable")
func _submit_transform(pos: Vector3, yaw: float, pitch: float) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not players.has(sender):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not pos.is_finite() or not is_finite(yaw) or not is_finite(pitch):
		return
	if absf(pitch) > deg_to_rad(85.5) or absf(yaw) > TAU * 1000.0:
		return
	var previous: Vector3 = last_positions.get(sender, players[sender].global_position)
	var elapsed := maxf(0.05, now - float(last_position_times.get(sender, now)))
	var allowed := 8.0 * elapsed + 1.5
	if previous.distance_to(pos) > allowed or absf(pos.x) > 30.0 or absf(pos.z) > 30.0 or pos.y < -2.0 or pos.y > 20.0:
		return
	last_positions[sender] = pos
	last_position_times[sender] = now
	players[sender].global_position = pos
	players[sender].rotation.y = yaw
	players[sender].get_node("Head").rotation.x = pitch
	_relay_transform.rpc(sender, pos, yaw, pitch)

@rpc("authority", "call_remote", "unreliable")
func _relay_transform(peer_id: int, pos: Vector3, yaw: float, pitch: float) -> void:
	if players.has(peer_id) and multiplayer.get_unique_id() != peer_id:
		players[peer_id].global_position = players[peer_id].global_position.lerp(pos, 0.7)
		players[peer_id].rotation.y = yaw
		players[peer_id].get_node("Head").rotation.x = pitch

@rpc("any_peer", "call_remote", "reliable")
func _request_shot(origin: Vector3, direction: Vector3) -> void:
	if multiplayer.is_server():
		_process_shot(multiplayer.get_remote_sender_id(), origin, direction)

func _process_shot(shooter_id: int, origin: Vector3, direction: Vector3) -> void:
	if not round_active or not players.has(shooter_id) or direction.length_squared() < 0.8:
		return
	var shooter: Node3D = players[shooter_id]
	if int(shooter.get("health")) <= 0:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last_shot_times.get(shooter_id, -1000.0)) < 0.115:
		return
	var head := shooter.get_node_or_null("Head") as Node3D
	if head == null:
		return
	var expected_origin := head.global_position
	var expected_direction := -head.global_transform.basis.z.normalized()
	if expected_origin.distance_to(origin) > 1.25 or expected_direction.dot(direction.normalized()) < 0.94:
		return
	last_shot_times[shooter_id] = now
	var query := PhysicsRayQueryParameters3D.create(expected_origin, expected_origin + expected_direction * 120.0)
	query.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target: Object = hit.collider
	if target is CharacterBody3D and target.is_in_group("combatants"):
		var victim_id := int(target.get_meta("actor_id", -1))
		if victim_id == shooter_id:
			return
		_apply_damage(victim_id, shooter_id, 34)

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
					_apply_damage(victim_id, bot_id, 20)

func _apply_damage(victim_id: int, attacker_id: int, amount: int) -> void:
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
		scores[attacker_id] = int(scores.get(attacker_id, 0)) + 1
		_sync_scores.rpc(scores)
		var attacker_name := _actor_name(attacker_id)
		var victim_name := _actor_name(victim_id)
		_kill_feed.rpc("%s  »  %s" % [attacker_name, victim_name])
		if players.has(victim_id):
			_respawn_player_later(victim_id)
		else:
			_respawn_bot_later(victim_id)
		if int(scores[attacker_id]) >= SCORE_LIMIT:
			_finish_round()

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
	await get_tree().create_timer(3.0).timeout
	if bots.has(bot_id) and round_active:
		_respawn_actor.rpc(bot_id, SPAWNS[randi() % SPAWNS.size()], 100)

@rpc("authority", "call_local", "reliable")
func _respawn_actor(actor_id: int, pos: Vector3, hp: int) -> void:
	var actor: Node3D = players.get(actor_id, bots.get(actor_id)) as Node3D
	if actor:
		actor.global_position = pos
		actor.set("health", hp)
		if actor is CharacterBody3D:
			(actor as CharacterBody3D).velocity = Vector3.ZERO

@rpc("authority", "call_local", "reliable")
func _sync_scores(new_scores: Dictionary) -> void:
	scores = new_scores.duplicate(true)

func _finish_round() -> void:
	if not multiplayer.is_server() or not round_active:
		return
	round_active = false
	var winner := -1
	var best := -1
	for id in scores:
		if int(scores[id]) > best:
			best = int(scores[id])
			winner = int(id)
	_round_finished.rpc(winner, best)

@rpc("authority", "call_local", "reliable")
func _round_finished(winner: int, points: int) -> void:
	status_label.text = "RUNDE BEENDET // %s GEWINNT (%d)" % [_actor_name(winner), points]
	menu_layer.visible = true

func _update_hud() -> void:
	if hud_layer == null:
		return
	timer_label.text = "DEATHMATCH     %02d:%02d" % [int(round_time) / 60, int(round_time) % 60]
	var ranking: Array = []
	for id in scores:
		ranking.append([int(id), int(scores[id])])
	ranking.sort_custom(func(a, b): return a[1] > b[1])
	var rows: Array[String] = []
	for row in ranking.slice(0, 5):
		rows.append("%s  %02d" % [_actor_name(row[0]), row[1]])
	score_label.text = "TOP FRAGGERS\n" + "\n".join(rows)
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
