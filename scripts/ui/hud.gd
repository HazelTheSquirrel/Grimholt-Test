extends CanvasLayer

var player: Node
var game_manager: Node
var vitals_label: Label
var ammo_label: Label
var score_label: Label
var wave_label: Label
var pause_panel: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(p_player: Node, p_manager: Node) -> void:
	player = p_player
	game_manager = p_manager
	_build_ui()
	player.connect("vitals_changed", Callable(self, "_on_vitals_changed"))
	game_manager.connect("score_changed", Callable(self, "_on_score_changed"))
	player.get_node("Head/Camera3D/WeaponController").connect("weapon_state_changed", Callable(self, "_on_weapon_changed"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if get_tree().paused:
			_resume_game()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_pause_game()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	vitals_label = _label(root, Vector2(28, -88), Vector2(360, 54), 22, Color(0.4, 0.85, 1))
	vitals_label.text = "SHIELDS 100  |  HEALTH 100"
	ammo_label = _label(root, Vector2(-290, -88), Vector2(260, 54), 22, Color(1, 0.82, 0.38))
	ammo_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.text = "MA5K  36 / 180"
	score_label = _label(root, Vector2(28, 24), Vector2(260, 38), 20, Color.WHITE)
	score_label.text = "SCORE  000000"
	wave_label = _label(root, Vector2(-260, 24), Vector2(240, 38), 20, Color(0.55, 0.9, 1))
	wave_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wave_label.text = "WAVE  1"

	var crosshair := _label(root, Vector2.ZERO, Vector2(40, 40), 30, Color(0.8, 0.95, 1))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var controls := _label(root, Vector2.ZERO, Vector2(1000, 28), 14, Color(0.75, 0.85, 0.95))
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.position.y = -36
	controls.text = "CLICK TO AIM  •  WASD MOVE  •  SHIFT SPRINT  •  SPACE JUMP  •  LMB FIRE  •  R RELOAD  •  Q SWAP  •  ESC PAUSE"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var title := _label(root, Vector2(28, 64), Vector2(280, 26), 14, Color(0.55, 0.68, 0.78))
	title.text = "FRONTLINE // RIFT ARENA"
	_build_pause_panel(root)

func _build_pause_panel(root: Control) -> void:
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-190, -145)
	pause_panel.size = Vector2(380, 290)
	pause_panel.visible = false
	root.add_child(pause_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pause_panel.add_child(column)

	var heading := Label.new()
	heading.text = "MISSION PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	column.add_child(heading)

	var hint := Label.new()
	hint.text = "Rift Arena // Training Simulation"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

	var resume := Button.new()
	resume.text = "RESUME"
	resume.custom_minimum_size.y = 44
	resume.pressed.connect(_resume_game)
	column.add_child(resume)

	var restart := Button.new()
	restart.text = "RESTART SIMULATION"
	restart.custom_minimum_size.y = 44
	restart.pressed.connect(_restart_game)
	column.add_child(restart)

	var quit := Button.new()
	quit.text = "QUIT TO DESKTOP"
	quit.custom_minimum_size.y = 44
	quit.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(quit)

func _pause_game() -> void:
	get_tree().paused = true
	pause_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _resume_game() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _restart_game() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func _label(parent: Control, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func _on_vitals_changed(health: float, shields: float) -> void:
	vitals_label.text = "SHIELDS %03d  |  HEALTH %03d" % [roundi(shields), roundi(health)]

func _on_weapon_changed(name: String, ammo: int, reserve: int) -> void:
	ammo_label.text = "%s  %02d / %03d" % [name, ammo, reserve]

func _on_score_changed(score: int, wave: int, remaining: int) -> void:
	score_label.text = "SCORE  %06d" % score
	wave_label.text = "WAVE %02d  //  HOSTILES %02d" % [wave, remaining]
