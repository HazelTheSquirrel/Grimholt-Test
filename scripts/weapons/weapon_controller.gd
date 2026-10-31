extends Node
signal weapon_state_changed(weapon_name: String, ammo: int, reserve: int)
@export var magazine_size: int = 36
@export var reserve_ammo: int = 180
@export var reload_duration: float = 1.55
@onready var camera: Camera3D = get_parent() as Camera3D
var ammo: int = 36
var reserve: int = 180
var cooldown: float = 0.0
var reloading: bool = false
var weapon_index: int = 0
var weapon_names: Array[String] = ["MA5K RIFLE", "M6 SIDEARM"]
var damage_values: Array[float] = [17.0, 34.0]
var intervals: Array[float] = [0.105, 0.28]
var mag_sizes: Array[int] = [36, 12]
var swap_latched: bool = false
func _ready() -> void:
	ammo = magazine_size
	reserve = reserve_ammo
	weapon_state_changed.emit(current_weapon_name(), ammo, reserve)
func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_fire()
	if Input.is_key_pressed(KEY_R) and not reloading:
		_reload()
	if Input.is_key_pressed(KEY_Q) and not swap_latched:
		swap_latched = true
		_swap_weapon()
	if not Input.is_key_pressed(KEY_Q):
		swap_latched = false
func _fire() -> void:
	if cooldown > 0.0 or reloading:
		return
	if ammo <= 0:
		_reload()
		return
	ammo -= 1
	cooldown = intervals[weapon_index]
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 180.0)
	query.exclude = [camera.get_parent().get_parent().get_rid()]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider = hit.get("collider")
		if collider != null and collider.has_method("take_damage"):
			var damage: float = damage_values[weapon_index]
			if hit.get("position", Vector3.ZERO).distance_to(collider.global_position + Vector3.UP * 1.4) < 0.32:
				damage *= 2.0
			collider.take_damage(damage)
	weapon_state_changed.emit(current_weapon_name(), ammo, reserve)
func _reload() -> void:
	if reloading or ammo == mag_sizes[weapon_index] or reserve <= 0:
		return
	reloading = true
	await get_tree().create_timer(reload_duration).timeout
	var loaded: int = mini(mag_sizes[weapon_index] - ammo, reserve)
	ammo += loaded
	reserve -= loaded
	reloading = false
	weapon_state_changed.emit(current_weapon_name(), ammo, reserve)
func _swap_weapon() -> void:
	weapon_index = (weapon_index + 1) % weapon_names.size()
	magazine_size = mag_sizes[weapon_index]
	ammo = mini(ammo, magazine_size)
	cooldown = 0.25
	weapon_state_changed.emit(current_weapon_name(), ammo, reserve)
func current_weapon_name() -> String:
	return weapon_names[weapon_index]
