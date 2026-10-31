extends CharacterBody3D
class_name ArenaBot

signal eliminated(bot: ArenaBot, killer: Node)

@export var max_health: int = 100
@export var move_speed: float = 4.2
@export var attack_range: float = 24.0
@export var damage: int = 8
@export var fire_interval: float = 0.8

var health: int = 100
var target: Node3D
var _fire_cooldown: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

func set_target(value: Node3D) -> void:
	target = value

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var offset: Vector3 = target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > 0.01:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))
	if distance > 10.0:
		var direction := _steer_around_obstacles(offset.normalized())
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 2.0)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 2.0)
	move_and_slide()
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if distance <= attack_range and _fire_cooldown <= 0.0 and _has_line_of_sight():
		_fire_cooldown = fire_interval
		if target.has_method("take_damage"):
			target.take_damage(damage, self)

func _steer_around_obstacles(desired: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var origin := global_position + Vector3.UP * 0.9
	var directions := [desired, (desired + global_transform.basis.x * 0.75).normalized(), (desired - global_transform.basis.x * 0.75).normalized()]
	for direction in directions:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 2.4)
		query.exclude = [get_rid()]
		if space.intersect_ray(query).is_empty():
			return direction
	return Vector3.ZERO

func _has_line_of_sight() -> bool:
	if not is_instance_valid(target):
		return false
	var origin := global_position + Vector3.UP * 1.45
	var destination := target.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == target

func take_damage(amount: int, attacker: Node = null) -> void:
	if amount <= 0 or health <= 0:
		return
	health = maxi(0, health - amount)
	if health == 0:
		eliminated.emit(self, attacker)
		queue_free()
