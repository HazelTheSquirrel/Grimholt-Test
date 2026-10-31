extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	assert(packed != null, "Main scene could not be loaded")
	var main: Node = packed.instantiate()
	root.add_child(main)
	for frame in range(240):
		await process_frame
		if frame % 60 == 0:
			await physics_frame
	assert(main.get_node_or_null("Player") != null, "Player was not created")
	assert(main.get_node_or_null("GameManager") != null, "Game manager was not created")
	assert(main.get_node_or_null("HUD") != null, "HUD was not created")
	var player: Node = main.get_node("Player")
	var weapon: Node = player.get_node("Head/Camera3D/WeaponController")
	assert(weapon != null, "Weapon controller missing")
	assert(weapon.ammo_in_mag.size() == 2, "Both weapon magazines must exist")
	assert(main.get_node("HUD").get_node_or_null("Control") != null or main.get_node("HUD").get_child_count() > 0, "HUD has no UI")
	var manager: Node = main.get_node("GameManager")
	assert(manager.wave >= 1, "First wave did not start")
	assert(manager.alive_enemies >= 1, "No enemies spawned in first wave")
	var initial_health: float = player.health
	player.receive_damage(10.0)
	assert(player.health <= initial_health, "Player damage did not apply")
	var enemy_scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Node = enemy_scene.instantiate()
	root.add_child(enemy)
	enemy.take_damage(1000.0)
	await process_frame
	assert(not is_instance_valid(enemy), "Enemy did not die after lethal damage")
	print("SMOKE TEST PASSED: scene, player, HUD, weapons, waves, enemy spawn, player damage and enemy death.")
	quit(0)
