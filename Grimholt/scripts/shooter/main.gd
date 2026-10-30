extends Node3D

const PLAYER_SCENE := preload("res://scenes/shooter/player.tscn")
const PORT := 27015
const MAX_PLAYERS := 12
const SCORE_LIMIT := 25
const ROUND_SECONDS := 600

var players: Dictionary = {}
var scores: Dictionary = {}
var round_time := ROUND_SECONDS
var round_active := true
var hud: Label
var status: Label
var address_input: LineEdit

func _ready() -> void:
	_configure_inputs()
	_build_arena()
	_build_menu()
	_build_hud()
	if OS.has_feature("dedicated_server"):
		host_game()

func _configure_inputs() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_backward", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)

func _add_key_action(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)

func _process(delta: float) -> void:
	if multiplayer.is_server() and round_active:
		round_time = maxf(0.0, round_time - delta)
		if round_time <= 0.0:
			_finish_round()
	_update_hud()

func _build_arena() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.34, 0.39, 0.48)
	environment.ambient_light_energy = 0.7
	world_env.environment = environment
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.25
	add_child(sun)
	_add_box("ArenaFloor", Vector3(0, -0.5, 0), Vector3(48, 1, 48), Color(0.16, 0.19, 0.23))
	_add_box("NorthWall", Vector3(0, 3, -24), Vector3(48, 6, 1), Color(0.20, 0.25, 0.31))
	_add_box("SouthWall", Vector3(0, 3, 24), Vector3(48, 6, 1), Color(0.20, 0.25, 0.31))
	_add_box("EastWall", Vector3(24, 3, 0), Vector3(1, 6, 48), Color(0.20, 0.25, 0.31))
	_add_box("WestWall", Vector3(-24, 3, 0), Vector3(1, 6, 48), Color(0.20, 0.25, 0.31))
	var cover := [
		[Vector3(-10, 1, -8), Vector3(6, 2, 2)], [Vector3(10, 1, 8), Vector3(6, 2, 2)],
		[Vector3(0, 1.5, 0), Vector3(3, 3, 3)], [Vector3(-15, 1, 8), Vector3(2, 2, 7)],
		[Vector3(15, 1, -8), Vector3(2, 2, 7)], [Vector3(0, 0.75, -14), Vector3(9, 1.5, 2)],
		[Vector3(0, 0.75, 14), Vector3(9, 1.5, 2)]
	]
	for item in cover:
		_add_box("Cover", item[0], item[1], Color(0.27, 0.33, 0.39))

func _add_box(node_name: String, position: Vector3, dimensions: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
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
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.custom_minimum_size = Vector2(330, 190)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "GRIMHOLT // ARENA"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	address_input = LineEdit.new()
	address_input.placeholder_text = "Server-IP (z. B. 127.0.0.1)"
	address_input.text = "127.0.0.1"
	column.add_child(address_input)
	var host_button := Button.new()
	host_button.text = "Spiel hosten"
	host_button.pressed.connect(host_game)
	column.add_child(host_button)
	var join_button := Button.new()
	join_button.text = "Server beitreten"
	join_button.pressed.connect(join_game)
	column.add_child(join_button)
	status = Label.new()
	status.text = "Noch nicht verbunden"
	column.add_child(status)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(24, 230)
	hud.add_theme_font_size_override("font_size", 20)
	layer.add_child(hud)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.add_theme_font_size_override("font_size", 28)
	layer.add_child(crosshair)

func host_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		status.text = "Host fehlgeschlagen: %s" % error
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	status.text = "Server läuft auf Port %d" % PORT
	_on_peer_connected(1)

func join_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address_input.text.strip_edges(), PORT)
	if error != OK:
		status.text = "Verbindung fehlgeschlagen: %s" % error
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(func(): status.text = "Verbunden")
	multiplayer.connection_failed.connect(func(): status.text = "Verbindung fehlgeschlagen")
	multiplayer.server_disconnected.connect(func(): status.text = "Server getrennt")

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_spawn_player.rpc(peer_id)
	for existing_id in players.keys():
		_spawn_player.rpc_id(peer_id, int(existing_id))
	_sync_scores.rpc(scores)

func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		players[peer_id].queue_free()
		players.erase(peer_id)
		scores.erase(peer_id)
		_sync_scores.rpc(scores)

@rpc("authority", "call_local", "reliable")
func _spawn_player(peer_id: int) -> void:
	if players.has(peer_id):
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = "Player_%d" % peer_id
	player.set_multiplayer_authority(peer_id)
	var spawn_points := [Vector3(-16, 1, -16), Vector3(16, 1, 16), Vector3(-16, 1, 16), Vector3(16, 1, -16), Vector3(0, 1, -18), Vector3(0, 1, 18)]
	player.position = spawn_points[players.size() % spawn_points.size()]
	add_child(player)
	players[peer_id] = player
	if multiplayer.is_server():
		scores[peer_id] = 0
		_sync_scores.rpc(scores)

@rpc("any_peer", "call_remote", "unreliable")
func _submit_transform(position: Vector3, yaw: float, pitch: float) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not players.has(sender):
		return
	var player: CharacterBody3D = players[sender]
	if player.global_position.distance_to(position) > 3.0:
		return
	player.global_position = position
	player.rotation.y = yaw
	player.get_node("Head").rotation.x = pitch
	_relay_transform.rpc(sender, position, yaw, pitch)

@rpc("authority", "call_remote", "unreliable")
func _relay_transform(peer_id: int, position: Vector3, yaw: float, pitch: float) -> void:
	if multiplayer.get_unique_id() == peer_id or not players.has(peer_id):
		return
	var player: CharacterBody3D = players[peer_id]
	player.global_position = player.global_position.lerp(position, 0.65)
	player.rotation.y = yaw
	player.get_node("Head").rotation.x = pitch

func _request_shot_local(shooter_id: int, origin: Vector3, direction: Vector3) -> void:
	_process_shot(shooter_id, origin, direction)

@rpc("any_peer", "call_remote", "reliable")
func _request_shot(origin: Vector3, direction: Vector3) -> void:
	if multiplayer.is_server():
		_process_shot(multiplayer.get_remote_sender_id(), origin, direction)

func _process_shot(shooter_id: int, origin: Vector3, direction: Vector3) -> void:
	if not multiplayer.is_server() or not round_active or not players.has(shooter_id):
		return
	var shooter: Node3D = players[shooter_id]
	if shooter.global_position.distance_to(origin) > 3.0:
		return
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction.normalized() * 120.0)
	query.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target = hit.collider
	if not target is CharacterBody3D or not target.is_in_group("players"):
		return
	var target_id := int(target.get_meta("peer_id", 0))
	if target_id == shooter_id or not players.has(target_id):
		return
	_target_died.rpc(target_id, shooter_id)

@rpc("authority", "call_local", "reliable")
func _target_died(victim_id: int, killer_id: int) -> void:
	if players.has(victim_id):
		players[victim_id].global_position = Vector3(0, -100, 0)
	if multiplayer.is_server():
		scores[killer_id] = int(scores.get(killer_id, 0)) + 1
		_sync_scores.rpc(scores)
		if scores[killer_id] >= SCORE_LIMIT:
			_finish_round()
		else:
			_respawn_later(victim_id)

func _respawn_later(peer_id: int) -> void:
	await get_tree().create_timer(2.0).timeout
	if players.has(peer_id) and round_active:
		var spawn_points := [Vector3(-16, 1, -16), Vector3(16, 1, 16), Vector3(-16, 1, 16), Vector3(16, 1, -16), Vector3(0, 1, -18), Vector3(0, 1, 18)]
		_respawn_player.rpc(peer_id, spawn_points[randi() % spawn_points.size()])

@rpc("authority", "call_local", "reliable")
func _respawn_player(peer_id: int, spawn_position: Vector3) -> void:
	if players.has(peer_id):
		players[peer_id].global_position = spawn_position
		players[peer_id].velocity = Vector3.ZERO

@rpc("authority", "call_local", "reliable")
func _sync_scores(new_scores: Dictionary) -> void:
	scores = new_scores.duplicate(true)

func _finish_round() -> void:
	if not multiplayer.is_server() or not round_active:
		return
	round_active = false
	var winner := -1
	var best := -1
	for peer_id in scores:
		if int(scores[peer_id]) > best:
			best = int(scores[peer_id])
			winner = int(peer_id)
	_round_finished.rpc(winner, best)

@rpc("authority", "call_local", "reliable")
func _round_finished(winner: int, points: int) -> void:
	status.text = "Runde beendet – Spieler %d gewinnt mit %d Punkten" % [winner, points]

func _update_hud() -> void:
	if hud == null:
		return
	var lines := ["DEATHMATCH  |  Ziel: %d Punkte  |  Zeit: %02d:%02d" % [SCORE_LIMIT, int(round_time) / 60, int(round_time) % 60]]
	var ordered := scores.keys()
	ordered.sort()
	for peer_id in ordered:
		lines.append("Spieler %d: %d" % [peer_id, int(scores[peer_id])])
	hud.text = "\n".join(lines)
