extends Node3D
class_name GrimholtVoxelChunk

const Config = preload("res://scripts/core/world_config.gd")
const Blocks = preload("res://scripts/world/block_registry.gd")

var chunk_coord: Vector2i
var voxels: PackedByteArray = PackedByteArray()
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var is_generated: bool = false

func generate(noise: FastNoiseLite) -> void:
    voxels.resize(Config.CHUNK_SIZE * Config.WORLD_HEIGHT * Config.CHUNK_SIZE)
    voxels.fill(Blocks.AIR)
    for local_x in range(Config.CHUNK_SIZE):
        for local_z in range(Config.CHUNK_SIZE):
            var world_x := chunk_coord.x * Config.CHUNK_SIZE + local_x
            var world_z := chunk_coord.y * Config.CHUNK_SIZE + local_z
            var broad := noise.get_noise_2d(float(world_x), float(world_z))
            var height := clampi(roundi(Config.TERRAIN_BASE_HEIGHT + broad * Config.TERRAIN_HEIGHT_SCALE), 2, Config.WORLD_HEIGHT - 2)
            for y in range(height + 1):
                var block_id := Blocks.STONE
                if y == height:
                    block_id = Blocks.GRASS
                elif y >= height - 3:
                    block_id = Blocks.DIRT
                set_voxel_local(local_x, y, local_z, block_id)
    is_generated = true

func get_voxel_local(x: int, y: int, z: int) -> int:
    if x < 0 or x >= Config.CHUNK_SIZE or y < 0 or y >= Config.WORLD_HEIGHT or z < 0 or z >= Config.CHUNK_SIZE:
        return Blocks.AIR
    return int(voxels[_index(x, y, z)])

func set_voxel_local(x: int, y: int, z: int, block_id: int) -> void:
    if x < 0 or x >= Config.CHUNK_SIZE or y < 0 or y >= Config.WORLD_HEIGHT or z < 0 or z >= Config.CHUNK_SIZE:
        return
    voxels[_index(x, y, z)] = block_id

func build_mesh(world: Node) -> void:
    if not is_generated:
        return
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var directions: Array[Vector3i] = [
        Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
        Vector3i(0, 1, 0), Vector3i(0, -1, 0),
        Vector3i(0, 0, 1), Vector3i(0, 0, -1)
    ]
    for x in range(Config.CHUNK_SIZE):
        for y in range(Config.WORLD_HEIGHT):
            for z in range(Config.CHUNK_SIZE):
                var block_id := get_voxel_local(x, y, z)
                if block_id == Blocks.AIR:
                    continue
                var world_x := chunk_coord.x * Config.CHUNK_SIZE + x
                var world_z := chunk_coord.y * Config.CHUNK_SIZE + z
                for face in range(directions.size()):
                    var direction: Vector3i = directions[face]
                    if int(world.call("get_voxel", Vector3i(world_x, y, world_z) + direction)) == Blocks.AIR:
                        _append_face(surface, Vector3(x, y, z), face, Blocks.color_for(block_id))
    var mesh := surface.commit()
    if mesh_instance == null:
        mesh_instance = MeshInstance3D.new()
        mesh_instance.name = "ChunkMesh"
        add_child(mesh_instance)
    mesh_instance.mesh = mesh
    mesh_instance.material_override = _make_material()
    if static_body != null:
        static_body.queue_free()
        static_body = null
    if mesh.get_surface_count() > 0:
        static_body = StaticBody3D.new()
        static_body.name = "ChunkCollision"
        var collision := CollisionShape3D.new()
        collision.shape = mesh.create_trimesh_shape()
        static_body.add_child(collision)
        add_child(static_body)

func _append_face(surface: SurfaceTool, origin: Vector3, face: int, color: Color) -> void:
    var corners: Array[Vector3] = []
    var normal := Vector3.ZERO
    match face:
        0:
            normal = Vector3.RIGHT
            corners = [Vector3(1,0,0), Vector3(1,1,0), Vector3(1,1,1), Vector3(1,0,1)]
        1:
            normal = Vector3.LEFT
            corners = [Vector3(0,0,1), Vector3(0,1,1), Vector3(0,1,0), Vector3(0,0,0)]
        2:
            normal = Vector3.UP
            corners = [Vector3(0,1,1), Vector3(1,1,1), Vector3(1,1,0), Vector3(0,1,0)]
        3:
            normal = Vector3.DOWN
            corners = [Vector3(0,0,0), Vector3(1,0,0), Vector3(1,0,1), Vector3(0,0,1)]
        4:
            normal = Vector3.BACK
            corners = [Vector3(1,0,1), Vector3(1,1,1), Vector3(0,1,1), Vector3(0,0,1)]
        5:
            normal = Vector3.FORWARD
            corners = [Vector3(0,0,0), Vector3(0,1,0), Vector3(1,1,0), Vector3(1,0,0)]
    for index in [0, 1, 2, 0, 2, 3]:
        surface.set_normal(normal)
        surface.set_color(color)
        surface.add_vertex(origin + corners[index])

func _make_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 1.0
    material.cull_mode = BaseMaterial3D.CULL_BACK
    return material

func _index(x: int, y: int, z: int) -> int:
    return (y * Config.CHUNK_SIZE + z) * Config.CHUNK_SIZE + x
