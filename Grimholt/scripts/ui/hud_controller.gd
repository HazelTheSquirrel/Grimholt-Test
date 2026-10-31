extends CanvasLayer
class_name HUDController

@onready var score_label: Label = $Margin/Layout/TopRow/Score
@onready var timer_label: Label = $Margin/Layout/TopRow/Timer
@onready var health_label: Label = $Margin/Layout/BottomRow/Health
@onready var ammo_label: Label = $Margin/Layout/BottomRow/Ammo

func set_score(value: int) -> void:
    score_label.text = "SCORE  %d" % value

func set_health(value: int) -> void:
    health_label.text = "HEALTH  %d" % value

func set_ammo(current: int, reserve: int) -> void:
    ammo_label.text = "%02d / %03d" % [current, reserve]

func set_time(seconds: int) -> void:
    timer_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
