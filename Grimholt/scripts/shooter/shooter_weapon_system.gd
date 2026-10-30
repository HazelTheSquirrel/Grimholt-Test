extends "res://scripts/shooter/shooter_network_system.gd"

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
