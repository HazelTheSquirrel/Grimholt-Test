extends CanvasLayer
var player: Node
var game_manager: Node
var vitals_label: Label
var ammo_label: Label
var score_label: Label
var wave_label: Label
func setup(p_player: Node, p_manager: Node) -> void:
	player = p_player
	game_manager = p_manager
	_build_ui()
	player.connect("vitals_changed", Callable(self, "_on_vitals_changed"))
	game_manager.connect("score_changed", Callable(self, "_on_score_changed"))
	player.get_node("Head/Camera3D/WeaponController").connect("weapon_state_changed", Callable(self, "_on_weapon_changed"))
func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	vitals_label = _label(root, Vector2(28,-88), Vector2(360,54), 22, Color(0.4,0.85,1))
	vitals_label.text = "SHIELDS 100  |  HEALTH 100"
	ammo_label = _label(root, Vector2(-290,-88), Vector2(260,54), 22, Color(1,0.82,0.38))
	ammo_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.text = "MA5K  36 / 180"
	score_label = _label(root, Vector2(28,24), Vector2(260,38), 20, Color.WHITE)
	score_label.text = "SCORE  000000"
	wave_label = _label(root, Vector2(-260,24), Vector2(240,38), 20, Color(0.55,0.9,1))
	wave_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wave_label.text = "WAVE  1"
	var crosshair := _label(root, Vector2.ZERO, Vector2(40,40), 30, Color(0.8,0.95,1))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var controls := _label(root, Vector2.ZERO, Vector2(900,28), 14, Color(0.75,0.85,0.95))
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.position.y = -36
	controls.text = "WASD MOVE  •  SHIFT SPRINT  •  SPACE JUMP  •  LMB FIRE  •  R RELOAD  •  Q SWAP"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := _label(root, Vector2(28,64), Vector2(280,26), 14, Color(0.55,0.68,0.78))
	title.text = "FRONTLINE // RIFT ARENA"
func _label(parent: Control, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label
func _on_vitals_changed(health: float, shields: float) -> void:
	vitals_label.text = "SHIELDS %03d  |  HEALTH %03d" % [roundi(shields),roundi(health)]
func _on_weapon_changed(name: String, ammo: int, reserve: int) -> void:
	ammo_label.text = "%s  %02d / %03d" % [name,ammo,reserve]
func _on_score_changed(score: int, wave: int, remaining: int) -> void:
	score_label.text = "SCORE  %06d" % score
	wave_label.text = "WAVE %02d  //  HOSTILES %02d" % [wave,remaining]
