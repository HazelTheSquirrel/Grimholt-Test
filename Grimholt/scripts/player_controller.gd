extends CharacterBody3D
class_name GrimholtPlayer

const BODY_HEIGHT := 1.70
const BODY_RADIUS := 0.30
const WALK_SPEED := 4.8
const SPRINT_SPEED := 7.2
const JUMP_VELOCITY := 5.0
const MOUSE_SENSITIVITY := 0.002
const INTERACTION_DISTANCE := 5.0
const CAMERA_MIN_DISTANCE := 0.08
const CAMERA_MAX_DISTANCE := 8.5
const CAMERA_ZOOM_STEP := 0.7
const FIRST_PERSON_THRESHOLD := 0.22

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var body_visual: MeshInstance3D = $BodyVisual
@onready var inventory: GrimholtInventory = $Inventory
@onready var status_label: Label = $HUD/StatusLabel

var professions := GrimholtProfessionSystem.new()
var building_system: GrimholtBuildingSystem
var selected_piece := "foundation"
var build_mode := false
var interaction_feedback := ""
var feedback_timer := 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_distance := 5.2
var effective_camera_distance := 5.2

func _ready() -> void:
    _configure_input_actions()
    _configure_body_visual()
    _configure_hud()
    floor_snap_length = 0.35
    floor_max_angle = deg_to_rad(50.0)
    camera_pivot.rotation.x = deg_to_rad(-8.0)
    _apply_camera_distance()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _configure_body_visual() -> void:
    var fabric_noise := FastNoiseLite.new()
    fabric_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    fabric_noise.frequency = 0.12
    var fabric_texture := NoiseTexture2D.new()
    fabric_texture.width = 128
    fabric_texture.height = 128
    fabric_texture.noise = fabric_noise
    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = Color(0.25, 0.30, 0.36)
    body_material.albedo_texture = fabric_texture
    body_material.uv1_triplanar = true
    body_material.uv1_scale = Vector3(2.0, 2.0, 2.0)
    body_material.roughness = 0.92
    body_visual.material_override = body_material

func _configure_hud() -> void:
    status_label.add_theme_font_size_override("font_size", 16)
    status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
    status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
    status_label.add_theme_constant_override("shadow_offset_x", 2)
    status_label.add_theme_constant_override("shadow_offset_y", 2)

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

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-80), deg_to_rad(65))
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        elif event.keycode == KEY_E:
            _interact()
        elif event.keycode == KEY_B:
            build_mode = not build_mode
            _set_feedback("Baumodus aktiviert" if build_mode else "Baumodus beendet")
        elif event.keycode == KEY_1:
            selected_piece = "foundation"
        elif event.keycode == KEY_2:
            selected_piece = "wall"
        elif event.keycode == KEY_3:
            selected_piece = "roof"
        elif event.keycode == KEY_C:
            _craft("wooden_plank")
        elif event.keycode == KEY_F5:
            get_parent().call("_save_game")
        elif event.keycode == KEY_F9:
            get_parent().call("_load_game")
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_distance = maxf(CAMERA_MIN_DISTANCE, camera_distance - CAMERA_ZOOM_STEP)
            _apply_camera_distance()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_distance = minf(CAMERA_MAX_DISTANCE, camera_distance + CAMERA_ZOOM_STEP)
            _apply_camera_distance()
        elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
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
    _apply_camera_distance()
    if feedback_timer > 0.0:
        feedback_timer = maxf(0.0, feedback_timer - delta)
        if feedback_timer == 0.0:
            interaction_feedback = ""
    _update_hud()


func _apply_camera_distance() -> void:
    if camera == null or camera_pivot == null:
        return
    var safe_distance := camera_distance
    if camera_distance > CAMERA_MIN_DISTANCE + 0.01 and is_inside_tree():
        var pivot_position := camera_pivot.global_position
        var camera_direction := camera_pivot.global_transform.basis.z.normalized()
        var desired_position := pivot_position + camera_direction * camera_distance
        var query := PhysicsRayQueryParameters3D.create(pivot_position, desired_position)
        query.exclude = [get_rid()]
        query.collision_mask = 1
        var obstruction := get_world_3d().direct_space_state.intersect_ray(query)
        if not obstruction.is_empty():
            safe_distance = maxf(CAMERA_MIN_DISTANCE, pivot_position.distance_to(Vector3(obstruction.position)) - 0.18)
    effective_camera_distance = safe_distance
    var zoom_ratio := inverse_lerp(CAMERA_MIN_DISTANCE, CAMERA_MAX_DISTANCE, camera_distance)
    camera.position = Vector3(0.0, lerpf(0.12, 0.35, zoom_ratio), safe_distance)
    body_visual.visible = camera_distance > FIRST_PERSON_THRESHOLD

func _interact() -> bool:
    var hit := _raycast()
    if hit.is_empty():
        _set_feedback("Kein Sammelobjekt im Fadenkreuz – näher herangehen und direkt ansehen.")
        return false
    var target := hit.get("collider") as Object
    if target == null or not target.has_method("harvest"):
        _set_feedback("Das ist keine sammelbare Ressource.")
        return false
    var resource_name := String(target.get("display_name"))
    if bool(target.call("harvest", inventory)):
        _set_feedback("%s geerntet. %s" % [resource_name, inventory.get_summary()])
        return true
    _set_feedback("Ernte nicht möglich – möglicherweise ist dein Inventar voll.")
    return false

func _set_feedback(message: String) -> void:
    interaction_feedback = message
    feedback_timer = 4.0

func _place_building_piece() -> void:
    if building_system == null:
        _set_feedback("Bausystem ist nicht verfügbar.")
        return
    var hit := _raycast()
    if hit.is_empty():
        _set_feedback("Kein gültiger Baupunkt im Fadenkreuz.")
        return
    if building_system.place_piece(selected_piece, hit.position, inventory):
        _set_feedback("%s platziert." % String(GrimholtBuildingSystem.PIECES[selected_piece]["name"]))
    else:
        _set_feedback("Bauen nicht möglich – fehlen Materialien oder ist das Bauteil ungültig?")

func _raycast() -> Dictionary:
    var origin := camera.global_position
    var camera_to_player := origin.distance_to(global_position)
    var ray_length := camera_to_player + INTERACTION_DISTANCE + 0.5
    var endpoint := origin - camera.global_transform.basis.z * ray_length
    var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
    query.exclude = [get_rid()]
    query.collision_mask = 1
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return {}
    if Vector3(hit.position).distance_to(global_position) > INTERACTION_DISTANCE + 0.5:
        return {}
    return hit

func _craft(recipe_id: String) -> void:
    if GrimholtCraftingSystem.craft(recipe_id, inventory, professions):
        _set_feedback("Herstellung abgeschlossen.")
    else:
        _set_feedback("Herstellung nicht möglich – prüfe Zutaten und freien Inventarplatz.")

func _update_hud() -> void:
    if inventory == null:
        return
    var mode_text := "BAUMODUS: %s (1 Fundament / 2 Wand / 3 Dach)" % selected_piece if build_mode else "E: Ernten | B: Bauen | C: Planken | F5: Speichern | F9: Laden"
    var feedback_text := interaction_feedback
    if feedback_text.is_empty():
        var target_hit := _raycast()
        if not target_hit.is_empty():
            var target := target_hit.get("collider") as Object
            if target != null and target.has_method("harvest"):
                feedback_text = "E: %s ernten" % String(target.get("display_name"))
        if feedback_text.is_empty():
            feedback_text = "Richte das Fadenkreuz auf einen Baum, Erz oder eine Pflanze."
    status_label.text = "GRIMHOLT – FANTASY SANDBOX\nWASD: Bewegen | SHIFT: Sprint | LEERTASTE: Springen | Maus: Umschauen | Mausrad: Ego-/Third-Person-Zoom | ESC: Maus lösen\n%s\n%s\n%s" % [mode_text, feedback_text, inventory.get_summary()]
