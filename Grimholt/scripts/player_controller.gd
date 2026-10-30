extends CharacterBody3D
class_name GrimholtPlayer

const WALK_SPEED := 5.5
const SPRINT_SPEED := 8.5
const JUMP_VELOCITY := 5.0
const MOUSE_SENSITIVITY := 0.002
const INTERACTION_DISTANCE := 5.0

var camera_pivot: Node3D
var camera: Camera3D
var body_visual: MeshInstance3D
var inventory: GrimholtInventory
var professions := GrimholtProfessionSystem.new()
var building_system: GrimholtBuildingSystem
var selected_piece := "foundation"
var build_mode := false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var status_label: Label

func _ready() -> void:
    _configure_input_actions()
    _create_body()
    _create_hud()
    floor_snap_length = 0.35
    floor_max_angle = deg_to_rad(50.0)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _configure_input_actions() -> void:
    _add_key_action("move_forward", KEY_W)
    _add_key_action("move_backward", KEY_S)
    _add_key_action("move_left", KEY_A)
    _add_key_action("move_right", KEY_D)

func _add_key_action(action_name: String, key: Key) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
    for existing in InputMap.action_get_events(action_name):
        if existing is InputEventKey and existing.physical_keycode == key:
            return
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action_name, event)

func _create_body() -> void:
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    collider.shape = capsule
    collider.position.y = 0.9
    add_child(collider)
    body_visual = MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.36
    body_mesh.height = 1.75
    body_visual.mesh = body_mesh
    body_visual.position.y = 0.9
    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = Color(0.22, 0.25, 0.29)
    body_visual.material_override = body_material
    add_child(body_visual)
    camera_pivot = Node3D.new()
    camera_pivot.position.y = 1.55
    camera_pivot.rotation.x = deg_to_rad(-12.0)
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0.0, 0.45, 5.2)
    camera.fov = 72.0
    camera.current = true
    camera_pivot.add_child(camera)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    status_label = Label.new()
    status_label.position = Vector2(18, 16)
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
    status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
    status_label.add_theme_constant_override("shadow_offset_x", 2)
    status_label.add_theme_constant_override("shadow_offset_y", 2)
    layer.add_child(status_label)
    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-5, -13)
    crosshair.add_theme_font_size_override("font_size", 24)
    layer.add_child(crosshair)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-45), deg_to_rad(30))
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        elif event.keycode == KEY_B:
            build_mode = not build_mode
        elif event.keycode == KEY_1:
            selected_piece = "foundation"
        elif event.keycode == KEY_2:
            selected_piece = "wall"
        elif event.keycode == KEY_3:
            selected_piece = "roof"
        elif event.keycode == KEY_C:
            _craft("wooden_plank")
    elif event is InputEventMouseButton and event.pressed:
        if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        elif event.button_index == MOUSE_BUTTON_LEFT and build_mode:
            _place_building_piece()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_key_pressed(KEY_SPACE):
        velocity.y = JUMP_VELOCITY
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var local_direction := Vector3(input_vector.x, 0.0, input_vector.y)
    var direction := local_direction.rotated(Vector3.UP, camera_pivot.global_rotation.y).normalized()
    var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
    if direction.length() > 0.01:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        var target_yaw := atan2(-direction.x, -direction.z)
        body_visual.rotation.y = lerp_angle(body_visual.rotation.y, target_yaw, delta * 9.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 5.0 * delta)
    move_and_slide()
    _update_hud()

func _unhandled_key_input(event: InputEvent) -> void:
    if event.pressed and not event.echo and event.keycode == KEY_E:
        _interact()

func _interact() -> void:
    var hit := _raycast()
    if hit.is_empty():
        return
    var target: Object = hit.get("collider")
    if target != null and target.has_method("harvest"):
        target.harvest(inventory)

func _place_building_piece() -> void:
    if building_system == null:
        return
    var hit := _raycast()
    if hit.is_empty():
        return
    building_system.place_piece(selected_piece, hit.position, inventory)

func _raycast() -> Dictionary:
    if camera == null:
        return {}
    var origin := camera.global_position
    var endpoint := origin - camera.global_transform.basis.z * INTERACTION_DISTANCE
    var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
    query.exclude = [get_rid()]
    query.collision_mask = 1
    return get_world_3d().direct_space_state.intersect_ray(query)

func _craft(recipe_id: String) -> void:
    GrimholtCraftingSystem.craft(recipe_id, inventory, professions)

func _update_hud() -> void:
    if status_label == null or inventory == null:
        return
    var mode_text := "BAUMODUS: %s (1 Fundament / 2 Wand / 3 Dach)" % selected_piece if build_mode else "E: Ressource ernten | B: Baumodus | C: Holzplanken herstellen"
    status_label.text = "GRIMHOLT – FANTASY SANDBOX\nWASD: Bewegen | SHIFT: Sprint | LEERTASTE: Springen | Maus: Kamera | ESC: Maus lösen\n%s\n%s" % [mode_text, inventory.get_summary()]
