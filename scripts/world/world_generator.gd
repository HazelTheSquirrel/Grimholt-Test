extends Node3D
class_name GrimholtWorld

const Config = preload("res://scripts/core/world_config.gd")
const ChunkScript = preload("res://scripts/world/voxel_chunk.gd")
const Blocks = preload("res://scripts/world/block_registry.gd")

@export var world_seed: int = Config.DEFAULT_SEED
@export var load_radius: int = Config.LOAD_RADIUS
var chunks: Dictionary = {}
var terrain_noise := FastNoiseLite.new()
var tracked_player: Node3D
var stream_timer: float = 0.0

func _ready() -> void:
    _configure_noise()
    _load_chunks_around(Vector2i.ZERO)

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

func get_height_at(world_x: int, world_z: int) -> int:
    var value := terrain_noise.get_noise_2d(float(world_x), float(world_z))
    return clampi(roundi(Config.TERRAIN_BASE_HEIGHT + value * Config.TERRAIN_HEIGHT_SCALE), 2, Config.WORLD_HEIGHT - 2)
