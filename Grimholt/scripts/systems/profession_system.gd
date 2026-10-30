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

func set_experience_from_save(saved_experience: Variant) -> bool:
    if not saved_experience is Dictionary:
        return false
    var validated: Dictionary = {}
    for profession_id in saved_experience:
        var amount_variant: Variant = saved_experience[profession_id]
        if String(profession_id).is_empty() or not amount_variant is int or int(amount_variant) < 0:
            return false
        validated[String(profession_id)] = int(amount_variant)
    experience = validated
    return true
