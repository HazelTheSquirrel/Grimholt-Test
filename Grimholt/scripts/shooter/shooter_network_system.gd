extends "res://scripts/shooter/shooter_ui_system.gd"

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
	last_transform_packet_msec.clear()
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
		last_transform_packet_msec.erase(peer_id)
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
	var previous_packet_msec := int(last_transform_packet_msec.get(sender, 0))
	if previous_packet_msec > 0 and now_msec - previous_packet_msec < TRANSFORM_MIN_INTERVAL_MSEC:
		return false
	last_transform_packet_msec[sender] = now_msec
	return true

@rpc("any_peer", "call_remote", "unreliable")
func _submit_input(input_vector: Vector2, jump_requested: bool, wants_crouch: bool, yaw: float, pitch: float) -> void:
	if not multiplayer.is_server():
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

