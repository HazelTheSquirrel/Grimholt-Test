extends CharacterBody3D
class_name GrimholtPlayer

const WALK_SPEED := 6.5
const SPRINT_SPEED := 10.0
const JUMP_VELOCITY := 5.8
const MOUSE_SENSITIVITY := 0.0022
const INTERACTION_DISTANCE := 6.0
const Blocks = preload("res://scripts/world/block_registry.gd")

var camera_pivot: Node3D
var camera: Camera3D
var interaction_world: GrimholtWorld
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
    _create_input_actions()
    _build_body()
    _build_hud()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_world(world: GrimholtWorld) -> void:
    interaction_world = world

func _create_input_actions() -> void:
    _add_key_action("move_forward", KEY_W)
    _add_key_action("move_backward", KEY_S)
    _add_key_action("move_left", KEY_A)
    _add_key_action("move_right", KEY_D)
    _add_key_action("jump", KEY_SPACE)
    _add_key_action("sprint", KEY_SHIFT)

func _add_key_action(action_name: String, key: Key) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
    for existing in InputMap.action_get_events(action_name):
        if existing is InputEventKey and existing.physical_keycode == key:
            return
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action_name, event)

func _build_body() -> void:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.85
    var collider := CollisionShape3D.new()
    collider.shape = capsule
    collider.position.y = 0.93
    add_child(collider)
    camera_pivot = Node3D.new()
    camera_pivot.position.y = 1.62
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 78.0
    camera.near = 0.05
    camera_pivot.add_child(camera)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var hud := Label.new()
    hud.position = Vector2(18.0, 14.0)
    hud.add_theme_font_size_override("font_size", 17)
    hud.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
    hud.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
    hud.add_theme_constant_override("shadow_offset_x", 2)
    hud.add_theme_constant_override("shadow_offset_y", 2)
    hud.text = "GRIMHOLT – VOXEL TESTWELT\nWASD: Bewegen | SHIFT: Sprint | LEERTASTE: Springen\nMaus: Umsehen | ESC: Maus freigeben | Klick: Maus fangen\nLinksklick: Block abbauen | Rechtsklick: Erde platzieren"
    layer.add_child(hud)
    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-7.0, -15.0)
    crosshair.add_theme_font_size_override("font_size", 28)
    layer.add_child(crosshair)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed:
        if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        elif event.button_index == MOUSE_BUTTON_LEFT:
            _interact_with_world(false)
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            _interact_with_world(true)

func _interact_with_world(place_block: bool) -> void:
    if interaction_world == null or camera == null:
        return
    var origin := camera.global_position
    var endpoint := origin - camera.global_transform.basis.z * INTERACTION_DISTANCE
    var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
    query.exclude = [get_rid()]
    query.collision_mask = 1
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return
    var normal: Vector3 = hit.normal
    var target_position: Vector3 = hit.position + normal * 0.01 if place_block else hit.position - normal * 0.01
    var voxel_position := Vector3i(target_position.floor())
    if place_block:
        interaction_world.set_voxel(voxel_position, Blocks.DIRT)
    else:
        interaction_world.set_voxel(voxel_position, Blocks.AIR)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = JUMP_VELOCITY
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var move_direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
    var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
    if move_direction.length() > 0.01:
        velocity.x = move_direction.x * speed
        velocity.z = move_direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 5.0 * delta)
    move_and_slide()
