extends Node
signal score_changed(score: int, wave: int, remaining: int)
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
var world: Node3D
var player: Node3D
var score: int = 0
var wave: int = 0
var remaining: int = 0
var spawn_points: Array[Vector3] = [Vector3(-17,0.1,-17),Vector3(17,0.1,-17),Vector3(-17,0.1,17),Vector3(17,0.1,17),Vector3(0,0.1,-20),Vector3(-20,0.1,0),Vector3(20,0.1,0),Vector3(0,0.1,20)]
func setup(p_world: Node3D, p_player: Node3D) -> void:
	world = p_world
	player = p_player
	await get_tree().create_timer(1.0).timeout
	start_next_wave()
func start_next_wave() -> void:
	wave += 1
	var count := 3 + wave * 2
	remaining = count
	score_changed.emit(score, wave, remaining)
	for i in range(count):
		await get_tree().create_timer(0.65).timeout
		_spawn_enemy()
func _spawn_enemy() -> void:
	if not is_instance_valid(player):
		return
	var enemy := ENEMY_SCENE.instantiate() as CharacterBody3D
	enemy.position = spawn_points[randi() % spawn_points.size()]
	enemy.set("target", player)
	enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
	world.add_child(enemy)
func _on_enemy_defeated() -> void:
	score += 100
	remaining = maxi(0, remaining - 1)
	score_changed.emit(score, wave, remaining)
	if remaining == 0:
		await get_tree().create_timer(3.0).timeout
		start_next_wave()
