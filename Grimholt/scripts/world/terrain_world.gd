@tool
extends Node3D
class_name GrimholtTerrainWorld

const ResourceNodeScript = preload("res://scripts/world/resource_node.gd")
const WORLD_SIZE_METERS := 100000.0
const WORLD_AREA_KM2 := 10000.0
const CHUNK_SIZE := 1000.0
const CHUNK_RESOLUTION := 32
const STREAM_RADIUS := 1

@export_range(24, 96, 8) var extent: int = 64
@export_range(1.0, 4.0, 0.5) var cell_size: float = 2.0
@export var terrain_seed: int = 472901:
    set(value):
        terrain_seed = value
        if is_inside_tree():
            _rebuild_noise()
            generate()

var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var ridge_noise := FastNoiseLite.new()
var river_noise := FastNoiseLite.new()
var terrain_mesh: ArrayMesh
var generated_root: Node3D
var known_resource_ids: Array[String] = []
var active_chunks: Dictionary = {}
var _last_center := Vector2i(2147483647, 2147483647)
var _terrain_material: StandardMaterial3D
var _pending_chunks: Array[Vector2i] = []

func _ready() -> void:
    _rebuild_noise()
    generate()

func _process(_delta: float) -> void:
    if _pending_chunks.is_empty():
        return
    var key: Vector2i = _pending_chunks.pop_front()
    if generated_root != null and is_instance_valid(generated_root) and not active_chunks.has(key):
        active_chunks[key] = _create_chunk(key.x, key.y)

func _rebuild_noise() -> void:
    terrain_noise.seed = terrain_seed
    terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    terrain_noise.frequency = 0.000075
    terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    terrain_noise.fractal_octaves = 5
    terrain_noise.fractal_gain = 0.48
    detail_noise.seed = terrain_seed + 97
    detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    detail_noise.frequency = 0.0018
    detail_noise.fractal_octaves = 3
    ridge_noise.seed = terrain_seed + 211
    ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    ridge_noise.frequency = 0.00012
    ridge_noise.fractal_octaves = 4
    river_noise.seed = terrain_seed + 419
    river_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    river_noise.frequency = 0.000035
    _terrain_material = _make_terrain_material()

func _smoothstep(edge_a: float, edge_b: float, value: float) -> float:
    var t := clampf((value - edge_a) / (edge_b - edge_a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

func height_at(x: float, z: float) -> float:
    # Broad continental forms, mountain ridges and a carved, meandering river basin.
    var continental := terrain_noise.get_noise_2d(x, z)
    var ridge := 1.0 - absf(ridge_noise.get_noise_2d(x, z))
    var mountain_mask := _smoothstep(0.18, 0.62, continental + ridge * 0.28)
    var mountains := pow(ridge, 2.2) * 720.0 * mountain_mask
    var hills := continental * 115.0
    var detail := detail_noise.get_noise_2d(x, z) * 9.0
    var river_center := 12500.0 + river_noise.get_noise_2d(0.0, z * 0.42) * 10500.0
    var river_distance := absf(x - river_center)
    var river_valley := exp(-river_distance / 2600.0) * 52.0
    var channel := exp(-river_distance / 145.0) * 13.0
    return 95.0 + hills + mountains + detail - river_valley - channel

func biome_at(x: float, z: float) -> int:
    var climate := detail_noise.get_noise_2d(x * 0.28 + 900.0, z * 0.28 - 400.0)
    var elevation := height_at(x, z)
    if elevation > 540.0:
        return 3 # alpine rock
    if elevation > 340.0:
        return 2 # highland / conifer belt
    if climate < -0.28:
        return 4 # heath / dry grassland
    if climate > 0.30:
        return 1 # dense temperate forest
    return 0 # meadow and mixed woodland

func _terrain_color(position: Vector3, normal: Vector3) -> Color:
    var biome := biome_at(position.x, position.z)
    var slope := 1.0 - normal.dot(Vector3.UP)
    var variation := detail_noise.get_noise_2d(position.x * 0.11, position.z * 0.11) * 0.055
    var palette := [
        Color(0.25, 0.39, 0.18),
        Color(0.13, 0.29, 0.13),
        Color(0.31, 0.34, 0.24),
        Color(0.42, 0.43, 0.41),
        Color(0.47, 0.42, 0.25)
    ]
    var base: Color = palette[biome]
    if slope > 0.42:
        base = base.lerp(Color(0.39, 0.40, 0.39), clampf((slope - 0.42) * 1.7, 0.0, 0.92))
    if position.y > 700.0:
        base = base.lerp(Color(0.82, 0.85, 0.86), clampf((position.y - 700.0) / 300.0, 0.0, 0.8))
    return base.lightened(variation)

func _make_terrain_material() -> StandardMaterial3D:
    var material := load("res://assets/materials/terrain_grass.tres") as StandardMaterial3D
    if material == null:
        push_error("Grimholt asset pack: terrain_grass.tres could not be loaded.")
        material = StandardMaterial3D.new()
        material.albedo_color = Color(0.28, 0.38, 0.20)
        material.roughness = 1.0
        material.uv1_triplanar = true
        material.uv1_scale = Vector3(0.055, 0.055, 0.055)
        material.vertex_color_use_as_albedo = true
    return material

func generate() -> void:
    if not is_inside_tree():
        return
    if generated_root != null and is_instance_valid(generated_root):
        generated_root.free()
    generated_root = Node3D.new()
    generated_root.name = "StreamedWorld"
    add_child(generated_root)
    active_chunks.clear()
    _pending_chunks.clear()
    _last_center = Vector2i(2147483647, 2147483647)
    update_streaming(Vector3.ZERO)
    # Build the spawn chunk immediately so the player never drops through a not-yet-created collider.
    var spawn_key := Vector2i.ZERO
    if not active_chunks.has(spawn_key):
        active_chunks[spawn_key] = _create_chunk(spawn_key.x, spawn_key.y)
    _pending_chunks.erase(spawn_key)

func get_safe_spawn_position() -> Vector3:
    return Vector3(0.0, height_at(0.0, 0.0) + 1.25, 0.0)

func update_streaming(world_position: Vector3) -> void:
    if generated_root == null or not is_instance_valid(generated_root):
        return
    var center := Vector2i(floori(world_position.x / CHUNK_SIZE), floori(world_position.z / CHUNK_SIZE))
    if center == _last_center:
        return
    _last_center = center
    var wanted: Dictionary = {}
    for cz in range(center.y - STREAM_RADIUS, center.y + STREAM_RADIUS + 1):
        for cx in range(center.x - STREAM_RADIUS, center.x + STREAM_RADIUS + 1):
            if absf(float(cx) * CHUNK_SIZE) > WORLD_SIZE_METERS * 0.5 or absf(float(cz) * CHUNK_SIZE) > WORLD_SIZE_METERS * 0.5:
                continue
            var key := Vector2i(cx, cz)
            wanted[key] = true
            if not active_chunks.has(key) and not _pending_chunks.has(key):
                _pending_chunks.append(key)
    var pending_remove: Array[Vector2i] = []
    for pending_key in _pending_chunks:
        if not wanted.has(pending_key):
            pending_remove.append(pending_key)
    for pending_key in pending_remove:
        _pending_chunks.erase(pending_key)
    var remove_keys: Array = []
    for key in active_chunks.keys():
        if not wanted.has(key):
            var old_chunk: Node3D = active_chunks[key]
            old_chunk.queue_free()
            remove_keys.append(key)
    for key in remove_keys:
        active_chunks.erase(key)

func _create_chunk(chunk_x: int, chunk_z: int) -> Node3D:
    var chunk := Node3D.new()
    chunk.name = "Chunk_%d_%d" % [chunk_x, chunk_z]
    chunk.position = Vector3(float(chunk_x) * CHUNK_SIZE, 0.0, float(chunk_z) * CHUNK_SIZE)
    generated_root.add_child(chunk)
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var chunk_distance := Vector2(float(chunk_x - _last_center.x), float(chunk_z - _last_center.y)).length()
    var lod_resolution := 32 if chunk_distance <= 1.0 else 12
    var step := CHUNK_SIZE / float(lod_resolution)
    for z in range(lod_resolution):
        for x in range(lod_resolution):
            var x0 := float(x) * step
            var x1 := float(x + 1) * step
            var z0 := float(z) * step
            var z1 := float(z + 1) * step
            var a := Vector3(x0, height_at(chunk.position.x + x0, chunk.position.z + z0), z0)
            var b := Vector3(x1, height_at(chunk.position.x + x1, chunk.position.z + z0), z0)
            var c := Vector3(x0, height_at(chunk.position.x + x0, chunk.position.z + z1), z1)
            var d := Vector3(x1, height_at(chunk.position.x + x1, chunk.position.z + z1), z1)
            _add_colored_triangle(surface, a, c, b, chunk.position)
            _add_colored_triangle(surface, b, c, d, chunk.position)
    surface.generate_normals()
    var mesh := surface.commit()
    var visual := MeshInstance3D.new()
    visual.name = "TerrainSurface"
    visual.mesh = mesh
    visual.material_override = _terrain_material
    chunk.add_child(visual)
    var body := StaticBody3D.new()
    body.name = "TerrainCollision"
    var collision := CollisionShape3D.new()
    var shape := mesh.create_trimesh_shape()
    shape.backface_collision = true
    collision.shape = shape
    body.add_child(collision)
    chunk.add_child(body)
    _populate_chunk_foliage(chunk, chunk_x, chunk_z)
    _create_river_water(chunk)
    _create_waterfall(chunk, chunk_x, chunk_z)
    _create_landmark(chunk, chunk_x, chunk_z)
    if chunk_x == 0 and chunk_z == 0:
        terrain_mesh = mesh
    return chunk

func _add_colored_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, chunk_origin: Vector3) -> void:
    var face_normal := Plane(a, b, c).normal
    surface.set_color(_terrain_color(a + chunk_origin, face_normal))
    surface.add_vertex(a)
    surface.set_color(_terrain_color(b + chunk_origin, face_normal))
    surface.add_vertex(b)
    surface.set_color(_terrain_color(c + chunk_origin, face_normal))
    surface.add_vertex(c)

func _populate_chunk_foliage(chunk: Node3D, chunk_x: int, chunk_z: int) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = abs(terrain_seed + chunk_x * 73856093 + chunk_z * 19349663)
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.16
    trunk_mesh.bottom_radius = 0.30
    trunk_mesh.height = 5.0
    var trunk_mat := StandardMaterial3D.new()
    var forest_biome := biome_at(chunk.position.x + 500.0, chunk.position.z + 500.0)
    trunk_mat.albedo_color = Color(0.68, 0.66, 0.55) if forest_biome == 1 else (Color(0.22, 0.14, 0.09) if forest_biome == 2 else Color(0.34, 0.22, 0.13))
    trunk_mat.albedo_texture = load("res://assets/textures/bark_wood.svg") as Texture2D
    trunk_mat.uv1_triplanar = true
    trunk_mat.uv1_scale = Vector3(0.18, 0.18, 0.18)
    var trunk_batch := MultiMesh.new()
    trunk_batch.transform_format = MultiMesh.TRANSFORM_3D
    trunk_batch.mesh = trunk_mesh
    trunk_batch.instance_count = 90
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 2.6
    crown_mesh.height = 5.8
    var crown_mat := StandardMaterial3D.new()
    crown_mat.albedo_color = [Color(0.20, 0.39, 0.15), Color(0.12, 0.31, 0.13), Color(0.08, 0.23, 0.17), Color(0.34, 0.35, 0.30), Color(0.45, 0.39, 0.22)][forest_biome]
    crown_mat.roughness = 1.0
    crown_mat.albedo_texture = load("res://assets/textures/leaves_canopy.svg") as Texture2D
    crown_mat.uv1_triplanar = true
    crown_mat.uv1_scale = Vector3(0.12, 0.12, 0.12)
    var crown_batch := MultiMesh.new()
    crown_batch.transform_format = MultiMesh.TRANSFORM_3D
    crown_batch.mesh = crown_mesh
    crown_batch.instance_count = 90
    var grass_mesh := CylinderMesh.new()
    grass_mesh.top_radius = 0.008
    grass_mesh.bottom_radius = 0.045
    grass_mesh.height = 0.38
    var grass_mat := StandardMaterial3D.new()
    grass_mat.albedo_color = [Color(0.34, 0.48, 0.20), Color(0.22, 0.39, 0.16), Color(0.25, 0.34, 0.22), Color(0.37, 0.37, 0.32), Color(0.49, 0.43, 0.25)][forest_biome]
    grass_mat.albedo_texture = load("res://assets/textures/grass_meadow.svg") as Texture2D
    grass_mat.uv1_triplanar = true
    grass_mat.uv1_scale = Vector3(0.22, 0.22, 0.22)
    var grass_batch := MultiMesh.new()
    grass_batch.transform_format = MultiMesh.TRANSFORM_3D
    grass_batch.mesh = grass_mesh
    grass_batch.instance_count = 240
    var actual_trees := 0
    for index in range(90):
        var px := rng.randf_range(18.0, CHUNK_SIZE - 18.0)
        var pz := rng.randf_range(18.0, CHUNK_SIZE - 18.0)
        var wx := chunk.position.x + px
        var wz := chunk.position.z + pz
        var biome := biome_at(wx, wz)
        if Vector2(px, pz).length() < 28.0:
            continue
        var river_x := 12500.0 + river_noise.get_noise_2d(0.0, wz * 0.42) * 10500.0
        if biome == 3 or absf(wx - river_x) < 360.0 or rng.randf() > (0.78 if biome == 1 else 0.43):
            continue
        var ground := height_at(wx, wz)
        var scale := rng.randf_range(0.72, 1.45)
        var transform := Transform3D(Basis().scaled(Vector3(scale, scale, scale)), Vector3(px, ground + 2.5 * scale, pz))
        trunk_batch.set_instance_transform(actual_trees, transform)
        var crown_transform := Transform3D(Basis().scaled(Vector3(scale, scale, scale)), Vector3(px, ground + 6.0 * scale, pz))
        crown_batch.set_instance_transform(actual_trees, crown_transform)
        actual_trees += 1
    trunk_batch.instance_count = actual_trees
    crown_batch.instance_count = actual_trees
    var trunks := MultiMeshInstance3D.new()
    trunks.name = "ForestTrunks"
    trunks.multimesh = trunk_batch
    trunks.material_override = trunk_mat
    chunk.add_child(trunks)
    var crowns := MultiMeshInstance3D.new()
    crowns.name = "ForestCanopies"
    crowns.multimesh = crown_batch
    crowns.material_override = crown_mat
    chunk.add_child(crowns)
    for index in range(grass_batch.instance_count):
        var gx := rng.randf_range(0.0, CHUNK_SIZE)
        var gz := rng.randf_range(0.0, CHUNK_SIZE)
        var gy := height_at(chunk.position.x + gx, chunk.position.z + gz)
        var scale := rng.randf_range(0.7, 1.4)
        grass_batch.set_instance_transform(index, Transform3D(Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(scale, scale, scale)), Vector3(gx, gy + 0.18, gz)))
    var grass := MultiMeshInstance3D.new()
    grass.name = "GrassCover"
    grass.multimesh = grass_batch
    grass.material_override = grass_mat
    chunk.add_child(grass)


func _river_center(z: float) -> float:
    return 12500.0 + river_noise.get_noise_2d(0.0, z * 0.42) * 10500.0

func _create_river_water(chunk: Node3D) -> void:
    var river_intersects := false
    for sample in range(9):
        var sample_z := chunk.position.z + float(sample) / 8.0 * CHUNK_SIZE
        var sample_x := _river_center(sample_z)
        if sample_x >= chunk.position.x - 100.0 and sample_x <= chunk.position.x + CHUNK_SIZE + 100.0:
            river_intersects = true
            break
    if not river_intersects:
        return
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(48):
        var z0 := float(i) / 48.0 * CHUNK_SIZE
        var z1 := float(i + 1) / 48.0 * CHUNK_SIZE
        var wx0 := _river_center(chunk.position.z + z0) - chunk.position.x
        var wx1 := _river_center(chunk.position.z + z1) - chunk.position.x
        var w0 := 42.0 + absf(river_noise.get_noise_2d(z0, 33.0)) * 24.0
        var w1 := 42.0 + absf(river_noise.get_noise_2d(z1, 33.0)) * 24.0
        var a := Vector3(wx0 - w0, height_at(chunk.position.x + wx0, chunk.position.z + z0) - 2.0, z0)
        var b := Vector3(wx0 + w0, a.y, z0)
        var c := Vector3(wx1 - w1, height_at(chunk.position.x + wx1, chunk.position.z + z1) - 2.0, z1)
        var d := Vector3(wx1 + w1, c.y, z1)
        surface.set_color(Color(0.12, 0.38, 0.52, 0.88))
        surface.add_vertex(a)
        surface.add_vertex(c)
        surface.add_vertex(b)
        surface.add_vertex(b)
        surface.add_vertex(c)
        surface.add_vertex(d)
    var water := MeshInstance3D.new()
    water.name = "RiverWater"
    water.mesh = surface.commit()
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.16, 0.43, 0.58, 0.82)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.roughness = 0.14
    material.metallic = 0.12
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    water.material_override = material
    chunk.add_child(water)


func _create_waterfall(chunk: Node3D, cx: int, cz: int) -> void:
    # Signature waterfall landmark in the northern mountain region.
    if cx != 3 or cz != -2:
        return
    var cascade := MeshInstance3D.new()
    cascade.name = "MountainWaterfall"
    var plane := PlaneMesh.new()
    plane.size = Vector2(34.0, 62.0)
    cascade.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.35, 0.68, 0.79, 0.78)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.roughness = 0.12
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    cascade.material_override = material
    cascade.position = Vector3(500.0, height_at(chunk.position.x + 500.0, chunk.position.z + 500.0) + 30.0, 500.0)
    cascade.rotation.y = PI * 0.5
    chunk.add_child(cascade)
    var plunge_pool := MeshInstance3D.new()
    plunge_pool.name = "WaterfallPlungePool"
    var pool := CylinderMesh.new()
    pool.top_radius = 24.0
    pool.bottom_radius = 24.0
    pool.height = 1.2
    plunge_pool.mesh = pool
    plunge_pool.material_override = material
    plunge_pool.position = cascade.position + Vector3(20.0, -29.0, 0.0)
    chunk.add_child(plunge_pool)

func _landmark_box(parent: Node3D, label: String, size: Vector3, pos: Vector3, tint: Color) -> void:
    var instance := MeshInstance3D.new()
    instance.name = label
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.95
    instance.material_override = material
    instance.position = pos
    parent.add_child(instance)

func _create_landmark(chunk: Node3D, cx: int, cz: int) -> void:
    var id := ""
    if cx == 3 and cz == -2:
        id = "watchtower_ruin"
    elif cx == -4 and cz == 2:
        id = "abandoned_village"
    elif cx == 6 and cz == 5:
        id = "stone_circle"
    elif cx == -7 and cz == -4:
        id = "dungeon_entrance"
    if id.is_empty():
        return
    var site := Node3D.new()
    site.name = "Landmark_" + id
    site.position = Vector3(500.0, height_at(chunk.position.x + 500.0, chunk.position.z + 500.0), 500.0)
    chunk.add_child(site)
    if id == "watchtower_ruin":
        _landmark_box(site, "KeepFoundation", Vector3(20, 2, 20), Vector3.ZERO, Color(0.35, 0.35, 0.33))
        for i in range(4):
            _landmark_box(site, "BrokenWall_%d" % i, Vector3(17, 7 + float(i % 2) * 3, 1.5), Vector3(0, 4, -8 + i * 5.3), Color(0.42, 0.41, 0.37))
        _landmark_box(site, "TowerRemnant", Vector3(5, 14, 5), Vector3(5, 6, 4), Color(0.32, 0.33, 0.32))
    elif id == "abandoned_village":
        for i in range(7):
            var p := Vector3(float(i % 3) * 17.0 - 17.0, 2.5, float(i / 3) * 18.0 - 18.0)
            _landmark_box(site, "House_%d" % i, Vector3(10, 5, 9), p, Color(0.43, 0.31, 0.20))
            _landmark_box(site, "Roof_%d" % i, Vector3(12, 2, 11), p + Vector3(0, 3.5, 0), Color(0.24, 0.16, 0.12))
    elif id == "stone_circle":
        for i in range(9):
            var angle := TAU * float(i) / 9.0
            _landmark_box(site, "StandingStone_%d" % i, Vector3(2.2, 5, 1.4), Vector3(cos(angle) * 18, 2.5, sin(angle) * 18), Color(0.39, 0.42, 0.43))
    else:
        _landmark_box(site, "DungeonLintel", Vector3(15, 3, 3), Vector3(0, 7, -8), Color(0.23, 0.24, 0.23))
        for side in [-1.0, 1.0]:
            _landmark_box(site, "DungeonPillar", Vector3(3, 12, 3), Vector3(side * 6, 6, -8), Color(0.30, 0.31, 0.30))
        _create_walkable_cave(site)

func _create_walkable_cave(parent: Node3D) -> void:
    var cave := Node3D.new()
    cave.name = "WalkableCaveInterior"
    cave.position = Vector3(0, 0, -12)
    parent.add_child(cave)
    var floor_material := StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.24, 0.23, 0.21)
    for i in range(12):
        var floor := MeshInstance3D.new()
        floor.name = "CaveFloor_%02d" % i
        var box := BoxMesh.new()
        box.size = Vector3(7, 0.5, 5)
        floor.mesh = box
        floor.material_override = floor_material
        floor.position = Vector3(0, -0.25, -float(i) * 5.0)
        cave.add_child(floor)
        var floor_body := StaticBody3D.new()
        floor_body.name = "CaveFloorCollision_%02d" % i
        var floor_collision := CollisionShape3D.new()
        var floor_shape := BoxShape3D.new()
        floor_shape.size = Vector3(7.0, 0.5, 5.0)
        floor_collision.shape = floor_shape
        floor_collision.position = floor.position
        floor_body.add_child(floor_collision)
        cave.add_child(floor_body)
        var arch := TorusMesh.new()
        arch.inner_radius = 3.0
        arch.outer_radius = 4.2
        arch.rings = 12
        arch.ring_segments = 16
        var rib := MeshInstance3D.new()
        rib.name = "CaveArch_%02d" % i
        rib.mesh = arch
        rib.material_override = floor_material
        rib.position = Vector3(0, 3.5, -float(i) * 5.0)
        rib.rotation.x = PI * 0.5
        cave.add_child(rib)
    var chamber := MeshInstance3D.new()
    chamber.name = "CaveEndChamber"
    var sphere := SphereMesh.new()
    sphere.radius = 8
    sphere.height = 8
    chamber.mesh = sphere
    chamber.material_override = floor_material
    chamber.position = Vector3(0, 3.5, -60)
    cave.add_child(chamber)

func populate_resources(inventory: GrimholtInventory) -> void:
    known_resource_ids.clear()
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
        known_resource_ids.append(node.persistent_id)
        node.configure(String(entry["id"]), String(entry["name"]), String(entry["item"]), int(entry["amount"]))
        var px := float(entry["x"])
        var pz := float(entry["z"])
        node.position = Vector3(px, height_at(px, pz), pz)
        add_child(node)

func has_resource_id(resource_key: String) -> bool:
    return known_resource_ids.has(resource_key)

func restore_depleted_resources(saved_ids: Variant) -> bool:
    if not saved_ids is Array:
        return false
    for resource_key in saved_ids:
        if not resource_key is String or not has_resource_id(resource_key):
            return false
    for child in get_children():
        if child is GrimholtResourceNode and saved_ids.has(child.persistent_id) and not child.is_queued_for_deletion():
            child.free()
    return true
