extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_test")

func _run_smoke_test() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "Main scene could not be loaded")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	assert(game.has_method("start_solo_game"), "Main scene is missing solo start")
	assert(InputMap.has_action("crouch"), "Crouch action was not registered")
	assert(InputMap.has_action("jump"), "Jump action was not registered")
	game.start_solo_game()
	await process_frame
	assert(game.players.has(1), "Solo player did not spawn")
	assert(game.bots.size() == 5, "Expected five bots in solo mode")
	assert(game.scoreboard_panel != null, "Scoreboard UI was not created")
	assert(game.hitmarker_label != null, "Hit confirmation UI was not created")
	var player: Node = game.players[1]
	assert(player.get_node_or_null("Head/Camera3D") != null, "Player camera is missing")
	assert(player.get_node("Head/Camera3D").current, "Local player camera is not current")
	print("SHOOTER_SMOKE_TEST_OK: scene, input, player, bots, HUD")
	quit(0)
