extends CharacterBody3D

const ACTOR_VISUAL := preload("res://scripts/shooter/actor_visual.gd")

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
const DAMAGE_RANGE := 120.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var body_visual: MeshInstance3D = $BodyVisual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var fire_cooldown := 0.0
var network_timer := 0.0
var jump_input_buffered := false
var remote_move_input := Vector2.ZERO
var remote_jump_requested := false
var remote_crouch_requested := false
var remote_yaw := 0.0
var remote_pitch := 0.0
var remote_input_received_msec := 0
var health := 100
var ammo := MAGAZINE_SIZE
var reserve_ammo := RESERVE_START
var current_weapon := "carbine"
var weapon_viewmodel: Node3D
var carbine_model: Node3D
var scatter_model: Node3D
var reload_time := 0.0
var is_crouched := false
var fire_held := false
var fire_audio: AudioStreamPlayer
var reload_audio: AudioStreamPlayer
var base_camera_position := Vector3.ZERO
var base_viewmodel_position := Vector3(0.24, -0.20, -0.42)
var bob_phase := 0.0
var viewmodel_recoil := 0.0

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
	ACTOR_VISUAL.build(body_visual, material.albedo_color, Color(0.88, 0.72, 0.38))
	camera.current = is_multiplayer_authority()
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		base_camera_position = camera.position
		_build_weapon_viewmodel()
		_build_audio_feedback()

func _process(delta: float) -> void:
	if not is_multiplayer_authority() or camera == null or weapon_viewmodel == null:
		return
	_update_first_person_feedback(delta)

func _update_first_person_feedback(delta: float) -> void:
	var is_playing := bool(get_parent().get("round_active")) and not bool(get_parent().get("is_local_paused"))
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	var moving := is_playing and is_on_floor() and planar_speed > 0.2
	if moving:
		bob_phase += delta * clampf(planar_speed * 1.35, 0.0, 12.0)
	var bob_strength := clampf(planar_speed / WALK_SPEED, 0.0, 1.0) if moving else 0.0
	var camera_bob := Vector3(0.0, sin(bob_phase * 2.0) * 0.025 * bob_strength, 0.0)
	var weapon_bob := Vector3(sin(bob_phase) * 0.009 * bob_strength, absf(cos(bob_phase)) * 0.012 * bob_strength, 0.0)
	viewmodel_recoil = move_toward(viewmodel_recoil, 0.0, delta * 0.42)
	var smoothing := 1.0 - exp(-delta * 14.0)
	camera.position = camera.position.lerp(base_camera_position + camera_bob, smoothing)
	weapon_viewmodel.position = weapon_viewmodel.position.lerp(base_viewmodel_position + weapon_bob + Vector3(0.0, viewmodel_recoil * 0.45, viewmodel_recoil), smoothing)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if bool(get_parent().get("is_local_paused")):
		fire_held = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		fire_held = event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-85), deg_to_rad(85))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			fire_held = true
			_fire()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_reload()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_1:
		get_parent().request_weapon_switch(get_multiplayer_authority(), "carbine")
	elif event is InputEventKey and event.pressed and event.keycode == KEY_2:
		get_parent().request_weapon_switch(get_multiplayer_authority(), "scatter")

func _physics_process(delta: float) -> void:
	var local_control := is_multiplayer_authority()
	var server_control := multiplayer.is_server()
	if (not local_control and not server_control) or health <= 0 or not bool(get_parent().get("round_active")):
		return

	var input_vector := Vector2.ZERO
	var jump_requested := false
	var wants_crouch := false
	if local_control:
		if not bool(get_parent().get("is_local_paused")):
			input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
			jump_requested = Input.is_action_just_pressed("jump")
			if jump_requested:
				jump_input_buffered = true
			wants_crouch = Input.is_action_pressed("crouch")
			if not server_control:
				network_timer += delta
				if network_timer >= 0.05 and multiplayer.multiplayer_peer != null:
					network_timer = 0.0
					get_parent()._submit_input.rpc_id(1, input_vector, jump_input_buffered, wants_crouch, rotation.y, head.rotation.x)
					jump_input_buffered = false
	else:
		var input_is_fresh := Time.get_ticks_msec() - remote_input_received_msec <= 250
		if input_is_fresh:
			input_vector = remote_move_input
			jump_requested = remote_jump_requested
			wants_crouch = remote_crouch_requested
		rotation.y = remote_yaw
		head.rotation.x = remote_pitch
		remote_jump_requested = false

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif jump_requested:
		velocity.y = JUMP_VELOCITY
	_update_crouch(wants_crouch)
	var direction := (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	var move_speed := CROUCH_SPEED if is_crouched else WALK_SPEED
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	move_and_slide()
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if local_control and fire_held and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_fire()

func _build_audio_feedback() -> void:
	fire_audio = AudioStreamPlayer.new()
	fire_audio.name = "FireAudio"
	fire_audio.volume_db = -8.0
	add_child(fire_audio)
	fire_audio.stream = _make_tone(115.0, 0.075, 0.34, true)

	reload_audio = AudioStreamPlayer.new()
	reload_audio.name = "ReloadAudio"
	reload_audio.volume_db = -10.0
	add_child(reload_audio)
	reload_audio.stream = _make_tone(520.0, 0.11, 0.18, false)

func _make_tone(frequency: float, duration: float, amplitude: float, noisy: bool) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	var sample_count := int(SAMPLE_RATE * duration)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var envelope := pow(1.0 - float(i) / sample_count, 2.2)
		var wave := sin(TAU * frequency * t)
		if noisy:
			wave = wave * 0.72 + randf_range(-1.0, 1.0) * 0.28
		var value := int(clampf(wave * envelope * amplitude, -1.0, 1.0) * 32767.0)
		samples.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream

func _build_weapon_viewmodel() -> void:
	weapon_viewmodel = Node3D.new()
	weapon_viewmodel.name = "WeaponViewmodel"
	weapon_viewmodel.position = base_viewmodel_position
	camera.add_child(weapon_viewmodel)

	carbine_model = Node3D.new()
	carbine_model.name = "Carbine"
	weapon_viewmodel.add_child(carbine_model)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.075, 0.09, 0.105)
	dark.metallic = 0.62
	dark.roughness = 0.38
	var polymer := StandardMaterial3D.new()
	polymer.albedo_color = Color(0.16, 0.19, 0.21)
	polymer.roughness = 0.72
	_add_weapon_box(carbine_model, "Receiver", Vector3(0.0, 0.0, 0.0), Vector3(0.12, 0.13, 0.38), dark)
	_add_weapon_box(carbine_model, "Barrel", Vector3(0.0, 0.015, -0.29), Vector3(0.055, 0.055, 0.30), dark)
	_add_weapon_box(carbine_model, "Muzzle", Vector3(0.0, 0.015, -0.45), Vector3(0.075, 0.075, 0.055), polymer)
	_add_weapon_box(carbine_model, "Stock", Vector3(0.0, 0.015, 0.27), Vector3(0.105, 0.10, 0.22), polymer)
	_add_weapon_box(carbine_model, "Magazine", Vector3(0.0, -0.12, 0.045), Vector3(0.085, 0.19, 0.12), polymer)
	_add_weapon_box(carbine_model, "Grip", Vector3(0.0, -0.12, 0.16), Vector3(0.075, 0.16, 0.085), dark)
	_add_weapon_box(carbine_model, "Sight", Vector3(0.0, 0.105, -0.02), Vector3(0.055, 0.065, 0.12), polymer)

	scatter_model = Node3D.new()
	scatter_model.name = "ArcScatter"
	weapon_viewmodel.add_child(scatter_model)
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color(0.13, 0.18, 0.20)
	shell.metallic = 0.72
	shell.roughness = 0.3
	var coil := StandardMaterial3D.new()
	coil.albedo_color = Color(0.18, 0.72, 0.68)
	coil.emission_enabled = true
	coil.emission = Color(0.08, 0.42, 0.38)
	coil.emission_energy_multiplier = 0.8
	_add_weapon_box(scatter_model, "ScatterReceiver", Vector3(0.0, 0.0, 0.0), Vector3(0.19, 0.16, 0.34), shell)
	_add_weapon_box(scatter_model, "TwinEmitterLeft", Vector3(-0.065, 0.025, -0.29), Vector3(0.065, 0.065, 0.32), coil)
	_add_weapon_box(scatter_model, "TwinEmitterRight", Vector3(0.065, 0.025, -0.29), Vector3(0.065, 0.065, 0.32), coil)
	_add_weapon_box(scatter_model, "PowerCell", Vector3(0.0, -0.13, 0.055), Vector3(0.13, 0.18, 0.13), shell)
	_add_weapon_box(scatter_model, "RearGrip", Vector3(0.0, -0.12, 0.17), Vector3(0.09, 0.16, 0.09), shell)
	_add_weapon_box(scatter_model, "TopRail", Vector3(0.0, 0.11, -0.02), Vector3(0.13, 0.035, 0.22), coil)
	set_weapon_visual(current_weapon)

func set_weapon_visual(weapon_id: String) -> void:
	current_weapon = weapon_id
	if carbine_model != null:
		carbine_model.visible = weapon_id == "carbine"
	if scatter_model != null:
		scatter_model.visible = weapon_id == "scatter"
	if fire_audio != null:
		fire_audio.stream = _make_tone(115.0, 0.075, 0.34, true) if weapon_id == "carbine" else _make_tone(72.0, 0.14, 0.42, true)

func _add_weapon_box(parent: Node3D, part_name: String, part_position: Vector3, dimensions: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.material_override = material
	part.position = part_position
	parent.add_child(part)

func _update_crouch(wants_crouch: bool) -> void:
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
	var spec: Dictionary = get_parent()._weapon_spec(current_weapon)
	fire_cooldown = float(spec["fire_interval"])
	if fire_audio != null:
		fire_audio.play()
	viewmodel_recoil = minf(viewmodel_recoil + (0.095 if current_weapon == "scatter" else 0.055), 0.16)
	get_parent().request_fire(get_multiplayer_authority())

func _reload() -> void:
	var spec: Dictionary = get_parent()._weapon_spec(current_weapon)
	if reload_time <= 0.0 and ammo < int(spec["magazine"]) and reserve_ammo > 0:
		if reload_audio != null:
			reload_audio.play()
		get_parent().request_reload(get_multiplayer_authority())
