extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("Main scene cannot be loaded.")
        return
    var scene := packed.instantiate()
    var required_paths := [
        "TerrainWorld",
        "PlayerBuildings",
        "WorldEnvironment",
        "Sun",
        "Player",
        "Player/CollisionShape3D",
        "Player/BodyVisual",
        "Player/CameraPivot",
        "Player/CameraPivot/Camera3D",
        "Player/Inventory",
        "Player/HUD",
        "Player/HUD/StatusLabel",
        "Player/HUD/Crosshair"
    ]
    for node_path in required_paths:
        if scene.get_node_or_null(NodePath(node_path)) == null:
            _fail("Editable scene node is missing: " + node_path)
            scene.free()
            return
    if not ResourceLoader.exists("res://scripts/world/terrain_world.gd"):
        _fail("Terrain generator script is missing.")
        scene.free()
        return
    scene.free()
    print("PASS: world, player, camera, inventory and HUD are explicit editable main-scene nodes.")
    quit(0)

func _fail(message: String) -> void:
    push_error("Scene structure test: " + message)
    quit(1)
