extends CanvasLayer
class_name HUDController

@onready var score_label: Label = $Margin/Layout/TopRow/Score
@onready var timer_label: Label = $Margin/Layout/TopRow/Timer
@onready var health_label: Label = $Margin/Layout/BottomRow/Health
@onready var ammo_label: Label = $Margin/Layout/BottomRow/Ammo
@onready var hit_label: Label = $HitFeedback
@onready var weapon_label: Label = $Margin/Layout/TopRow/Weapon

var _feedback_time: float = 0.0

func _ready() -> void:
	hit_label.visible = false

func _process(delta: float) -> void:
	if _feedback_time > 0.0:
		_feedback_time = maxf(0.0, _feedback_time - delta)
		if _feedback_time == 0.0:
			hit_label.visible = false

func set_score(value: int) -> void:
	score_label.text = "SCORE  %d" % value

func set_health(value: int) -> void:
	health_label.text = "HEALTH  %d" % value

func set_ammo(current: int, reserve: int) -> void:
	ammo_label.text = "%02d / %03d" % [current, reserve]

func set_time(seconds: int) -> void:
	timer_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]

func set_weapon(display_name: String) -> void:
	weapon_label.text = display_name

func show_hit_marker() -> void:
	hit_label.text = "×"
	hit_label.visible = true
	_feedback_time = 0.16

func show_kill_marker() -> void:
	hit_label.text = "ELIMINATION"
	hit_label.visible = true
	_feedback_time = 0.75
