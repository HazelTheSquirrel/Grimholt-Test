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
    if player == null:
        _fail("Player missing from main scene.")
        return
    for i in range(120):
        await physics_frame

    if not player.is_on_floor():
        _fail("Player is not grounded after falling. position=%s velocity=%s" % [player.global_position, player.velocity])
        return

    var ray_start := player.global_position + Vector3.UP * 5.0
    var ray_end := player.global_position - Vector3.UP * 5.0
    var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
    query.exclude = [player.get_rid()]
    var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        _fail("No terrain collision found directly beneath the player.")
        return
    var ground_gap: float = player.global_position.y - hit.position.y
    if ground_gap < -0.15 or ground_gap > 0.2:
        _fail("Player capsule is not resting on the collision surface. gap=%f player=%s ground=%s" % [ground_gap, player.global_position, hit.position])
        return


    var player_controller := player as GrimholtPlayer
    for i in range(8):
        var zoom_in := InputEventMouseButton.new()
        zoom_in.button_index = MOUSE_BUTTON_WHEEL_UP
        zoom_in.pressed = true
        player_controller._unhandled_input(zoom_in)
    if player_controller.camera_distance > GrimholtPlayer.FIRST_PERSON_THRESHOLD or player_controller.body_visual.visible:
        _fail("Mouse wheel did not switch cleanly into first-person camera mode.")
        return
    var look_up := InputEventMouseMotion.new()
    look_up.relative = Vector2(0.0, -10000.0)
    player_controller._unhandled_input(look_up)
    if player_controller.camera_pivot.rotation.x < deg_to_rad(-80.1):
        _fail("Camera pitch escaped its safe upward look limit.")
        return
    for i in range(8):
        var zoom_out := InputEventMouseButton.new()
        zoom_out.button_index = MOUSE_BUTTON_WHEEL_DOWN
        zoom_out.pressed = true
        player_controller._unhandled_input(zoom_out)
    if player_controller.camera_distance <= GrimholtPlayer.FIRST_PERSON_THRESHOLD or not player_controller.body_visual.visible:
        _fail("Mouse wheel did not return cleanly to third-person camera mode.")
        return

    var start := player.global_position
    if not is_equal_approx((player.get_node("CollisionShape3D").shape as CapsuleShape3D).height, 1.75):
        _fail("Player physical capsule is not 1.75 metres tall.")
        return
    Input.action_press("move_forward")
    for i in range(30):
        await physics_frame
    Input.action_release("move_forward")
    var distance := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
    if distance < 0.5:
        _fail("Forward input did not move the player. distance=%f" % distance)
        return

    if player.velocity.length() > 0.1:\n        _fail("Player should decelerate after releasing movement input.")\n        return\n\n    print("PASS: 1.75 m player remains grounded, camera zoom works, and accelerated movement responds to input.")
    quit(0)

func _fail(message: String) -> void:
    push_error("Player physics test: " + message)
    quit(1)
