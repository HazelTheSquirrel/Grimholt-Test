extends Node3D
class_name GrimholtWorld

const WORLD_SIZE := 96
const GRID_STEP := 1.0
const BASE_HEIGHT := 7.0
const HEIGHT_SCALE := 8.0

var terrain_mesh: MeshInstance3D
var terrain_body: StaticBody3D
var height_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()

func _ready() -> void:
    _configure_noise()
    _generate_terrain()

func _configure_noise() -> void:
    height_noise.seed = 472901
    height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    height_noise.frequency = 0.018
    height_noise.fractal_octaves = 4
    height_noise.fractal_lacunarity = 2.1
    height_noise.fractal_gain = 0.48

    detail_noise.seed = 99173
    detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
    detail_noise.frequency = 0.075
    detail_noise.fractal_octaves = 2

func get_height_at(x: float, z: float) -> float:
    var broad := height_noise.get_noise_2d(x, z)
    var detail := detail_noise.get_noise_2d(x, z) * 0.18
    return BASE_HEIGHT + (broad + detail) * HEIGHT_SCALE

func _generate_terrain() -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface.set_material(_make_terrain_material())

    var half_size := float(WORLD_SIZE) * 0.5
    for x in range(WORLD_SIZE):
        for z in range(WORLD_SIZE):
            var x0 := (float(x) - half_size) * GRID_STEP
            var x1 := (float(x + 1) - half_size) * GRID_STEP
            var z0 := (float(z) - half_size) * GRID_STEP
            var z1 := (float(z + 1) - half_size) * GRID_STEP

            var p00 := Vector3(x0, get_height_at(x0, z0), z0)
            var p10 := Vector3(x1, get_height_at(x1, z0), z0)
            var p01 := Vector3(x0, get_height_at(x0, z1), z1)
            var p11 := Vector3(x1, get_height_at(x1, z1), z1)

            _add_triangle(surface, p00, p01, p10)
            _add_triangle(surface, p10, p01, p11)

    surface.generate_normals()
    var mesh := surface.commit()

    terrain_mesh = MeshInstance3D.new()
    terrain_mesh.name = "Terrain"
    terrain_mesh.mesh = mesh
    add_child(terrain_mesh)

    terrain_body = StaticBody3D.new()
    terrain_body.name = "TerrainCollision"
    var collision := CollisionShape3D.new()
    collision.shape = mesh.create_trimesh_shape()
    terrain_body.add_child(collision)
    add_child(terrain_body)

    _add_water()

func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    surface.set_color(_terrain_color(a.y))
    surface.add_vertex(a)
    surface.set_color(_terrain_color(b.y))
    surface.add_vertex(b)
    surface.set_color(_terrain_color(c.y))
    surface.add_vertex(c)

func _terrain_color(height: float) -> Color:
    if height < 3.5:
        return Color(0.72, 0.68, 0.48)
    if height > 13.0:
        return Color(0.43, 0.45, 0.46)
    if height > 10.0:
        return Color(0.36, 0.43, 0.30)
    return Color(0.27, 0.48, 0.23)

func _make_terrain_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 1.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func _add_water() -> void:
    var water := MeshInstance3D.new()
    water.name = "WaterPlane"
    var plane := PlaneMesh.new()
    plane.size = Vector2(WORLD_SIZE, WORLD_SIZE)
    water.mesh = plane
    water.position.y = 2.8
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.36, 0.49, 0.62)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.roughness = 0.22
    water.material_override = material
    add_child(water)
