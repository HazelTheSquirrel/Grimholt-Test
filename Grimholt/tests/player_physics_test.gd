extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("Main scene could not be loaded.")
        return
    var instance := packed.instantiate()
    root.add_child(instance)
    for i in range(3):
        await physics_frame
    var player := instance.get_node_or_null("Player") as CharacterBody3D
    var terrain := instance.get_node_or_null("TerrainWorld")
    if player == null or terrain == null:
        _fail("Player or terrain missing from main scene.")
        return
    for i in range(120):
        await physics_frame
    var floor_y: float = terrain.height_at(player.global_position.x, player.global_position.z)
    if player.global_position.y < floor_y - 0.15 or player.global_position.y > floor_y + 0.65:
        _fail("Player did not settle on terrain. player_y=%f terrain_y=%f" % [player.global_position.y, floor_y])
        return
    var start := player.global_position
    Input.action_press("move_forward")
    for i in range(30):
        await physics_frame
    Input.action_release("move_forward")
    var distance := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
    if distance < 0.5:
        _fail("Forward input did not move the player. distance=%f" % distance)
        return
    print("PASS: player lands on terrain and forward input moves the character.")
    quit(0)

func _fail(message: String) -> void:
    push_error("Player physics test: " + message)
    quit(1)
