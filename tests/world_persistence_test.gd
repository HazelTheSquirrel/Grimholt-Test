extends SceneTree

const WorldScript = preload("res://scripts/world/world_generator.gd")
const Blocks = preload("res://scripts/world/block_registry.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var first_world = WorldScript.new()
    root.add_child(first_world)
    var positive_edge := Vector3i(15, 40, 1)
    var negative_chunk := Vector3i(-1, 40, -1)

    if not first_world.set_voxel(positive_edge, Blocks.DIRT):
        push_error("Persistence test: could not edit positive chunk edge.")
        quit(1)
        return
    if not first_world.set_voxel(negative_chunk, Blocks.SAND):
        push_error("Persistence test: could not edit negative chunk.")
        quit(1)
        return

    first_world.save_world()
    first_world.queue_free()
    await process_frame

    var second_world = WorldScript.new()
    root.add_child(second_world)
    if second_world.get_voxel(positive_edge) != Blocks.DIRT:
        push_error("Persistence test: positive chunk edit was not restored.")
        quit(1)
        return
    if second_world.get_voxel(negative_chunk) != Blocks.SAND:
        push_error("Persistence test: negative chunk edit was not restored.")
        quit(1)
        return

    second_world.queue_free()
    await process_frame
    print("PASS: voxel edits persist across reloads, including negative chunk coordinates.")
    quit(0)
