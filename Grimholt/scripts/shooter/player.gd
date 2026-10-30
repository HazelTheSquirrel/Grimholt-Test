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
		_build_weapon_viewmodel()

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

func _build_weapon_viewmodel() -> void:
	var weapon := Node3D.new()
	weapon.name = "RifleViewmodel"
	weapon.position = Vector3(0.24, -0.20, -0.42)
	camera.add_child(weapon)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.075, 0.09, 0.105)
	dark.metallic = 0.62
	dark.roughness = 0.38
	var polymer := StandardMaterial3D.new()
	polymer.albedo_color = Color(0.16, 0.19, 0.21)
	polymer.roughness = 0.72
	_add_weapon_box(weapon, "Receiver", Vector3(0.0, 0.0, 0.0), Vector3(0.12, 0.13, 0.38), dark)
	_add_weapon_box(weapon, "Barrel", Vector3(0.0, 0.015, -0.29), Vector3(0.055, 0.055, 0.30), dark)
	_add_weapon_box(weapon, "Muzzle", Vector3(0.0, 0.015, -0.45), Vector3(0.075, 0.075, 0.055), polymer)
	_add_weapon_box(weapon, "Stock", Vector3(0.0, 0.015, 0.27), Vector3(0.105, 0.10, 0.22), polymer)
	_add_weapon_box(weapon, "Magazine", Vector3(0.0, -0.12, 0.045), Vector3(0.085, 0.19, 0.12), polymer)
	_add_weapon_box(weapon, "Grip", Vector3(0.0, -0.12, 0.16), Vector3(0.075, 0.16, 0.085), dark)
	_add_weapon_box(weapon, "Sight", Vector3(0.0, 0.105, -0.02), Vector3(0.055, 0.065, 0.12), polymer)

func _add_weapon_box(parent: Node3D, part_name: String, part_position: Vector3, dimensions: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.material_override = material
	part.position = part_position
	parent.add_child(part)

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
	if fire_cooldown > 0.0 or reload_time > 0.0:
		return
	fire_cooldown = FIRE_INTERVAL
	get_parent().request_fire(get_multiplayer_authority())

func _reload() -> void:
	if reload_time <= 0.0 and ammo < MAGAZINE_SIZE and reserve_ammo > 0:
		get_parent().request_reload(get_multiplayer_authority())
