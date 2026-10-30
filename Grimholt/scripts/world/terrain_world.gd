extends Node3D
class_name GrimholtTerrainWorld

const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")

var terrain_noise := FastNoiseLite.new()
var terrain_mesh: ArrayMesh

func _ready() -> void:
    generate()

func height_at(x: float, z: float) -> float:
    return 2.0 + terrain_noise.get_noise_2d(x, z) * 4.5

func generate() -> void:
    terrain_noise.seed = 472901
    terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    terrain_noise.frequency = 0.012
    terrain_noise.fractal_octaves = 4
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var extent := 64
    var step := 2.0
    for z in range(-extent, extent):
        for x in range(-extent, extent):
            var x0 := float(x) * step
            var x1 := float(x + 1) * step
            var z0 := float(z) * step
            var z1 := float(z + 1) * step
            var a := Vector3(x0, height_at(x0, z0), z0)
            var b := Vector3(x1, height_at(x1, z0), z0)
            var c := Vector3(x0, height_at(x0, z1), z1)
            var d := Vector3(x1, height_at(x1, z1), z1)
            surface.add_vertex(a)
            surface.add_vertex(c)
            surface.add_vertex(b)
            surface.add_vertex(b)
            surface.add_vertex(c)
            surface.add_vertex(d)
    surface.generate_normals()
    terrain_mesh = surface.commit()
    var terrain_material := StandardMaterial3D.new()
    terrain_material.albedo_color = Color(0.24, 0.34, 0.19)
    terrain_material.roughness = 1.0
    var terrain_visual := MeshInstance3D.new()
    terrain_visual.name = "NaturalTerrain"
    terrain_visual.mesh = terrain_mesh
    terrain_visual.material_override = terrain_material
    add_child(terrain_visual)
    var terrain_body := StaticBody3D.new()
    terrain_body.name = "TerrainCollision"
    var terrain_collision := CollisionShape3D.new()
    var terrain_shape := terrain_mesh.create_trimesh_shape()
    terrain_shape.backface_collision = true
    terrain_collision.shape = terrain_shape
    terrain_body.add_child(terrain_collision)
    add_child(terrain_body)

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
