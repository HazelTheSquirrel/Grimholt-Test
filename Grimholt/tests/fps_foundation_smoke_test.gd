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

	var game := packed.instantiate() as MatchController
	root.add_child(game)
	await process_frame
	await process_frame

	_check(game.get_node_or_null("Player") != null, "Player must spawn")
	_check(game.get_node_or_null("HUD") != null, "HUD scene must be instanced")
	_check(game.get_node_or_null("PauseMenu") != null, "Pause menu scene must be instanced")
	_check(get_nodes_in_group("enemies").size() == 5, "Exactly five arena bots must spawn")

	var player := game.get_node_or_null("Player") as PlayerController
	if player != null:
		_check(player.get_node_or_null("Head/Camera3D") != null, "First-person camera must exist")
		_check(player.get_node_or_null("Head/Camera3D/PulseCarbine") != null, "Pulse Carbine scene must exist")
		_check(player.has_method("take_damage"), "Player damage receiver must exist")
		_check(player.has_method("add_score"), "Player score receiver must exist")
		_check(player.weapons.size() == 2, "Two distinct weapon roles must be available")
		_check(player.weapon.display_name == "PULSE CARBINE", "Pulse Carbine must be the starting weapon")
		player._switch_weapon()
		_check(player.weapon.display_name == "ARC SCATTER", "Q weapon switch must select Arc Scatter")
		_check(player.weapon.magazine_size == 8 and player.weapon.pellet_count == 7, "Arc Scatter must have its close-range multi-pellet role")
		player._switch_weapon()
		_check(player.weapon.display_name == "PULSE CARBINE", "Weapon cycling must return to Pulse Carbine")

	var hud := game.get_node_or_null("HUD") as HUDController
	if hud != null:
		_check(hud.has_method("set_health"), "HUD health binding must exist")
		_check(hud.has_method("set_ammo"), "HUD ammunition binding must exist")
		_check(hud.has_method("set_time"), "HUD match timer binding must exist")
		_check(hud.has_method("show_hit_marker"), "HUD hit feedback must exist")
		_check(hud.has_method("show_kill_marker"), "HUD elimination feedback must exist")
		_check(hud.has_method("set_weapon"), "HUD active weapon binding must exist")

	_check(InputMap.has_action("move_forward"), "Forward movement action must be configured")
	_check(InputMap.has_action("fire"), "Fire action must be configured")
	_check(InputMap.has_action("reload"), "Reload action must be configured")
	_check(InputMap.has_action("switch_weapon"), "Weapon switching action must be configured")

	if game != null and game.has_method("_toggle_pause"):
		game._toggle_pause()
		_check(get_tree().paused, "Pause action must pause the solo match")
		_check(game.pause_menu.is_menu_visible(), "Pause overlay must be visible")
		game._resume_match()
		_check(not get_tree().paused, "Resume action must unpause the solo match")
		_check(not game.pause_menu.is_menu_visible(), "Resume action must hide the pause overlay")
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
