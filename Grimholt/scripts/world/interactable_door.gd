extends StaticBody3D
class_name GrimholtInteractableDoor

@export var open_angle_degrees: float = 100.0
@export var interaction_label: String = "Tür öffnen"
@export var animation_speed: float = 5.0

var is_open: bool = false
var _closed_rotation: float
var _target_rotation: float

func _ready() -> void:
    _closed_rotation = rotation.y
    _target_rotation = _closed_rotation

func _process(delta: float) -> void:
    rotation.y = lerp_angle(rotation.y, _target_rotation, 1.0 - exp(-animation_speed * delta))

func interact(_actor: Node) -> bool:
    is_open = not is_open
    _target_rotation = _closed_rotation + deg_to_rad(open_angle_degrees) * (1.0 if is_open else 0.0)
    return true

func get_interaction_prompt() -> String:
    return "Tür schließen" if is_open else interaction_label
