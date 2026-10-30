extends CharacterBody3D

const WALK_SPEED := 8.0
const CROUCH_SPEED := 4.0
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1
const STAND_EYE_HEIGHT := 1.55
const CROUCH_EYE_HEIGHT := 0.98
const JUMP_VELOCITY := 6.0
const MOUSE_SENSITIVITY := 0.0022
const MAGAZINE_SIZE := 30
const RESERVE_START := 120
const FIRE_INTERVAL := 0.12
const DAMAGE_RANGE := 120.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var body_visual: MeshInstance3D = $BodyVisual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var fire_cooldown := 0.0
var network_timer := 0.0
var health := 100
var ammo := MAGAZINE_SIZE
var reserve_ammo := RESERVE_START
var reload_time := 0.0
var is_crouched := false

func _ready() -> void:
	collision_shape.shape = collision_shape.shape.duplicate()
	add_to_group("combatants")
	set_meta("actor_id", get_multiplayer_authority())
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.36
	capsule.height = 1.75
	body_visual.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.from_hsv(float(get_multiplayer_authority() % 8) / 8.0, 0.72, 0.95)
	body_visual.material_override = material
	camera.current = is_multiplayer_authority()
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-85), deg_to_rad(85))
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_fire()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_reload()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or health <= 0:
		return
	if reload_time > 0.0:
		reload_time = maxf(0.0, reload_time - delta)
		if reload_time == 0.0:
			var amount := mini(MAGAZINE_SIZE - ammo, reserve_ammo)
			ammo += amount
			reserve_ammo -= amount
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	_update_crouch()
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	var move_speed := CROUCH_SPEED if is_crouched else WALK_SPEED
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	move_and_slide()
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	network_timer += delta
	if network_timer >= 0.05 and multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		network_timer = 0.0
		get_parent()._submit_transform.rpc_id(1, global_position, rotation.y, head.rotation.x)

func _update_crouch() -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch == is_crouched:
		return
	if not wants_crouch:
		var query := PhysicsShapeQueryParameters3D.new()
		var standing_shape := CapsuleShape3D.new()
		standing_shape.radius = 0.38
		standing_shape.height = STAND_HEIGHT
		query.shape = standing_shape
		query.transform = global_transform.translated(Vector3.UP * (STAND_HEIGHT * 0.5))
		query.exclude = [get_rid()]
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return
	is_crouched = wants_crouch
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = CROUCH_HEIGHT if is_crouched else STAND_HEIGHT
	collision_shape.position.y = capsule.height * 0.5
	head.position.y = CROUCH_EYE_HEIGHT if is_crouched else STAND_EYE_HEIGHT
	var body_capsule := body_visual.mesh as CapsuleMesh
	body_capsule.height = capsule.height
	body_visual.position.y = capsule.height * 0.5

func _fire() -> void:
	if fire_cooldown > 0.0 or ammo <= 0 or reload_time > 0.0:
		if ammo <= 0:
			_reload()
		return
	fire_cooldown = FIRE_INTERVAL
	ammo -= 1
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	if multiplayer.is_server():
		get_parent()._process_shot(get_multiplayer_authority(), origin, direction)
	else:
		get_parent()._request_shot.rpc_id(1, origin, direction)

func _reload() -> void:
	if reload_time <= 0.0 and ammo < MAGAZINE_SIZE and reserve_ammo > 0:
		reload_time = 1.65
