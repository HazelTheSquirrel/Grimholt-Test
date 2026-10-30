extends RefCounted
class_name GrimholtActorVisual

static func build(root: Node3D, primary_color: Color, accent_color: Color) -> void:
	var armor := StandardMaterial3D.new()
	armor.albedo_color = primary_color.darkened(0.28)
	armor.metallic = 0.48
	armor.roughness = 0.52
	var trim := StandardMaterial3D.new()
	trim.albedo_color = accent_color
	trim.metallic = 0.58
	trim.roughness = 0.38
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.035, 0.055, 0.065)
	dark.metallic = 0.22
	dark.roughness = 0.68
	var visor := StandardMaterial3D.new()
	visor.albedo_color = Color(0.16, 0.72, 0.78)
	visor.metallic = 0.72
	visor.roughness = 0.2
	visor.emission_enabled = true
	visor.emission = Color(0.04, 0.3, 0.36)
	visor.emission_energy_multiplier = 0.35
	_add_box(root, "ChestPlate", Vector3(0, 0.10, -0.17), Vector3(0.48, 0.46, 0.12), armor)
	_add_box(root, "ChestCore", Vector3(0, 0.12, -0.242), Vector3(0.24, 0.23, 0.025), trim)
	_add_box(root, "Belt", Vector3(0, -0.25, -0.04), Vector3(0.48, 0.11, 0.34), dark)
	_add_box(root, "BeltBuckle", Vector3(0, -0.25, -0.222), Vector3(0.12, 0.075, 0.025), trim)
	_add_box(root, "Backpack", Vector3(0, 0.12, 0.19), Vector3(0.34, 0.46, 0.22), dark)
	_add_sphere(root, "Helmet", Vector3(0, 0.69, 0), Vector3(0.29, 0.28, 0.29), armor)
	_add_box(root, "Visor", Vector3(0, 0.70, -0.245), Vector3(0.34, 0.105, 0.035), visor)
	for side in [-1.0, 1.0]:
		_add_sphere(root, "Shoulder_%s" % str(side), Vector3(side * 0.34, 0.30, 0), Vector3(0.22, 0.18, 0.22), trim)
		_add_box(root, "Forearm_%s" % str(side), Vector3(side * 0.31, -0.06, -0.015), Vector3(0.13, 0.28, 0.15), dark)
		_add_box(root, "Thigh_%s" % str(side), Vector3(side * 0.14, -0.48, -0.015), Vector3(0.19, 0.31, 0.23), armor)
		_add_box(root, "Boot_%s" % str(side), Vector3(side * 0.14, -0.79, -0.055), Vector3(0.20, 0.13, 0.32), dark)

static func _add_box(root: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.material_override = material
	part.position = pos
	root.add_child(part)

static func _add_sphere(root: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	part.mesh = mesh
	part.scale = dimensions
	part.material_override = material
	part.position = pos
	root.add_child(part)
