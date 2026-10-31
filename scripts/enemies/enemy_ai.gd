extends CharacterBody3D

signal defeated

@export var move_speed: float = 3.8
@export var max_health: float = 90.0
@export var attack_range: float = 2.1
@export var attack_damage: float = 12.0

var health: float = 90.0
var target: Node3D
var attack_cooldown: float = 0.0
var gravity: float = 24.0
var active: bool = true

func _ready() -> void:
	health = max_health
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.34, 0.48)
	material.metallic = 0.72
	material.roughness = 0.32
	($Body as MeshInstance3D).material_override = material

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target) or get_tree().paused:
		return

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()

	if distance > attack_range:
		var direction := _steer_around_cover(offset.normalized())
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		if direction.length_squared() > 0.01:
			look_at(global_position + Vector3(direction.x, 0.0, direction.z), Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
		if attack_cooldown <= 0.0 and target.has_method("receive_damage"):
			target.receive_damage(attack_damage)
			attack_cooldown = 1.1

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _steer_around_cover(desired: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var start := global_position + Vector3.UP * 0.9
	var forward_query := PhysicsRayQueryParameters3D.create(start, start + desired * 2.2)
	forward_query.exclude = [get_rid()]
	if not space.intersect_ray(forward_query).is_empty():
		var right := Vector3(-desired.z, 0.0, desired.x)
		for side in [1.0, -1.0]:
			var candidate := (desired + right * side * 0.9).normalized()
			var side_query := PhysicsRayQueryParameters3D.create(start, start + candidate * 2.0)
			side_query.exclude = [get_rid()]
			if space.intersect_ray(side_query).is_empty():
				return candidate
		return Vector3.ZERO
	return desired

func take_damage(amount: float) -> void:
	if not active:
		return
	health -= amount
	if health <= 0.0:
		active = false
		defeated.emit()
		queue_free()
