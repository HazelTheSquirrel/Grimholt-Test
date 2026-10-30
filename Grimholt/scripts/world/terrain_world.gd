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
    var grass := Color(0.24, 0.39, 0.19)
    var moss := Color(0.34, 0.39, 0.19)
    var stone := Color(0.39, 0.40, 0.39)
    var color := grass.lerp(moss, clampf((0.2 - height_factor) * 2.5, 0.0, 1.0))
    color = color.lerp(stone, clampf(maxf(slope * 1.35, height_factor * 0.85), 0.0, 0.88))
    return color.lightened(variation)

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
    var terrain_material := StandardMaterial3D.new()
    terrain_material.vertex_color_use_as_albedo = true
    terrain_material.roughness = 1.0
    var terrain_visual := MeshInstance3D.new()
    terrain_visual.name = "TerrainSurface"
    terrain_visual.mesh = terrain_mesh
    terrain_visual.material_override = terrain_material
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
        {"id": "tree", "name": "Eiche", "item": "wood", "amount": 4, "x": -9.0, "z": -5.0},
        {"id": "tree", "name": "Birke", "item": "wood", "amount": 3, "x": -5.0, "z": 8.0},
        {"id": "tree", "name": "Fichte", "item": "wood", "amount": 5, "x": 10.0, "z": 7.0},
        {"id": "iron_vein", "name": "Eisenader", "item": "iron_ore", "amount": 3, "x": 12.0, "z": -9.0},
        {"id": "iron_vein", "name": "Eisenader", "item": "iron_ore", "amount": 3, "x": -14.0, "z": -12.0},
        {"id": "herb", "name": "Heilkraut", "item": "herb", "amount": 2, "x": 5.0, "z": -14.0},
        {"id": "herb", "name": "Heilkraut", "item": "herb", "amount": 2, "x": -12.0, "z": 11.0}
    ]
    for entry in placements:
        var node: GrimholtResourceNode = ResourceNodeScript.new()
        node.configure(String(entry["id"]), String(entry["name"]), String(entry["item"]), int(entry["amount"]))
        var px := float(entry["x"])
        var pz := float(entry["z"])
        node.position = Vector3(px, height_at(px, pz), pz)
        add_child(node)
