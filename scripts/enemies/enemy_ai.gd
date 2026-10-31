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
	if not active or not is_instance_valid(target):
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > attack_range:
		var direction := offset.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
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
func take_damage(amount: float) -> void:
	if not active:
		return
	health -= amount
	if health <= 0.0:
		active = false
		defeated.emit()
		queue_free()
