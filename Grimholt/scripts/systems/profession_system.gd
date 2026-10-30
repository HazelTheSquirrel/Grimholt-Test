extends RefCounted
class_name GrimholtProfessionSystem

var experience: Dictionary = {}

func add_experience(profession_id: String, amount: int) -> void:
    if profession_id.is_empty() or amount <= 0:
        return
    experience[profession_id] = int(experience.get(profession_id, 0)) + amount

func get_experience(profession_id: String) -> int:
    return int(experience.get(profession_id, 0))

func get_level(profession_id: String) -> int:
    return 1 + floori(sqrt(float(get_experience(profession_id)) / 100.0))
