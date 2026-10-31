extends Node

signal weapon_state_changed(weapon_name: String, ammo: int, reserve: int)

@export var reload_duration: float = 1.55

@onready var camera: Camera3D = get_parent() as Camera3D

var weapon_index: int = 0
var weapon_names: Array[String] = ["MA5K RIFLE", "M6 SIDEARM"]
var damage_values: Array[float] = [17.0, 34.0]
var intervals: Array[float] = [0.105, 0.28]
var mag_sizes: Array[int] = [36, 12]
var ammo_in_mag: Array[int] = [36, 12]
var reserve_by_weapon: Array[int] = [180, 48]
var cooldown: float = 0.0
var reloading: bool = false
var reload_token: int = 0
var viewmodel: Node3D

func _ready() -> void:
	_create_viewmodel()
	_emit_weapon_state()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	cooldown = maxf(0.0, cooldown - delta)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("fire"):
		_fire()
	if Input.is_action_just_pressed("reload"):
		_reload()
	if Input.is_action_just_pressed("swap_weapon"):
		_swap_weapon()

func _create_viewmodel() -> void:
	viewmodel = Node3D.new()
	viewmodel.position = Vector3(0.34, -0.29, -0.58)
	viewmodel.rotation_degrees = Vector3(-4.0, -7.0, 0.0)
	camera.add_child(viewmodel)
	_add_gun_part(Vector3.ZERO, Vector3(0.19, 0.16, 0.48), Color(0.12, 0.19, 0.25), 0.7)
	_add_gun_part(Vector3(0, 0.055, -0.29), Vector3(0.075, 0.075, 0.32), Color(0.055, 0.08, 0.1), 0.85)
	_add_gun_part(Vector3(0, -0.16, 0.06), Vector3(0.12, 0.25, 0.16), Color(0.09, 0.14, 0.18), 0.55)
	_add_gun_part(Vector3(0, 0.105, -0.08), Vector3(0.06, 0.025, 0.15), Color(0.1, 0.75, 1.0), 0.3, true)

func _add_gun_part(pos: Vector3, dimensions: Vector3, tint: Color, metal: float, glow: bool = false) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = metal
	material.roughness = 0.28
	if glow:
		material.emission_enabled = true
		material.emission = tint
		material.emission_energy_multiplier = 1.8
	part.material_override = material
	viewmodel.add_child(part)

func _fire() -> void:
	if cooldown > 0.0 or reloading:
		return
	if ammo_in_mag[weapon_index] <= 0:
		_reload()
		return

	ammo_in_mag[weapon_index] -= 1
	cooldown = intervals[weapon_index]
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 180.0)
	var player_body := camera.get_parent().get_parent() as CollisionObject3D
	query.exclude = [player_body.get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)

	if not hit.is_empty():
		var collider = hit.get("collider")
		if collider != null and collider.has_method("take_damage"):
			var damage: float = damage_values[weapon_index]
			var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
			if hit_position.distance_to(collider.global_position + Vector3.UP * 1.4) < 0.32:
				damage *= 2.0
			collider.take_damage(damage)

	_emit_weapon_state()

func _reload() -> void:
	if reloading or ammo_in_mag[weapon_index] >= mag_sizes[weapon_index] or reserve_by_weapon[weapon_index] <= 0:
		return
	reloading = true
	reload_token += 1
	var this_reload := reload_token
	await get_tree().create_timer(reload_duration).timeout
	if not is_inside_tree() or this_reload != reload_token:
		return
	var loaded: int = mini(mag_sizes[weapon_index] - ammo_in_mag[weapon_index], reserve_by_weapon[weapon_index])
	ammo_in_mag[weapon_index] += loaded
	reserve_by_weapon[weapon_index] -= loaded
	reloading = false
	_emit_weapon_state()

func _swap_weapon() -> void:
	if reloading:
		reload_token += 1
		reloading = false
	weapon_index = (weapon_index + 1) % weapon_names.size()
	viewmodel.scale = Vector3.ONE if weapon_index == 0 else Vector3(0.78, 0.78, 0.78)
	cooldown = 0.25
	_emit_weapon_state()

func _emit_weapon_state() -> void:
	weapon_state_changed.emit(weapon_names[weapon_index], ammo_in_mag[weapon_index], reserve_by_weapon[weapon_index])

func current_weapon_name() -> String:
	return weapon_names[weapon_index]
