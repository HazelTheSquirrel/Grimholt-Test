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
	assert(game.get_script().resource_path == "res://scripts/shooter/main.gd", "Main scene must use the composition-root script")
	assert(load("res://assets/branding/grimholt_crest.svg") != null, "Original Grimholt crest asset is missing")
	assert(load("res://assets/branding/rifle_insignia.svg") != null, "Original rifle insignia asset is missing")
	assert(load("res://assets/materials/arena_floor.svg") != null, "Original arena floor material is missing")
	assert(load("res://scripts/shooter/shooter_weapon_system.gd") != null, "Weapon system script is missing")
	assert(load("res://scripts/shooter/shooter_match_system.gd") != null, "Match system script is missing")
	assert(InputMap.has_action("crouch"), "Crouch action was not registered")
	assert(InputMap.has_action("jump"), "Jump action was not registered")
	game.start_solo_game()
	await process_frame
	assert(game.players.has(1), "Solo player did not spawn")
	assert(game.bots.size() == 5, "Expected five bots in solo mode")
	assert(game.SCORE_LIMIT == 50, "Round kill limit should be 50")
	assert(game.ROUND_SECONDS == 900, "Round duration should be 15 minutes")
	assert(game._format_round_time(900000) == "15:00", "900 seconds must display as 15:00")
	assert(game._format_round_time(61000) == "01:01", "Countdown must use real seconds")
	assert(game._format_round_time(60000) == "01:00", "Minute boundary must display correctly")
	assert(game._format_round_time(999) == "00:01", "Timer must not show 00:00 before expiry")
	assert(game._format_round_time(0) == "00:00", "Expired timer must display 00:00")
	assert(game.round_end_time_msec > Time.get_ticks_msec(), "Round must use a future monotonic deadline")
	assert(game.scoreboard_panel != null, "Scoreboard UI was not created")
	assert(game.hitmarker_label != null, "Hit confirmation UI was not created")
	var player: Node = game.players[1]
	assert(player.get_node_or_null("Head/Camera3D") != null, "Player camera is missing")
	assert(player.get_node("Head/Camera3D").current, "Local player camera is not current")
	var score_before_kill := int(game.scores.get(1, 0))
	game._apply_damage(1000, 1, 100)
	assert(int(game.scores.get(1, 0)) == score_before_kill + 1, "Every kill must award exactly one point")
	game._apply_damage(1000, 1, 100)
	assert(int(game.scores.get(1, 0)) == score_before_kill + 1, "A dead target must not award duplicate kill points")
	assert(not game.scores.has(1000), "Bots must not appear as independent FFA score leaders")
	assert(not game.bots.has(1000), "Dead bot should be removed immediately")
	await create_timer(3.2).timeout
	assert(game.bots.has(1000), "Bot should respawn after its delay")
	assert(game.bots[1000].health == 100, "Respawned bot should have full health")
	# A short real-time deadline proves the clock expires by elapsed wall time,
	# rather than by a minutes/seconds formatting or frame-count shortcut.
	game.round_end_time_msec = Time.get_ticks_msec() + 1100
	await create_timer(1.25).timeout
	assert(not game.round_active, "Round must finish when the real-time deadline reaches zero")
	assert(game.timer_label.text.ends_with("00:00"), "Expired round must show 00:00")
	game._round_finished.rpc(-1, 0, "score")
	assert(game.timer_label.text.ends_with("SCORE LIMIT"), "A score-limit finish must not falsely display 00:00")
	print("SHOOTER_SMOKE_TEST_OK: scene, input, player, bots, HUD, real-time countdown, one-point kill scoring, bot death/respawn")
	quit(0)
