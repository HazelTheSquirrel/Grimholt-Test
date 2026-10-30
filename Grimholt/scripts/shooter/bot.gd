extends CharacterBody3D

const ACTOR_VISUAL := preload("res://scripts/shooter/actor_visual.gd")

const SPEED := 5.2
const DETECT_RANGE := 42.0
const FIRE_RANGE := 28.0
const PREFERRED_RANGE := 15.0
const MIN_COMFORT_RANGE := 9.0
const MAX_COMFORT_RANGE := 19.0
const FIRE_INTERVAL := 1.65
const STRAFE_SWITCH_INTERVAL := 1.8
const OBSTACLE_PROBE_DISTANCE := 2.8
const GRAVITY := 20.0

@onready var head: Node3D = $Head
@onready var visual: MeshInstance3D = $BodyVisual
var bot_id := 0
var game: Node
var health := 100
var fire_timer := 1.0
var think_timer := 0.0
var strafe_timer := 0.0
var strafe_direction := 1.0
var target: Node3D

func configure(id: int, controller: Node) -> void:
	bot_id = id
	game = controller
	set_meta("actor_id", id)

func _ready() -> void:
	add_to_group("combatants")
	add_to_group("bots")
	set_meta("actor_id", bot_id)
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.37
	capsule.height = 1.8
	visual.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.78, 0.36, 0.18)
	visual.material_override = material
	ACTOR_VISUAL.build(visual, material.albedo_color, Color(0.94, 0.67, 0.25))

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or not bool(game.get("round_active")) or health <= 0:
		return
	fire_timer = maxf(0.0, fire_timer - delta)
	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_timer = STRAFE_SWITCH_INTERVAL + randf_range(-0.35, 0.35)
		strafe_direction = -strafe_direction if randf() < 0.72 else (1.0 if randf() < 0.5 else -1.0)
	think_timer -= delta
	if think_timer <= 0.0 or not is_instance_valid(target):
		think_timer = 0.25
		target = _find_target()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if target and is_instance_valid(target):
		var offset := target.global_position - global_position
		var distance := Vector2(offset.x, offset.z).length()
		var desired_direction := _combat_movement_direction(offset, strafe_direction)
		var movement_direction := _steer_around_obstacles(desired_direction)
		velocity.x = movement_direction.x * SPEED
		velocity.z = movement_direction.z * SPEED
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
		move_and_slide()
		if distance <= FIRE_RANGE and fire_timer <= 0.0 and _has_line_of_sight():
			_shoot_at_target()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		move_and_slide()

# Keep a readable engagement distance: close the gap when far away, create
# space when rushed, and strafe instead of standing still at mid range.
func _combat_movement_direction(offset: Vector3, side: float) -> Vector3:
	var flat_offset := Vector3(offset.x, 0.0, offset.z)
	var distance := flat_offset.length()
	if distance < 0.001:
		return Vector3.ZERO
	var toward_target := flat_offset / distance
	if distance > MAX_COMFORT_RANGE:
		return toward_target
	if distance < MIN_COMFORT_RANGE:
		return -toward_target
	var lateral := Vector3(-toward_target.z, 0.0, toward_target.x) * signf(side)
	var range_correction := toward_target * clampf((distance - PREFERRED_RANGE) / 12.0, -0.25, 0.25)
	return (lateral + range_correction).normalized()

# A short forward probe prevents the simple steering controller from pushing
# directly into walls and arena cover. It is deliberately lightweight rather
# than pretending to be full navigation-mesh pathfinding.
func _steer_around_obstacles(desired: Vector3) -> Vector3:
	if desired.length_squared() < 0.001:
		return Vector3.ZERO
	var origin := global_position + Vector3.UP * 0.85
	if not _movement_ray_blocked(origin, desired):
		return desired
	var left := desired.rotated(Vector3.UP, -PI / 2.8).normalized()
	var right := desired.rotated(Vector3.UP, PI / 2.8).normalized()
	var first := left if strafe_direction >= 0.0 else right
	var second := right if strafe_direction >= 0.0 else left
	if not _movement_ray_blocked(origin, first):
		return first
	if not _movement_ray_blocked(origin, second):
		return second
	return Vector3.ZERO

func _movement_ray_blocked(origin: Vector3, direction: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * OBSTACLE_PROBE_DISTANCE)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider != target

func _has_line_of_sight() -> bool:
	if not target or not is_instance_valid(target):
		return false
	var origin := head.global_position
	var destination := target.global_position + Vector3.UP * 1.05
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == target

func _find_target() -> Node3D:
	var nearest: Node3D
	var best_distance := DETECT_RANGE
	for actor in get_tree().get_nodes_in_group("combatants"):
		if actor == self or not actor is CharacterBody3D:
			continue
		var candidate := actor as CharacterBody3D
		if int(candidate.get("health")) <= 0 or candidate.is_in_group("bots"):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = candidate
	return nearest

func _shoot_at_target() -> void:
	if not target or not is_instance_valid(target):
		return
	fire_timer = FIRE_INTERVAL
	var origin := head.global_position
	var aim := (target.global_position + Vector3.UP * 1.0 - origin).normalized()
	# Bots deliberately have imperfect aim; players should have time to react,
	# use cover, and learn the combat loop.
	aim = (aim + Vector3(randf_range(-0.075, 0.075), randf_range(-0.045, 0.045), randf_range(-0.075, 0.075))).normalized()
	game.call("bot_fire", bot_id, origin, aim)
