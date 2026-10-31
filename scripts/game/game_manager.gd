extends Node

signal score_changed(score: int, wave: int, remaining: int)
signal wave_started(wave: int, enemy_count: int)
signal wave_cleared(wave: int)

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

var world: Node3D
var player: Node3D
var score: int = 0
var wave: int = 0
var remaining: int = 0
var alive_enemies: int = 0
var spawning: bool = false
var spawn_points: Array[Vector3] = [
	Vector3(-19, 0.1, -19), Vector3(19, 0.1, -19),
	Vector3(-19, 0.1, 19), Vector3(19, 0.1, 19),
	Vector3(0, 0.1, -21), Vector3(-21, 0.1, 0),
	Vector3(21, 0.1, 0), Vector3(0, 0.1, 21)
]

func setup(p_world: Node3D, p_player: Node3D) -> void:
	world = p_world
	player = p_player
	await get_tree().create_timer(1.0, false).timeout
	if is_inside_tree():
		start_next_wave()

func start_next_wave() -> void:
	if spawning or alive_enemies > 0:
		return
	spawning = true
	wave += 1
	var count: int = 3 + wave * 2
	remaining = count
	score_changed.emit(score, wave, remaining)
	wave_started.emit(wave, count)
	for index in range(count):
		if not is_inside_tree() or not is_instance_valid(player):
			spawning = false
			return
		await get_tree().create_timer(0.65, false).timeout
		_spawn_enemy(index)
	spawning = false

func _spawn_enemy(index: int) -> void:
	if not is_instance_valid(player) or not is_instance_valid(world):
		return
	var enemy: CharacterBody3D = ENEMY_SCENE.instantiate() as CharacterBody3D
	var spawn_position: Vector3 = spawn_points[index % spawn_points.size()]
	if spawn_position.distance_to(player.global_position) < 10.0:
		spawn_position = -spawn_position.normalized() * 22.0
	enemy.position = spawn_position
	enemy.set("target", player)
	enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
	world.add_child(enemy)
	alive_enemies += 1

func _on_enemy_defeated() -> void:
	score += 100
	alive_enemies = maxi(0, alive_enemies - 1)
	remaining = maxi(0, remaining - 1)
	score_changed.emit(score, wave, remaining)
	if remaining == 0 and alive_enemies == 0 and not spawning:
		_complete_wave()

func _complete_wave() -> void:
	wave_cleared.emit(wave)
	await get_tree().create_timer(3.0, false).timeout
	if is_inside_tree():
		start_next_wave()
