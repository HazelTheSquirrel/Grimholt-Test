extends CanvasLayer
class_name PauseMenuController

signal resume_requested
signal restart_requested
signal quit_requested

@onready var overlay: Control = $Overlay
@onready var heading: Label = $Overlay/Center/Panel/Content/Heading
@onready var resume_button: Button = $Overlay/Center/Panel/Content/Resume
@onready var restart_button: Button = $Overlay/Center/Panel/Content/Restart
@onready var quit_button: Button = $Overlay/Center/Panel/Content/Quit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	resume_button.pressed.connect(func(): resume_requested.emit())
	restart_button.pressed.connect(func(): restart_requested.emit())
	quit_button.pressed.connect(func(): quit_requested.emit())

func set_menu_visible(value: bool) -> void:
	overlay.visible = value

func is_menu_visible() -> bool:
	return overlay.visible

func show_match_result(final_score: int) -> void:
	heading.text = "RUNDE BEENDET  |  SCORE %d" % final_score
	resume_button.visible = false
	overlay.visible = true
