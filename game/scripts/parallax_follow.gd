extends Node

## Runs after Camera2D so far/mid use this frame's scroll, not last frame's.

func _ready() -> void:
	process_priority = -20


func _process(_delta: float) -> void:
	var level := get_parent()
	if level != null and level.has_method("sync_parallax"):
		level.sync_parallax()
