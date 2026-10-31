extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    assert(packed != null, "Main scene must load")
    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    assert(game.get_node_or_null("Player") != null, "Player must spawn")
    assert(game.get_node_or_null("HUD") != null, "HUD scene must be instanced")
    assert(get_nodes_in_group("enemies").size() == 5, "Five arena bots must spawn")
    var player: Node = game.get_node("Player")
    assert(player.get_node_or_null("Head/Camera3D") != null, "First-person camera must exist")
    assert(player.get_node_or_null("Head/Camera3D/PulseCarbine") != null, "Weapon scene must exist")
    print("GRIMHOLT_FPS_SMOKE_TEST_OK")
    quit(0)
