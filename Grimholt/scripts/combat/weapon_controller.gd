extends Node3D
class_name WeaponController

signal ammo_changed(current: int, reserve: int)

@export var display_name: String = "PULSE CARBINE"
@export var damage: int = 34
@export var pellet_count: int = 1
@export var spread: float = 0.003
@export var magazine_size: int = 30
@export var reserve_capacity: int = 120
@export var fire_interval: float = 0.12
@export var reload_duration: float = 1.65
@export var max_range: float = 120.0

var magazine_ammo: int
var reserve_ammo: int
var _cooldown: float = 0.0
var _reloading: bool = false

func _ready() -> void:
    magazine_ammo = magazine_size
    reserve_ammo = reserve_capacity

func _process(delta: float) -> void:
    _cooldown = maxf(0.0, _cooldown - delta)

func try_fire() -> bool:
    if _reloading or _cooldown > 0.0 or magazine_ammo <= 0:
        return false
    magazine_ammo -= 1
    _cooldown = fire_interval
    ammo_changed.emit(magazine_ammo, reserve_ammo)
    return true

func reload() -> void:
    if _reloading or magazine_ammo == magazine_size or reserve_ammo <= 0:
        return
    _reloading = true
    await get_tree().create_timer(reload_duration).timeout
    var needed: int = magazine_size - magazine_ammo
    var loaded: int = mini(needed, reserve_ammo)
    magazine_ammo += loaded
    reserve_ammo -= loaded
    _reloading = false
    ammo_changed.emit(magazine_ammo, reserve_ammo)
