extends Node
func build(world: Node3D) -> void:
	_add_box(world, Vector3(0,-0.5,0), Vector3(52,1,52), Color(0.12,0.16,0.2))
	_add_box(world, Vector3(0,4,-26), Vector3(52,8,1), Color(0.16,0.22,0.28))
	_add_box(world, Vector3(0,4,26), Vector3(52,8,1), Color(0.16,0.22,0.28))
	_add_box(world, Vector3(-26,4,0), Vector3(1,8,52), Color(0.16,0.22,0.28))
	_add_box(world, Vector3(26,4,0), Vector3(1,8,52), Color(0.16,0.22,0.28))
	for x in [-15.0,-5.0,5.0,15.0]:
		for z in [-15.0,15.0]:
			_add_box(world, Vector3(x,1.1,z), Vector3(3.2,2.2,2.2), Color(0.2,0.29,0.34))
	_add_box(world, Vector3(-9,1.4,0), Vector3(2.4,2.8,7.0), Color(0.18,0.27,0.34))
	_add_box(world, Vector3(9,1.4,0), Vector3(2.4,2.8,7.0), Color(0.18,0.27,0.34))
	_add_box(world, Vector3(0,0.8,-8), Vector3(7,1.6,2.2), Color(0.24,0.31,0.36))
	_add_box(world, Vector3(0,0.8,8), Vector3(7,1.6,2.2), Color(0.24,0.31,0.36))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-28,0)
	sun.light_energy = 1.2
	world.add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0,8,0)
	fill.light_color = Color(0.2,0.55,1.0)
	fill.light_energy = 2.2
	fill.omni_range = 24
	world.add_child(fill)
	var environment_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.04, 0.065, 1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.23,0.31,0.4)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = env
	world.add_child(environment_node)
func _add_box(world: Node3D, pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.55
	material.roughness = 0.48
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
