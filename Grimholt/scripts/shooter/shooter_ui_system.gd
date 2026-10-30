extends "res://scripts/shooter/shooter_core.gd"

const GRIMHOLT_CREST := preload("res://assets/branding/grimholt_crest.svg")

func _build_arena() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.34, 0.39, 0.48)
	env.ambient_light_energy = 0.7
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	_add_box("ArenaFloor", Vector3(0, -0.5, 0), Vector3(48, 1, 48), Color(0.13, 0.17, 0.21))
	_add_box("NorthWall", Vector3(0, 3, -24), Vector3(48, 6, 1), Color(0.20, 0.25, 0.31))
	_add_box("SouthWall", Vector3(0, 3, 24), Vector3(48, 6, 1), Color(0.20, 0.25, 0.31))
	_add_box("EastWall", Vector3(24, 3, 0), Vector3(1, 6, 48), Color(0.20, 0.25, 0.31))
	_add_box("WestWall", Vector3(-24, 3, 0), Vector3(1, 6, 48), Color(0.20, 0.25, 0.31))
	var cover := [[Vector3(-10, 1, -8), Vector3(6, 2, 2)], [Vector3(10, 1, 8), Vector3(6, 2, 2)], [Vector3(0, 1.5, 0), Vector3(3, 3, 3)], [Vector3(-15, 1, 8), Vector3(2, 2, 7)], [Vector3(15, 1, -8), Vector3(2, 2, 7)], [Vector3(0, 0.75, -14), Vector3(9, 1.5, 2)], [Vector3(0, 0.75, 14), Vector3(9, 1.5, 2)]]
	for item in cover:
		_add_box("Cover", item[0], item[1], Color(0.27, 0.33, 0.39))

func _add_box(node_name: String, pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -230
	panel.offset_top = -260
	panel.offset_right = 230
	panel.offset_bottom = 260
	menu_layer.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := Label.new()
	title.text = "GRIMHOLT // ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	var crest := TextureRect.new()
	crest.texture = GRIMHOLT_CREST
	crest.custom_minimum_size = Vector2(104, 104)
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(crest)

	var intro := Label.new()
	intro.text = "FREE-FOR-ALL  |  50 KILLS  |  15 MIN"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(intro)

	main_menu_container = VBoxContainer.new()
	main_menu_container.add_theme_constant_override("separation", 8)
	column.add_child(main_menu_container)
	_add_menu_button(main_menu_container, "START SOLO GAME", _on_training_pressed)
	_add_menu_button(main_menu_container, "MATCHMAKING", func(): _show_menu_section("matchmaking"))
	_add_menu_button(main_menu_container, "CUSTOM GAMES", func(): _show_menu_section("custom"))
	_add_menu_button(main_menu_container, "OPTIONS", func(): _show_menu_section("options"))

	matchmaking_container = VBoxContainer.new()
	matchmaking_container.add_theme_constant_override("separation", 8)
	matchmaking_container.visible = false
	column.add_child(matchmaking_container)
	var matchmaking_title := Label.new()
	matchmaking_title.text = "MATCHMAKING"
	matchmaking_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	matchmaking_container.add_child(matchmaking_title)
	var matchmaking_info := Label.new()
	matchmaking_info.text = "Die automatische Spielersuche ist noch nicht verfügbar."
	matchmaking_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	matchmaking_container.add_child(matchmaking_info)
	_add_menu_button(matchmaking_container, "ZURÜCK", func(): _show_menu_section("main"))

	custom_games_container = VBoxContainer.new()
	custom_games_container.add_theme_constant_override("separation", 8)
	custom_games_container.visible = false
	column.add_child(custom_games_container)
	var custom_title := Label.new()
	custom_title.text = "CUSTOM GAMES"
	custom_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	custom_games_container.add_child(custom_title)
	address_input = LineEdit.new()
	address_input.placeholder_text = "Server-IP oder Hostname"
	address_input.text = "127.0.0.1"
	custom_games_container.add_child(address_input)
	_add_menu_button(custom_games_container, "SPIEL HOSTEN", _on_host_pressed)
	_add_menu_button(custom_games_container, "SPIEL BEITRETEN", _on_join_pressed)
	_add_menu_button(custom_games_container, "ZURÜCK", func(): _show_menu_section("main"))

	options_container = VBoxContainer.new()
	options_container.add_theme_constant_override("separation", 8)
	options_container.visible = false
	column.add_child(options_container)
	var options_title := Label.new()
	options_title.text = "OPTIONS"
	options_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_container.add_child(options_title)

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.text = "Vollbild"
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	options_container.add_child(fullscreen_toggle)

	var volume_label := Label.new()
	volume_label.text = "Master-Lautstärke"
	options_container.add_child(volume_label)
	var volume_slider := HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	volume_slider.value_changed.connect(_on_master_volume_changed)
	options_container.add_child(volume_slider)
	_add_menu_button(options_container, "ZURÜCK", func(): _show_menu_section("main"))

	status_label = Label.new()
	status_label.text = "WASD bewegen  |  Maus zielen  |  Linksklick feuern"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status_label)

func _add_menu_button(parent: VBoxContainer, button_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(callback)
	parent.add_child(button)

func _show_menu_section(section: String) -> void:
	main_menu_container.visible = section == "main"
	matchmaking_container.visible = section == "matchmaking"
	custom_games_container.visible = section == "custom"
	options_container.visible = section == "options"

func _on_fullscreen_toggled(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _on_master_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value)

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_top = 18
	top.offset_right = -24
	top.custom_minimum_size.y = 42
	hud_layer.add_child(top)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 22)
	top.add_child(timer_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 22)
	top.add_child(score_label)
	var crosshair := Label.new()
	crosshair.text = "＋"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.add_theme_font_size_override("font_size", 28)
	hud_layer.add_child(crosshair)
	health_label = Label.new()
	health_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	health_label.offset_left = 26
	health_label.offset_bottom = -24
	health_label.offset_top = -70
	health_label.add_theme_font_size_override("font_size", 22)
	hud_layer.add_child(health_label)
	ammo_label = Label.new()
	ammo_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.offset_right = -28
	ammo_label.offset_bottom = -24
	ammo_label.offset_top = -82
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(ammo_label)
	feed_label = Label.new()
	feed_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	feed_label.offset_right = -26
	feed_label.offset_top = 74
	feed_label.offset_left = -330
	feed_label.add_theme_font_size_override("font_size", 16)
	feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_layer.add_child(feed_label)
	minimap = Control.new()
	minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	minimap.position = Vector2(24, -210)
	minimap.custom_minimum_size = Vector2(160, 160)
	minimap.draw.connect(_draw_minimap)
	hud_layer.add_child(minimap)

	hitmarker_label = Label.new()
	hitmarker_label.text = "✕"
	hitmarker_label.visible = false
	hitmarker_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hitmarker_label.add_theme_font_size_override("font_size", 34)
	hitmarker_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	hud_layer.add_child(hitmarker_label)

	scoreboard_panel = PanelContainer.new()
	scoreboard_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	scoreboard_panel.offset_left = -310
	scoreboard_panel.offset_top = -250
	scoreboard_panel.offset_right = 310
	scoreboard_panel.offset_bottom = 250
	scoreboard_panel.visible = false
	hud_layer.add_child(scoreboard_panel)
	scoreboard_label = RichTextLabel.new()
	scoreboard_label.bbcode_enabled = true
	scoreboard_label.fit_content = true
	scoreboard_label.scroll_active = false
	scoreboard_panel.add_child(scoreboard_label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_TAB:
		if event.pressed and not event.echo and scoreboard_panel != null:
			scoreboard_panel.visible = true
			_update_scoreboard()
		elif not event.pressed and scoreboard_panel != null:
			scoreboard_panel.visible = false
