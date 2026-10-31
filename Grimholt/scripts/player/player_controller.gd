extends CharacterBody3D
class_name PlayerController

signal health_changed(value: int)
signal ammo_changed(current: int, reserve: int)
signal score_changed(value: int)
signal pause_requested
signal hit_confirmed
signal weapon_changed(display_name: String)

@export var move_speed: float = 8.0
@export var acceleration: float = 24.0
@export var jump_velocity: float = 5.2
@export var mouse_sensitivity: float = 0.0022
@export var max_health: int = 100

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var carbine: WeaponController = $Head/Camera3D/PulseCarbine
@onready var arc_scatter: WeaponController = $Head/Camera3D/ArcScatter

var weapons: Array[WeaponController] = []
var weapon_index: int = 0
var weapon: WeaponController
var health: int = 100
var score: int = 0
var _is_paused: bool = false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	health = max_health
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapons = [carbine, arc_scatter]
	weapon = carbine
	arc_scatter.visible = false
	for weapon_node in weapons:
		weapon_node.ammo_changed.connect(_on_ammo_changed)
	ammo_changed.emit(weapon.magazine_ammo, weapon.reserve_ammo)
	weapon_changed.emit(weapon.display_name)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if _is_paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-88), deg_to_rad(88))
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("reload"):
		weapon.reload()
	if event.is_action_pressed("switch_weapon"):
		_switch_weapon()

func set_local_paused(value: bool) -> void:
	_is_paused = value
	if value:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if _is_paused:
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target := direction * move_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	move_and_slide()
	if Input.is_action_pressed("fire") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_fire()

func _switch_weapon() -> void:
	if weapons.size() < 2:
		return
	weapon_index = (weapon_index + 1) % weapons.size()
	weapon = weapons[weapon_index]
	for index in range(weapons.size()):
		weapons[index].visible = index == weapon_index
	ammo_changed.emit(weapon.magazine_ammo, weapon.reserve_ammo)
	weapon_changed.emit(weapon.display_name)

func _fire() -> void:
	if not weapon.try_fire():
		return
	var origin := camera.global_position
	var basis := camera.global_transform.basis
	for pellet_index in range(weapon.pellet_count):
		var direction := (-basis.z + basis.x * randf_range(-weapon.spread, weapon.spread) + basis.y * randf_range(-weapon.spread, weapon.spread)).normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * weapon.max_range)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var target: Object = hit.collider
			if target.has_method("take_damage"):
				target.take_damage(weapon.damage, self)
				hit_confirmed.emit()

func take_damage(amount: int, _attacker: Node = null) -> void:
	if amount <= 0 or health <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health)
	if health == 0:
		health = max_health
		global_position = Vector3(0, 1.1, 25)
		velocity = Vector3.ZERO
		health_changed.emit(health)

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func _on_ammo_changed(current: int, reserve: int) -> void:
	ammo_changed.emit(current, reserve)
