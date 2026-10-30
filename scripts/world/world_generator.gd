extends Node3D
class_name GrimholtWorld

const Config = preload("res://scripts/core/world_config.gd")
const ChunkScript = preload("res://scripts/world/voxel_chunk.gd")
const Blocks = preload("res://scripts/world/block_registry.gd")

const SAVE_ROOT := "user://worlds/default"
const SAVE_VERSION := 1

@export var world_seed: int = Config.DEFAULT_SEED
@export var load_radius: int = Config.LOAD_RADIUS
var chunks: Dictionary = {}
var terrain_noise := FastNoiseLite.new()
var tracked_player: Node3D
var stream_timer: float = 0.0
var modified_blocks: Dictionary = {}

func _ready() -> void:
    _load_world_metadata()
    _configure_noise()
    _load_chunks_around(Vector2i.ZERO)

func _exit_tree() -> void:
    save_world()

func set_player(player: Node3D) -> void:
    tracked_player = player
    _refresh_streaming()

func _process(delta: float) -> void:
    if tracked_player == null or not is_instance_valid(tracked_player):
        return
    stream_timer += delta
    if stream_timer >= 0.35:
        stream_timer = 0.0
        _refresh_streaming()

func _configure_noise() -> void:
    terrain_noise.seed = world_seed
    terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    terrain_noise.frequency = Config.TERRAIN_FREQUENCY
    terrain_noise.fractal_octaves = 4
    terrain_noise.fractal_lacunarity = 2.0
    terrain_noise.fractal_gain = 0.48

func _refresh_streaming() -> void:
    var player_chunk := Vector2i(floori(tracked_player.global_position.x / float(Config.CHUNK_SIZE)), floori(tracked_player.global_position.z / float(Config.CHUNK_SIZE)))
    _load_chunks_around(player_chunk)
    _unload_distant_chunks(player_chunk)

func _load_chunks_around(center: Vector2i) -> void:
    for x in range(center.x - load_radius, center.x + load_radius + 1):
        for z in range(center.y - load_radius, center.y + load_radius + 1):
            var coord := Vector2i(x, z)
            if chunks.has(coord):
                continue
            var chunk: GrimholtVoxelChunk = ChunkScript.new()
            chunk.name = "Chunk_%d_%d" % [x, z]
            chunk.chunk_coord = coord
            chunk.position = Vector3(x * Config.CHUNK_SIZE, 0.0, z * Config.CHUNK_SIZE)
            chunk.generate(terrain_noise)
            _apply_saved_changes(chunk)
            add_child(chunk)
            chunks[coord] = chunk
            chunk.build_mesh(self)
            _rebuild_loaded_neighbors(coord)

func _unload_distant_chunks(center: Vector2i) -> void:
    var unload_distance := load_radius + Config.UNLOAD_MARGIN
    for key in chunks.keys():
        var coord: Vector2i = key
        if abs(coord.x - center.x) > unload_distance or abs(coord.y - center.y) > unload_distance:
            var chunk: Node = chunks[coord]
            chunks.erase(coord)
            chunk.queue_free()
            _rebuild_loaded_neighbors(coord)

func _rebuild_loaded_neighbors(coord: Vector2i) -> void:
    var neighbors: Array[Vector2i] = [coord + Vector2i(1,0), coord + Vector2i(-1,0), coord + Vector2i(0,1), coord + Vector2i(0,-1)]
    for neighbor_coord in neighbors:
        if chunks.has(neighbor_coord):
            var neighbor: GrimholtVoxelChunk = chunks[neighbor_coord]
            neighbor.build_mesh(self)

func get_voxel(world_position: Vector3i) -> int:
    if world_position.y < 0 or world_position.y >= Config.WORLD_HEIGHT:
        return Blocks.AIR
    var chunk_x := floori(float(world_position.x) / Config.CHUNK_SIZE)
    var chunk_z := floori(float(world_position.z) / Config.CHUNK_SIZE)
    var coord := Vector2i(chunk_x, chunk_z)
    if not chunks.has(coord):
        return Blocks.AIR
    var local_x := world_position.x - chunk_x * Config.CHUNK_SIZE
    var local_z := world_position.z - chunk_z * Config.CHUNK_SIZE
    var chunk: GrimholtVoxelChunk = chunks[coord]
    return chunk.get_voxel_local(local_x, world_position.y, local_z)

func set_voxel(world_position: Vector3i, block_id: int) -> bool:
    if world_position.y < 0 or world_position.y >= Config.WORLD_HEIGHT:
        return false
    if block_id < Blocks.AIR or block_id > Blocks.SAND:
        return false
    var chunk_x := floori(float(world_position.x) / Config.CHUNK_SIZE)
    var chunk_z := floori(float(world_position.z) / Config.CHUNK_SIZE)
    var coord := Vector2i(chunk_x, chunk_z)
    if not chunks.has(coord):
        return false
    var local_x := world_position.x - chunk_x * Config.CHUNK_SIZE
    var local_z := world_position.z - chunk_z * Config.CHUNK_SIZE
    var chunk: GrimholtVoxelChunk = chunks[coord]
    if chunk.get_voxel_local(local_x, world_position.y, local_z) == block_id:
        return false
    chunk.set_voxel_local(local_x, world_position.y, local_z, block_id)
    var key := _voxel_key(world_position)
    modified_blocks[key] = block_id
    chunk.build_mesh(self)
    if local_x == 0:
        _rebuild_one_neighbor(coord + Vector2i(-1, 0))
    elif local_x == Config.CHUNK_SIZE - 1:
        _rebuild_one_neighbor(coord + Vector2i(1, 0))
    if local_z == 0:
        _rebuild_one_neighbor(coord + Vector2i(0, -1))
    elif local_z == Config.CHUNK_SIZE - 1:
        _rebuild_one_neighbor(coord + Vector2i(0, 1))
    _save_chunk(coord)
    return true

func _rebuild_one_neighbor(coord: Vector2i) -> void:
    if chunks.has(coord):
        var neighbor: GrimholtVoxelChunk = chunks[coord]
        neighbor.build_mesh(self)

func _voxel_key(position: Vector3i) -> String:
    return "%d,%d,%d" % [position.x, position.y, position.z]

func _chunk_path(coord: Vector2i) -> String:
    return "%s/chunks/%d_%d.json" % [SAVE_ROOT, coord.x, coord.y]

func _apply_saved_changes(chunk: GrimholtVoxelChunk) -> void:
    var path := _chunk_path(chunk.chunk_coord)
    if not FileAccess.file_exists(path):
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("Grimholt: Chunk-Speicherdatei konnte nicht gelesen werden: " + path)
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary or int(parsed.get("version", -1)) != SAVE_VERSION:
        push_warning("Grimholt: Ungültige oder inkompatible Chunk-Datei: " + path)
        return
    var entries: Variant = parsed.get("blocks", [])
    if not entries is Array:
        push_warning("Grimholt: Beschädigte Blockdaten in " + path)
        return
    for entry in entries:
        if not entry is Array or entry.size() != 2:
            continue
        var index := int(entry[0])
        var block_id := int(entry[1])
        if index < 0 or index >= chunk.voxels.size() or block_id < Blocks.AIR or block_id > Blocks.SAND:
            continue
        chunk.voxels[index] = block_id
        var local_x := index % Config.CHUNK_SIZE
        var local_z := floori(float(index) / Config.CHUNK_SIZE) % Config.CHUNK_SIZE
        var local_y := floori(float(index) / (Config.CHUNK_SIZE * Config.CHUNK_SIZE))
        var world_position := Vector3i(chunk.chunk_coord.x * Config.CHUNK_SIZE + local_x, local_y, chunk.chunk_coord.y * Config.CHUNK_SIZE + local_z)
        modified_blocks[_voxel_key(world_position)] = block_id

func _save_chunk(coord: Vector2i) -> void:
    var chunk: GrimholtVoxelChunk = chunks.get(coord)
    if chunk == null:
        return
    var entries: Array = []
    for key in modified_blocks:
        var parts := String(key).split(",")
        if parts.size() != 3:
            continue
        var world_x := int(parts[0])
        var world_y := int(parts[1])
        var world_z := int(parts[2])
        if floori(float(world_x) / Config.CHUNK_SIZE) != coord.x or floori(float(world_z) / Config.CHUNK_SIZE) != coord.y:
            continue
        var local_x := world_x - coord.x * Config.CHUNK_SIZE
        var local_z := world_z - coord.y * Config.CHUNK_SIZE
        var index := (world_y * Config.CHUNK_SIZE + local_z) * Config.CHUNK_SIZE + local_x
        entries.append([index, int(modified_blocks[key])])
    var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT + "/chunks"))
    if directory_error != OK:
        push_error("Grimholt: Speicherverzeichnis konnte nicht erstellt werden.")
        return
    var file := FileAccess.open(_chunk_path(coord), FileAccess.WRITE)
    if file == null:
        push_error("Grimholt: Chunk konnte nicht gespeichert werden: " + _chunk_path(coord))
        return
    file.store_string(JSON.stringify({"version": SAVE_VERSION, "blocks": entries}))

func _load_world_metadata() -> void:
    var path := SAVE_ROOT + "/world.json"
    if not FileAccess.file_exists(path):
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_warning("Grimholt: Welt-Metadaten konnten nicht gelesen werden.")
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary and int(parsed.get("version", -1)) == SAVE_VERSION:
        world_seed = int(parsed.get("seed", world_seed))
    else:
        push_warning("Grimholt: Welt-Metadaten sind ungültig oder inkompatibel.")

func save_world() -> void:
    var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_ROOT))
    if directory_error != OK:
        push_error("Grimholt: Welt-Speicherverzeichnis konnte nicht erstellt werden.")
        return
    var metadata := FileAccess.open(SAVE_ROOT + "/world.json", FileAccess.WRITE)
    if metadata == null:
        push_error("Grimholt: Welt-Metadaten konnten nicht gespeichert werden.")
        return
    metadata.store_string(JSON.stringify({"version": SAVE_VERSION, "seed": world_seed, "generator_version": 1}))
    for key in chunks:
        _save_chunk(key)

func get_height_at(world_x: int, world_z: int) -> int:
    var value := terrain_noise.get_noise_2d(float(world_x), float(world_z))
    return clampi(roundi(Config.TERRAIN_BASE_HEIGHT + value * Config.TERRAIN_HEIGHT_SCALE), 2, Config.WORLD_HEIGHT - 2)
