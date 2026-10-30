extends CharacterBody3D

const ACTOR_VISUAL := preload("res://scripts/shooter/actor_visual.gd")

const SPEED := 5.2
const DETECT_RANGE := 42.0
const FIRE_RANGE := 28.0
const FIRE_INTERVAL := 1.65
const GRAVITY := 20.0

@onready var head: Node3D = $Head
@onready var visual: MeshInstance3D = $BodyVisual
var bot_id := 0
var game: Node
var health := 100
var fire_timer := 1.0
var think_timer := 0.0
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
	think_timer -= delta
	if think_timer <= 0.0:
		think_timer = 0.25
		target = _find_target()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if target and is_instance_valid(target):
		var offset := target.global_position - global_position
		offset.y = 0.0
		if offset.length() > 5.0:
			var direction := offset.normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
			velocity.z = move_toward(velocity.z, 0.0, SPEED)
		move_and_slide()
		if offset.length() <= FIRE_RANGE and fire_timer <= 0.0:
			_shoot_at_target()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		move_and_slide()

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
	var origin := global_position + Vector3.UP * 1.45
	var aim := (target.global_position + Vector3.UP * 1.0 - origin).normalized()
	# Bots deliberately have imperfect aim; the first prototype should allow
	# players time to react, use cover, and learn the combat loop.
	aim = (aim + Vector3(randf_range(-0.075, 0.075), randf_range(-0.045, 0.045), randf_range(-0.075, 0.075))).normalized()
	game.call("bot_fire", bot_id, origin, aim)
