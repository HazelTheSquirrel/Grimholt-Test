extends Node
class_name GrimholtInteractionComponent

signal focus_changed(target: Node3D)

@export var max_distance: float = 5.0
@export_flags_3d_physics var collision_mask: int = 1

var _camera: Camera3D
var _actor: CharacterBody3D
var _focused_target: Node3D

func setup(actor: CharacterBody3D, camera: Camera3D) -> void:
    _actor = actor
    _camera = camera

func get_focused_target() -> Node3D:
    if not is_instance_valid(_actor) or not is_instance_valid(_camera):
        return null
    var origin := _camera.global_position
    var endpoint := origin - _camera.global_transform.basis.z * max_distance
    var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
    query.exclude = [_actor.get_rid()]
    query.collision_mask = collision_mask
    var hit := _actor.get_world_3d().direct_space_state.intersect_ray(query)
    var target := hit.get("collider") as Node3D if not hit.is_empty() else null
    if is_instance_valid(target) and not target.has_method("interact"):
        target = null
    if target != _focused_target:
        _focused_target = target
        focus_changed.emit(_focused_target)
    return _focused_target

func interact() -> bool:
    var target := get_focused_target()
    if not is_instance_valid(target) or not target.has_method("interact"):
        return false
    return bool(target.call("interact", _actor))
