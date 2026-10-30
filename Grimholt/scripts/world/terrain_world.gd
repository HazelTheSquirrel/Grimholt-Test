@tool
extends Node3D
class_name GrimholtTerrainWorld

const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")

@export_range(24, 96, 8) var extent: int = 64:
    set(value):
        extent = value
        if is_inside_tree():
            generate()
@export_range(1.0, 4.0, 0.5) var cell_size: float = 2.0:
    set(value):
        cell_size = value
        if is_inside_tree():
            generate()
@export var terrain_seed: int = 472901:
    set(value):
        terrain_seed = value
        if is_inside_tree():
            generate()

var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var terrain_mesh: ArrayMesh
var generated_root: Node3D

func _ready() -> void:
    generate()

func height_at(x: float, z: float) -> float:
    var broad := terrain_noise.get_noise_2d(x, z) * 4.8
    var detail := detail_noise.get_noise_2d(x, z) * 0.8
    var ridge := pow(1.0 - absf(terrain_noise.get_noise_2d(x * 0.45 + 180.0, z * 0.45 - 90.0)), 2.0) * 1.8
    return 1.6 + broad + detail + ridge

func _terrain_color(position: Vector3, normal: Vector3) -> Color:
    var height_factor := clampf((position.y - 1.0) / 8.0, 0.0, 1.0)
    var slope := 1.0 - normal.dot(Vector3.UP)
    var variation := detail_noise.get_noise_2d(position.x * 1.7, position.z * 1.7) * 0.045
    var grass := Color(0.22, 0.36, 0.16)
    var moss := Color(0.34, 0.37, 0.18)
    var stone := Color(0.43, 0.43, 0.42)
    var scree := Color(0.30, 0.32, 0.32)
    var color := grass.lerp(moss, clampf((0.25 - height_factor) * 2.2, 0.0, 1.0))
    color = color.lerp(stone, clampf(maxf(slope * 1.5, height_factor * 0.9), 0.0, 0.92))
    if slope > 0.48:
        color = color.lerp(scree, clampf((slope - 0.48) * 1.8, 0.0, 0.7))
    return color.lightened(variation)

func _make_terrain_material() -> StandardMaterial3D:
    var texture_noise := FastNoiseLite.new()
    texture_noise.seed = terrain_seed + 1201
    texture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    texture_noise.frequency = 0.035
    texture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    texture_noise.fractal_octaves = 4
    var albedo_texture := NoiseTexture2D.new()
    albedo_texture.width = 512
    albedo_texture.height = 512
    albedo_texture.seamless = true
    albedo_texture.noise = texture_noise
    var texture_ramp := Gradient.new()
    texture_ramp.set_color(0, Color(0.76, 0.79, 0.70, 1.0))
    texture_ramp.add_point(0.5, Color(0.90, 0.92, 0.84, 1.0))
    texture_ramp.set_color(1, Color(1.0, 1.0, 1.0, 1.0))
    albedo_texture.color_ramp = texture_ramp
    var material := StandardMaterial3D.new()
    material.albedo_texture = albedo_texture
    material.vertex_color_use_as_albedo = true
    material.uv1_triplanar = true
    material.uv1_scale = Vector3(0.16, 0.16, 0.16)
    material.roughness = 1.0
    return material

func generate() -> void:
    if not is_inside_tree():
        return
    terrain_noise.seed = terrain_seed
    terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    terrain_noise.frequency = 0.012
    terrain_noise.fractal_octaves = 4
    detail_noise.seed = terrain_seed + 97
    detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    detail_noise.frequency = 0.055
    detail_noise.fractal_octaves = 3
    if generated_root != null and is_instance_valid(generated_root):
        generated_root.free()
    generated_root = Node3D.new()
    generated_root.name = "GeneratedTerrain"
    add_child(generated_root)

    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in range(-extent, extent):
        for x in range(-extent, extent):
            var x0 := float(x) * cell_size
            var x1 := float(x + 1) * cell_size
            var z0 := float(z) * cell_size
            var z1 := float(z + 1) * cell_size
            var a := Vector3(x0, height_at(x0, z0), z0)
            var b := Vector3(x1, height_at(x1, z0), z0)
            var c := Vector3(x0, height_at(x0, z1), z1)
            var d := Vector3(x1, height_at(x1, z1), z1)
            _add_colored_triangle(surface, a, c, b)
            _add_colored_triangle(surface, b, c, d)
    surface.generate_normals()
    terrain_mesh = surface.commit()
    var terrain_visual := MeshInstance3D.new()
    terrain_visual.name = "TerrainSurface"
    terrain_visual.mesh = terrain_mesh
    terrain_visual.material_override = _make_terrain_material()
    generated_root.add_child(terrain_visual)

    var terrain_body := StaticBody3D.new()
    terrain_body.name = "TerrainCollision"
    var terrain_collision := CollisionShape3D.new()
    var terrain_shape := terrain_mesh.create_trimesh_shape()
    terrain_shape.backface_collision = true
    terrain_collision.shape = terrain_shape
    terrain_body.add_child(terrain_collision)
    generated_root.add_child(terrain_body)

func _add_colored_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var face_normal := Plane(a, b, c).normal
    surface.set_color(_terrain_color(a, face_normal))
    surface.add_vertex(a)
    surface.set_color(_terrain_color(b, face_normal))
    surface.add_vertex(b)
    surface.set_color(_terrain_color(c, face_normal))
    surface.add_vertex(c)

func populate_resources(inventory: GrimholtInventory) -> void:
    var placements := [
        {"id": "tree", "name": "Eiche", "item": "wood", "amount": 4, "x": 0.0, "z": -2.8},
        {"id": "tree", "name": "Birke", "item": "wood", "amount": 3, "x": -12.0, "z": 8.0},
        {"id": "tree", "name": "Fichte", "item": "wood", "amount": 5, "x": 12.0, "z": 7.0},
        {"id": "iron_vein", "name": "Eisenader", "item": "iron_ore", "amount": 3, "x": 12.0, "z": -9.0},
        {"id": "iron_vein", "name": "Eisenader", "item": "iron_ore", "amount": 3, "x": -14.0, "z": -12.0},
        {"id": "herb", "name": "Heilkraut", "item": "herb", "amount": 2, "x": 5.0, "z": -14.0},
        {"id": "herb", "name": "Heilkraut", "item": "herb", "amount": 2, "x": -12.0, "z": 11.0},
        {"id": "shrub", "name": "Waldstrauch", "item": "", "amount": 0, "x": -14.0, "z": 3.0},
        {"id": "shrub", "name": "Waldstrauch", "item": "", "amount": 0, "x": 15.0, "z": 1.0},
        {"id": "shrub", "name": "Waldstrauch", "item": "", "amount": 0, "x": 2.0, "z": 15.0}
    ]
    for index in range(placements.size()):
        var entry: Dictionary = placements[index]
        var node: GrimholtResourceNode = ResourceNodeScript.new()
        node.persistent_id = "%s_%02d" % [String(entry["id"]), index]
        node.configure(String(entry["id"]), String(entry["name"]), String(entry["item"]), int(entry["amount"]))
        var px := float(entry["x"])
        var pz := float(entry["z"])
        node.position = Vector3(px, height_at(px, pz), pz)
        add_child(node)
    _populate_ground_cover()

func _populate_ground_cover() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = terrain_seed + 8103

    var grass_mesh := CylinderMesh.new()
    grass_mesh.top_radius = 0.008
    grass_mesh.bottom_radius = 0.055
    grass_mesh.height = 0.48
    grass_mesh.radial_segments = 5
    var grass_material := StandardMaterial3D.new()
    grass_material.albedo_color = Color(0.28, 0.43, 0.18)
    grass_material.roughness = 1.0
    var grass_batch := MultiMesh.new()
    grass_batch.transform_format = MultiMesh.TRANSFORM_3D
    grass_batch.mesh = grass_mesh
    grass_batch.instance_count = 2800
    for index in range(grass_batch.instance_count):
        var px := rng.randf_range(-extent * cell_size + 4.0, extent * cell_size - 4.0)
        var pz := rng.randf_range(-extent * cell_size + 4.0, extent * cell_size - 4.0)
        if Vector2(px, pz).length() < 9.0:
            px += 12.0
        var scale := rng.randf_range(0.65, 1.35)
        var basis := Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(scale, scale, scale))
        var origin := Vector3(px, height_at(px, pz) + 0.22 * scale, pz)
        grass_batch.set_instance_transform(index, Transform3D(basis, origin))
    var grass_instance := MultiMeshInstance3D.new()
    grass_instance.name = "GrassTufts"
    grass_instance.multimesh = grass_batch
    grass_instance.material_override = grass_material
    add_child(grass_instance)

    var stone_mesh := SphereMesh.new()
    stone_mesh.radius = 0.24
    stone_mesh.height = 0.32
    var stone_material := StandardMaterial3D.new()
    stone_material.albedo_color = Color(0.38, 0.40, 0.39)
    stone_material.roughness = 0.96
    var stone_batch := MultiMesh.new()
    stone_batch.transform_format = MultiMesh.TRANSFORM_3D
    stone_batch.mesh = stone_mesh
    stone_batch.instance_count = 96
    for index in range(stone_batch.instance_count):
        var px := rng.randf_range(-extent * cell_size + 4.0, extent * cell_size - 4.0)
        var pz := rng.randf_range(-extent * cell_size + 4.0, extent * cell_size - 4.0)
        var scale := rng.randf_range(0.45, 1.8)
        var basis := Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(scale, scale * rng.randf_range(0.7, 1.2), scale))
        var origin := Vector3(px, height_at(px, pz) + 0.10 * scale, pz)
        stone_batch.set_instance_transform(index, Transform3D(basis, origin))
    var stone_instance := MultiMeshInstance3D.new()
    stone_instance.name = "ScatteredStones"
    stone_instance.multimesh = stone_batch
    stone_instance.material_override = stone_material
    add_child(stone_instance)

func restore_depleted_resources(saved_ids: Variant) -> bool:
    if not saved_ids is Array:
        return false
    var allowed_ids: Dictionary = {}
    for child in get_children():
        if child is GrimholtResourceNode:
            allowed_ids[child.persistent_id] = child
    for resource_key in saved_ids:
        if not resource_key is String or not allowed_ids.has(resource_key):
            return false
    for resource_key in saved_ids:
        var resource: GrimholtResourceNode = allowed_ids[resource_key]
        resource.free()
    return true
