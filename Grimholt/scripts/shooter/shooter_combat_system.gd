extends "res://scripts/shooter/shooter_weapon_system.gd"

@rpc("any_peer", "call_remote", "reliable")
@rpc("authority", "call_local", "reliable")
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
