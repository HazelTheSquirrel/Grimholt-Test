extends Node
signal weapon_state_changed(weapon_name: String, ammo: int, reserve: int)
signal shot_fired
signal hit_confirmed
@export var reload_duration: float = 1.55
@export var max_shot_distance: float = 180.0
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
var muzzle_light: OmniLight3D
var muzzle_timer: float = 0.0
var recoil_amount: float = 0.0
var audio_manager: Node
func _ready() -> void:
	_create_viewmodel()
	audio_manager = get_tree().current_scene.get_node_or_null("AudioManager")
	_emit_weapon_state()
func _process(delta: float) -> void:
	if get_tree().paused:
		return
	cooldown = maxf(0.0, cooldown - delta)
	muzzle_timer = maxf(0.0, muzzle_timer - delta)
	recoil_amount = move_toward(recoil_amount, 0.0, delta * 3.5)
	if muzzle_light != null:
		muzzle_light.visible = muzzle_timer > 0.0
	if viewmodel != null:
		viewmodel.position.y = -0.29 + recoil_amount * 0.035
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
	_add_gun_part(Vector3(0.105, 0.02, 0.02), Vector3(0.035, 0.11, 0.22), Color(0.25, 0.34, 0.4), 0.9)
	_add_gun_part(Vector3(-0.105, 0.02, 0.02), Vector3(0.035, 0.11, 0.22), Color(0.25, 0.34, 0.4), 0.9)
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0.0, 0.06, -0.52)
	muzzle_light.light_color = Color(0.35, 0.78, 1.0)
	muzzle_light.light_energy = 3.0
	muzzle_light.omni_range = 5.0
	muzzle_light.visible = false
	viewmodel.add_child(muzzle_light)
func _add_gun_part(pos: Vector3, dimensions: Vector3, tint: Color, metal: float, glow: bool = false) -> void:
	var part: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = pos
	var material: StandardMaterial3D = StandardMaterial3D.new()
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
	muzzle_timer = 0.045
	recoil_amount = minf(1.0, recoil_amount + 0.45)
	shot_fired.emit()
	_play_sound("shot")
	var origin: Vector3 = camera.global_position
	var direction: Vector3 = -camera.global_transform.basis.z
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin + direction * max_shot_distance)
	var player_body: CollisionObject3D = camera.get_parent().get_parent() as CollisionObject3D
	query.exclude = [player_body.get_rid()]
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
		var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
		_spawn_hit_spark(hit_position, hit_normal)
		var collider: Object = hit.get("collider")
		if collider != null and collider.has_method("take_damage"):
			var damage: float = damage_values[weapon_index]
			if hit_position.distance_to((collider as Node3D).global_position + Vector3.UP * 1.4) < 0.32:
				damage *= 2.0
			collider.call("take_damage", damage)
			hit_confirmed.emit()
	_emit_weapon_state()
func _spawn_hit_spark(hit_position: Vector3, hit_normal: Vector3) -> void:
	var effect: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.14
	effect.mesh = sphere
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.58, 0.16, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.35, 0.06)
	material.emission_energy_multiplier = 2.5
	effect.material_override = material
	effect.global_position = hit_position + hit_normal * 0.04
	get_tree().current_scene.add_child(effect)
	var tween: Tween = create_tween()
	tween.tween_property(effect, "scale", Vector3.ZERO, 0.16)
	tween.tween_callback(effect.queue_free)
func _reload() -> void:
	if reloading or ammo_in_mag[weapon_index] >= mag_sizes[weapon_index] or reserve_by_weapon[weapon_index] <= 0:
		return
	reloading = true
	reload_token += 1
	var this_reload: int = reload_token
	_play_sound("reload")
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
func _play_sound(kind: String) -> void:
	if is_instance_valid(audio_manager):
		audio_manager.call("play_sfx", kind)
func current_weapon_name() -> String:
	return weapon_names[weapon_index]
