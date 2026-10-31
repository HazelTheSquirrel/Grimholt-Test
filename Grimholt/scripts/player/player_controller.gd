extends CharacterBody3D
class_name PlayerController

signal health_changed(value: int)
signal ammo_changed(current: int, reserve: int)
signal score_changed(value: int)

@export var move_speed: float = 8.0
@export var acceleration: float = 24.0
@export var jump_velocity: float = 5.2
@export var mouse_sensitivity: float = 0.0022
@export var max_health: int = 100

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon: WeaponController = $Head/Camera3D/PulseCarbine

var health: int = 100
var score: int = 0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
    health = max_health
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    weapon.ammo_changed.connect(_on_ammo_changed)
    ammo_changed.emit(weapon.magazine_ammo, weapon.reserve_ammo)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        head.rotate_x(-event.relative.y * mouse_sensitivity)
        head.rotation.x = clampf(head.rotation.x, deg_to_rad(-88), deg_to_rad(88))
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if event.is_action_pressed("reload"):
        weapon.reload()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
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

func _fire() -> void:
    if not weapon.try_fire():
        return
    var origin := camera.global_position
    var direction := -camera.global_transform.basis.z
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * weapon.max_range)
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var target: Object = hit.collider
        if target.has_method("take_damage"):
            target.take_damage(weapon.damage, self)

func take_damage(amount: int, _attacker: Node = null) -> void:
    health = maxi(0, health - amount)
    health_changed.emit(health)
    if health == 0:
        global_position = Vector3(0, 2, 26)
        health = max_health
        health_changed.emit(health)

func add_score(points: int) -> void:
    score += points
    score_changed.emit(score)

func _on_ammo_changed(current: int, reserve: int) -> void:
    ammo_changed.emit(current, reserve)
