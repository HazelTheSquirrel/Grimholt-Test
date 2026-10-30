extends "res://scripts/shooter/shooter_combat_system.gd"

func _finish_round(reason: String = "time") -> void:
	if not multiplayer.is_server() or not round_active:
		return
	round_active = false
	var winner := -1
	var best := -1
	var tied := false
	for id in scores:
		var points := int(scores[id])
		if points > best:
			best = points
			winner = int(id)
			tied = false
		elif points == best:
			tied = true
	if tied:
		winner = -1
	_round_finished.rpc(winner, maxi(0, best), reason)

@rpc("authority", "call_local", "reliable")
func _round_finished(winner: int, points: int, reason: String) -> void:
	if winner < 0:
		status_label.text = "RUNDE BEENDET // UNENTSCHIEDEN (%d PUNKTE)" % points
	else:
		status_label.text = "RUNDE BEENDET // %s GEWINNT (%d)" % [_actor_name(winner), points]
	timer_label.text = "DEATHMATCH     SCORE LIMIT" if reason == "score" else "DEATHMATCH     00:00"
	menu_layer.visible = true

func _format_round_time(remaining_msec: int) -> String:
	# Round up partial seconds so 00:00 is shown only once the clock truly expires.
	var total_seconds := ceili(float(maxi(0, remaining_msec)) / 1000.0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
