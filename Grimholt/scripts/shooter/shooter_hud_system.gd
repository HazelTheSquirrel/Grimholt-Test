extends "res://scripts/shooter/shooter_match_system.gd"

func _update_scoreboard() -> void:
	if scoreboard_label == null:
		return
	var ranking: Array = []
	for id in scores:
		ranking.append([int(id), int(scores[id]), int(deaths.get(id, 0))])
	ranking.sort_custom(func(a, b):
		if a[1] == b[1]:
			return a[2] < b[2]
		return a[1] > b[1]
	)
	var output := "[center][b]GRIMHOLT // SCOREBOARD[/b]\n[b]PLAYER                         K       D[/b]\n"
	for row in ranking:
		output += "%s    %02d    %02d\n" % [_actor_name(row[0]), row[1], row[2]]
	output += "[/center]"
	scoreboard_label.text = output

@rpc("authority", "call_local", "reliable")
func _update_hud() -> void:
	if hud_layer == null:
		return
	timer_label.text = "DEATHMATCH     " + _format_round_time(maxi(0, round_end_time_msec - Time.get_ticks_msec()))
	var ranking: Array = []
	for id in scores:
		ranking.append([int(id), int(scores[id])])
	ranking.sort_custom(func(a, b): return a[1] > b[1])
	var rows: Array[String] = []
	for row in ranking.slice(0, 5):
		rows.append("%s  %02d" % [_actor_name(row[0]), row[1]])
	score_label.text = "TOP FRAGGERS\n" + "\n".join(rows)
	if scoreboard_panel != null and scoreboard_panel.visible:
		_update_scoreboard()
	var local_player: Node3D = players.get(multiplayer.get_unique_id()) as Node3D
	if local_player:
		health_label.text = "VITALS   %03d / 100" % int(local_player.get("health"))
		ammo_label.text = "RIFLE  |  %02d / %03d\n[ R ] RELOAD" % [int(local_player.get("ammo")), int(local_player.get("reserve_ammo"))]
	else:
		health_label.text = "VITALS   --"
		ammo_label.text = "RIFLE  |  -- / --"

func _draw_minimap() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(160, 160))
	minimap.draw_rect(rect, Color(0.025, 0.055, 0.075, 0.78), true)
	minimap.draw_rect(rect, Color(0.45, 0.65, 0.72, 0.9), false, 2.0)
	for x in [24.0, 80.0, 136.0]:
		minimap.draw_line(Vector2(x, 8), Vector2(x, 152), Color(0.28, 0.39, 0.44, 0.5), 1.0)
	for z in [24.0, 80.0, 136.0]:
		minimap.draw_line(Vector2(8, z), Vector2(152, z), Color(0.28, 0.39, 0.44, 0.5), 1.0)
	var local: Node3D = players.get(multiplayer.get_unique_id()) as Node3D
	if local:
		var p := Vector2(80 + local.global_position.x * 2.7, 80 + local.global_position.z * 2.7)
		minimap.draw_circle(p, 5.0, Color(0.35, 0.95, 0.8))
	for id in players:
		if int(id) == multiplayer.get_unique_id():
			continue
		var p: Vector3 = players[id].global_position
		minimap.draw_circle(Vector2(80 + p.x * 2.7, 80 + p.z * 2.7), 3.5, Color(0.9, 0.35, 0.25))
	for id in bots:
		var p: Vector3 = bots[id].global_position
		minimap.draw_circle(Vector2(80 + p.x * 2.7, 80 + p.z * 2.7), 3.0, Color(0.95, 0.72, 0.28))
