extends SceneTree

var checked_files := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_scan_directory("res://")
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("SCRIPT_VALIDATION_OK: %d GDScript files parsed." % checked_files)
	quit(0)

func _scan_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		failures.append("Could not open directory: " + path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var child_path := path.path_join(entry)
		if directory.current_is_dir():
			if entry != ".godot":
				_scan_directory(child_path)
		elif entry.get_extension().to_lower() == "gd":
			checked_files += 1
			var script := load(child_path)
			if script == null:
				failures.append("Failed to load GDScript: " + child_path)
			elif script is GDScript:
				var reload_error: Error = (script as GDScript).reload()
				if reload_error != OK:
					failures.append("GDScript parser rejected: " + child_path)
		entry = directory.get_next()
	directory.list_dir_end()
