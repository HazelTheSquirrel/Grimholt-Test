extends RefCounted
class_name GrimholtBlockRegistry
const AIR: int = 0
const GRASS: int = 1
const DIRT: int = 2
const STONE: int = 3
const SAND: int = 4

static func color_for(block_id: int) -> Color:
    match block_id:
        GRASS:
            return Color(0.29, 0.49, 0.24)
        DIRT:
            return Color(0.39, 0.27, 0.17)
        STONE:
            return Color(0.43, 0.45, 0.47)
        SAND:
            return Color(0.72, 0.66, 0.46)
        _:
            return Color(1.0, 0.0, 1.0)
