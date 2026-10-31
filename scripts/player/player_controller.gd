extends CharacterBody3D

signal vitals_changed(health: float, shields: float)
signal player_died

@export var walk_speed: float = 8.0
@export var sprint_speed: float = 11.5
@export var jump_velocity: float = 8.5
@export var mouse_sensitivity: float = 0.0018
@export var max_health: float = 100.0
@export var max_shields: float = 100.0

@onready var head: Node3D = $Head

var health: float = 100.0
var shields: float = 100.0
var shield_delay: float = 0.0
var gravity: float = 24.0
var dead: bool = false
var mouse_capture_requested: bool = false

func _ready() -> void:
	health = max_health
	shields = max_shields
	# Start visible: some desktop/window managers discard a capture requested
	# before the game window receives focus. The first click captures reliably.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	vitals_changed.emit(health, shields)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not dead:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			mouse_capture_requested = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("pause_game"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif mouse_capture_requested and not get_tree().paused and not dead:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not dead and not get_tree().paused:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if dead or get_tree().paused:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	if direction.length() > 0.0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 8.0 * delta)

	move_and_slide()

	if shield_delay > 0.0:
		shield_delay = maxf(0.0, shield_delay - delta)
	else:
		var old_shields := shields
		shields = minf(max_shields, shields + 22.0 * delta)
		if not is_equal_approx(old_shields, shields):
			vitals_changed.emit(health, shields)

func receive_damage(amount: float) -> void:
	if dead:
		return
	shield_delay = 3.0
	var absorbed := minf(shields, amount)
	shields -= absorbed
	health = maxf(0.0, health - (amount - absorbed))
	vitals_changed.emit(health, shields)

	if health <= 0.0:
		dead = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player_died.emit()
		await get_tree().create_timer(2.5).timeout
		if not is_inside_tree():
			return
		health = max_health
		shields = max_shields
		global_position = Vector3(0.0, 0.2, 12.0)
		velocity = Vector3.ZERO
		dead = false
		vitals_changed.emit(health, shields)
