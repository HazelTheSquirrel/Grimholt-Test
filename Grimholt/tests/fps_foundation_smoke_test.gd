extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "Main scene must load")
	if packed == null:
		_finish()
		return

	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	_check(game.get_node_or_null("Player") != null, "Player must spawn")
	_check(game.get_node_or_null("HUD") != null, "HUD scene must be instanced")
	_check(game.get_node_or_null("PauseMenu") != null, "Pause menu scene must be instanced")
	_check(get_nodes_in_group("enemies").size() == 5, "Exactly five arena bots must spawn")

	var player := game.get_node_or_null("Player")
	if player != null:
		_check(player.get_node_or_null("Head/Camera3D") != null, "First-person camera must exist")
		_check(player.get_node_or_null("Head/Camera3D/PulseCarbine") != null, "Pulse Carbine scene must exist")
		_check(player.has_method("take_damage"), "Player damage receiver must exist")
		_check(player.has_method("add_score"), "Player score receiver must exist")

	var hud := game.get_node_or_null("HUD")
	if hud != null:
		_check(hud.has_method("set_health"), "HUD health binding must exist")
		_check(hud.has_method("set_ammo"), "HUD ammunition binding must exist")
		_check(hud.has_method("set_time"), "HUD match timer binding must exist")
		_check(hud.has_method("show_hit_marker"), "HUD hit feedback must exist")
		_check(hud.has_method("show_kill_marker"), "HUD elimination feedback must exist")

	_check(InputMap.has_action("move_forward"), "Forward movement action must be configured")
	_check(InputMap.has_action("fire"), "Fire action must be configured")
	_check(InputMap.has_action("reload"), "Reload action must be configured")

	print("GRIMHOLT_FPS_SMOKE_TEST: %d failure(s)" % failures.size())
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("GRIMHOLT_FPS_SMOKE_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
