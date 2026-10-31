extends CanvasLayer
var player: Node
var game_manager: Node
var weapon_controller: Node
var health_bar: ProgressBar
var shield_bar: ProgressBar
var health_value: Label
var shield_value: Label
var ammo_label: Label
var score_label: Label
var wave_label: Label
var pause_panel: PanelContainer
var death_overlay: ColorRect
var damage_flash: ColorRect
var hit_marker: Label
var hit_marker_time: float = 0.0
var damage_tween: Tween
const PANEL_COLOR: Color = Color(0.025, 0.055, 0.085, 0.88)
const ACCENT: Color = Color(0.15, 0.78, 1.0)
const MUTED: Color = Color(0.55, 0.72, 0.82)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func setup(p_player: Node, p_manager: Node) -> void:
	player = p_player
	game_manager = p_manager
	weapon_controller = player.get_node("Head/Camera3D/WeaponController")
	_build_ui()
	player.vitals_changed.connect(_on_vitals_changed)
	player.player_damaged.connect(_on_player_damaged)
	player.player_died.connect(_on_player_died)
	player.player_respawned.connect(_on_player_respawned)
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.wave_started.connect(_on_wave_started)
	weapon_controller.weapon_state_changed.connect(_on_weapon_changed)
	weapon_controller.hit_confirmed.connect(_on_hit_confirmed)
	_on_vitals_changed(player.health, player.shields)
	_on_weapon_changed(weapon_controller.current_weapon_name(), weapon_controller.ammo_in_mag[0], weapon_controller.reserve_by_weapon[0])
func _process(delta: float) -> void:
	hit_marker_time = maxf(0.0, hit_marker_time - delta)
	if hit_marker != null:
		hit_marker.modulate.a = clampf(hit_marker_time / 0.12, 0.0, 1.0)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if get_tree().paused:
			_resume_game()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_pause_game()
		get_viewport().set_input_as_handled()
func _build_ui() -> void:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var title_panel: PanelContainer = _panel(root, Vector2(24, 20), Vector2(310, 54), Control.PRESET_TOP_LEFT)
	var title: Label = _label(title_panel, "FRONTLINE  /  RIFT ARENA", 15, ACCENT)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var status_panel: PanelContainer = _panel(root, Vector2(-300, 20), Vector2(276, 54), Control.PRESET_TOP_RIGHT)
	wave_label = _label(status_panel, "WAVE 01  //  HOSTILES 00", 16, Color.WHITE)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var vitals_panel: PanelContainer = _panel(root, Vector2(24, -118), Vector2(340, 94), Control.PRESET_BOTTOM_LEFT)
	var vitals_column: VBoxContainer = VBoxContainer.new()
	vitals_column.add_theme_constant_override("separation", 5)
	vitals_panel.add_child(vitals_column)
	shield_value = _label(vitals_column, "SHIELDS 100", 12, ACCENT)
	shield_bar = _bar(vitals_column, Color(0.12, 0.72, 1.0))
	health_value = _label(vitals_column, "HEALTH 100", 12, Color(0.35, 0.95, 0.58))
	health_bar = _bar(vitals_column, Color(0.22, 0.88, 0.48))
	var ammo_panel: PanelContainer = _panel(root, Vector2(-310, -94), Vector2(286, 70), Control.PRESET_BOTTOM_RIGHT)
	ammo_label = _label(ammo_panel, "MA5K RIFLE   36 / 180", 18, Color(1.0, 0.82, 0.4))
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var score_panel: PanelContainer = _panel(root, Vector2(-180, 88), Vector2(156, 42), Control.PRESET_TOP_RIGHT)
	score_label = _label(score_panel, "SCORE 000000", 14, Color.WHITE)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var crosshair: Label = _label(root, "+", 28, Color(0.78, 0.95, 1.0))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-12, -18)
	crosshair.size = Vector2(24, 36)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hit_marker = _label(root, "×", 34, Color(1.0, 0.88, 0.42))
	hit_marker.set_anchors_preset(Control.PRESET_CENTER)
	hit_marker.position = Vector2(-16, -22)
	hit_marker.size = Vector2(32, 44)
	hit_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hit_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hit_marker.modulate.a = 0.0
	var controls: Label = _label(root, "WASD MOVE   •   SHIFT SPRINT   •   SPACE JUMP   •   LMB FIRE   •   R RELOAD   •   Q SWAP   •   ESC PAUSE", 12, MUTED)
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.position = Vector2(-470, -30)
	controls.size = Vector2(940, 22)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_flash = ColorRect.new()
	damage_flash.color = Color(0.9, 0.025, 0.035, 0.0)
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage_flash)
	death_overlay = ColorRect.new()
	death_overlay.color = Color(0.28, 0.015, 0.025, 0.55)
	death_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_overlay.visible = false
	death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(death_overlay)
	var death_text: Label = _label(death_overlay, "SIGNAL LOST\nREDEPLOYING...", 28, Color(1.0, 0.72, 0.68))
	death_text.set_anchors_preset(Control.PRESET_CENTER)
	death_text.position = Vector2(-190, -55)
	death_text.size = Vector2(380, 110)
	death_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_build_pause_panel(root)
func _panel(parent: Control, pos: Vector2, dimensions: Vector2, preset: Control.LayoutPreset) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(preset)
	panel.position = pos
	panel.size = dimensions
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = Color(0.12, 0.42, 0.58, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel
func _label(parent: Control, value: String, font_size: int, tint: Color) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label
func _bar(parent: Control, tint: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.max_value = 100.0
	bar.show_percentage = false
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.04, 0.09, 0.13)
	background.set_corner_radius_all(3)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = tint
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar
func _build_pause_panel(root: Control) -> void:
	pause_panel = _panel(root, Vector2(-205, -180), Vector2(410, 360), Control.PRESET_CENTER)
	pause_panel.visible = false
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	pause_panel.add_child(column)
	var heading: Label = _label(column, "MISSION PAUSED", 28, ACCENT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint: Label = _label(column, "RIFT ARENA  //  TRAINING SIMULATION", 12, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_menu_button(column, "RESUME", _resume_game)
	_add_menu_button(column, "RESTART SIMULATION", _restart_game)
	_add_menu_button(column, "QUIT TO DESKTOP", func() -> void: get_tree().quit())
func _add_menu_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = caption
	button.custom_minimum_size.y = 46
	button.pressed.connect(action)
	parent.add_child(button)
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
func _on_vitals_changed(health: float, shields: float) -> void:
	health_bar.value = health
	shield_bar.value = shields
	health_value.text = "HEALTH  %03d" % roundi(health)
	shield_value.text = "SHIELDS  %03d" % roundi(shields)
func _on_player_damaged(_amount: float, _health: float, _shields: float) -> void:
	if damage_tween != null and damage_tween.is_running():
		damage_tween.kill()
	damage_flash.color.a = 0.32
	damage_tween = create_tween()
	damage_tween.tween_property(damage_flash, "color:a", 0.0, 0.28)
	if player.dead:
		death_overlay.visible = true
func _on_player_died() -> void:
	death_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func _on_player_respawned() -> void:
	death_overlay.visible = false
func _on_weapon_changed(name: String, ammo: int, reserve: int) -> void:
	ammo_label.text = "%s   %02d / %03d" % [name, ammo, reserve]
func _on_score_changed(score: int, wave: int, remaining: int) -> void:
	score_label.text = "SCORE %06d" % score
	wave_label.text = "WAVE %02d  //  HOSTILES %02d" % [wave, remaining]
func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	wave_label.text = "WAVE %02d  //  HOSTILES %02d" % [wave_number, enemy_count]
func _on_hit_confirmed() -> void:
	hit_marker_time = 0.18
	hit_marker.modulate.a = 1.0
