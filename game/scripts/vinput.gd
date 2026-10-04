extends Node

## Virtual / on-screen control state. Keyboard still works independently in player.

var move_x := 0.0
var move_y := 0.0
var attack_held := false
var jump_held := false

var _attack_was := false
var _jump_was := false
var attack_just := false
var jump_just := false


func _process(_delta: float) -> void:
	attack_just = attack_held and not _attack_was
	jump_just = jump_held and not _jump_was
	_attack_was = attack_held
	_jump_was = jump_held


func set_move_x(v: float) -> void:
	move_x = clampf(v, -1.0, 1.0)


func set_move_y(v: float) -> void:
	move_y = clampf(v, -1.0, 1.0)


func clear_move() -> void:
	move_x = 0.0
	move_y = 0.0


func reset() -> void:
	clear_move()
	attack_held = false
	jump_held = false
	_attack_was = false
	_jump_was = false
	attack_just = false
	jump_just = false
