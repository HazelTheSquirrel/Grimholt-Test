extends CharacterBody3D

const WALK_SPEED := 8.0
const JUMP_VELOCITY := 6.0
const MOUSE_SENSITIVITY := 0.0022
const FIRE_INTERVAL := 0.22

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var body_visual: MeshInstance3D = $BodyVisual
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var fire_cooldown := 0.0
var network_timer := 0.0

func _ready() -> void:
	add_to_group("players")
	set_meta("peer_id", get_multiplayer_authority())
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

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP_VELOCITY
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	move_and_slide()
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	network_timer += delta
	if network_timer >= 0.05 and multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		network_timer = 0.0
		get_parent()._submit_transform.rpc_id(1, global_position, rotation.y, head.rotation.x)

func _fire() -> void:
	if fire_cooldown > 0.0 or multiplayer.multiplayer_peer == null:
		return
	fire_cooldown = FIRE_INTERVAL
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	if multiplayer.is_server():
		get_parent()._request_shot_local(get_multiplayer_authority(), origin, direction)
	else:
		get_parent()._request_shot.rpc_id(1, origin, direction)
