extends Node

const FLOOR: Color = Color(0.075, 0.11, 0.15)
const WALL: Color = Color(0.12, 0.19, 0.25)
const ARMOR: Color = Color(0.19, 0.29, 0.36)
const CYAN: Color = Color(0.04, 0.65, 0.92)
const AMBER: Color = Color(0.95, 0.48, 0.12)

func build(world: Node3D) -> void:
	_add_box(world, Vector3(0, -0.5, 0), Vector3(52, 1, 52), FLOOR, 0.35)
	_add_box(world, Vector3(0, 4, -26), Vector3(52, 8, 1), WALL)
	_add_box(world, Vector3(0, 4, 26), Vector3(52, 8, 1), WALL)
	_add_box(world, Vector3(-26, 4, 0), Vector3(1, 8, 52), WALL)
	_add_box(world, Vector3(26, 4, 0), Vector3(1, 8, 52), WALL)
	_add_box(world, Vector3(0, 7.75, -25.35), Vector3(50, 0.18, 0.12), CYAN, 0.2, true, false)
	_add_box(world, Vector3(0, 7.75, 25.35), Vector3(50, 0.18, 0.12), CYAN, 0.2, true, false)
	_add_box(world, Vector3(-25.35, 7.75, 0), Vector3(0.12, 0.18, 50), CYAN, 0.2, true, false)
	_add_box(world, Vector3(25.35, 7.75, 0), Vector3(0.12, 0.18, 50), CYAN, 0.2, true, false)
	for x in [-15.0, -5.0, 5.0, 15.0]:
		for z in [-15.0, 15.0]:
			_add_cover_block(world, Vector3(x, 1.1, z))
	for z in [-9.0, 9.0]:
		_add_box(world, Vector3(-9, 1.4, z * 0.0), Vector3(2.4, 2.8, 7.0), ARMOR)
	_add_box(world, Vector3(-9, 1.4, 0), Vector3(2.4, 2.8, 7.0), ARMOR)
	_add_box(world, Vector3(9, 1.4, 0), Vector3(2.4, 2.8, 7.0), ARMOR)
	_add_box(world, Vector3(0, 0.8, -8), Vector3(7, 1.6, 2.2), ARMOR)
	_add_box(world, Vector3(0, 0.8, 8), Vector3(7, 1.6, 2.2), ARMOR)
	_add_box(world, Vector3(0, 3.1, -25.25), Vector3(10, 1.2, 0.2), CYAN, 0.2, true, false)
	_add_box(world, Vector3(0, 3.1, 25.25), Vector3(10, 1.2, 0.2), AMBER, 0.2, true, false)
	for index in range(4):
		var x: float = -18.0 + float(index) * 12.0
		_add_box(world, Vector3(x, 0.02, -23.8), Vector3(4.0, 0.035, 0.16), CYAN, 0.1, true, false)
		_add_box(world, Vector3(x, 0.02, 23.8), Vector3(4.0, 0.035, 0.16), AMBER, 0.1, true, false)
	_add_pillar(world, Vector3(-23.8, 0.0, -23.8))
	_add_pillar(world, Vector3(23.8, 0.0, -23.8))
	_add_pillar(world, Vector3(-23.8, 0.0, 23.8))
	_add_pillar(world, Vector3(23.8, 0.0, 23.8))
	_add_lighting(world)
	_add_environment(world)

func _add_cover_block(world: Node3D, pos: Vector3) -> void:
	_add_box(world, pos, Vector3(3.2, 2.2, 2.2), ARMOR)
	_add_box(world, pos + Vector3(0, 1.12, 0), Vector3(3.35, 0.08, 2.3), CYAN, 0.2, true, false)

func _add_pillar(world: Node3D, pos: Vector3) -> void:
	_add_box(world, pos + Vector3(0, 3.0, 0), Vector3(1.2, 6.0, 1.2), WALL)
	_add_box(world, pos + Vector3(0, 6.1, 0), Vector3(1.5, 0.22, 1.5), CYAN, 0.2, true, false)

func _add_lighting(world: Node3D) -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	world.add_child(sun)
	for point in [Vector3(0, 7, 0), Vector3(-17, 5, -17), Vector3(17, 5, 17)]:
		var fill: OmniLight3D = OmniLight3D.new()
		fill.position = point
		fill.light_color = Color(0.16, 0.55, 1.0)
		fill.light_energy = 1.5
		fill.omni_range = 18.0
		world.add_child(fill)

func _add_environment(world: Node3D) -> void:
	var environment_node: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.025, 0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.23, 0.31, 0.4)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.35
	environment_node.environment = env
	world.add_child(environment_node)

func _add_box(world: Node3D, pos: Vector3, dimensions: Vector3, color: Color, metallic: float = 0.55, emissive: bool = false, collision_enabled: bool = true) -> void:
	var parent: Node3D
	if collision_enabled:
		var body: StaticBody3D = StaticBody3D.new()
		body.position = pos
		var collision: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		body.add_child(collision)
		parent = body
	else:
		var visual: Node3D = Node3D.new()
		visual.position = pos
		parent = visual
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.38
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.6
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	world.add_child(parent)
